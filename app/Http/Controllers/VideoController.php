<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use App\Models\Video;
use App\Models\VideoComment;
use App\Models\VideoLike;
use App\Models\VideoView;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class VideoController extends Controller
{
    /**
     * Upload et créer une nouvelle vidéo
     */
    public function upload(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'video' => 'required|file|mimes:mp4,mov,avi,wmv,flv,webm|max:512000',
            'thumbnail' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:10240',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'is_public' => 'boolean',
            'allow_comments' => 'boolean',
            'allow_downloads' => 'boolean',
            'shop_id' => 'nullable|exists:shops,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            DB::beginTransaction();

            $user = auth()->user();

            // Upload de la vidéo (sans compression)
            $videoFile = $request->file('video');
            $videoPath = $videoFile->store('videos', 'public');

            // Upload de la miniature si présente
            $thumbnailPath = null;
            if ($request->hasFile('thumbnail')) {
                $thumbnailFile = $request->file('thumbnail');
                $thumbnailPath = $thumbnailFile->store('video-thumbnails', 'public');
            }

            // Obtenir les métadonnées basiques sans ffmpeg
            $fileSize = $videoFile->getSize() / (1024 * 1024); // en MB

            // Stocker les chemins relatifs
            $videoRelativePath = str_replace('public/', '', $videoPath);
            $thumbnailRelativePath = $thumbnailPath ? str_replace('public/', '', $thumbnailPath) : null;

            $video = Video::create([
                'title' => $request->title,
                'description' => $request->description,
                'video_path' => $videoRelativePath,
                'thumbnail_path' => $thumbnailRelativePath,
                'processed_path' => null, // Plus de compression
                'duration_seconds' => 0, // Sans ffmpeg, on ne peut pas obtenir la durée
                'resolution' => null,
                'file_size_mb' => round($fileSize, 2),
                'format' => 'mp4',
                'is_public' => $request->is_public ?? true,
                'allow_comments' => $request->allow_comments ?? true,
                'allow_downloads' => $request->allow_downloads ?? false,
                'status' => 'ready',
                'user_id' => $user->id,
                'shop_id' => $request->shop_id,
                'metadata' => json_encode(['file_size_mb' => $fileSize]),
                'published_at' => $request->is_public ? now() : null,
                'views_count' => 0,
                'likes_count' => 0,
                'comments_count' => 0,
            ]);

            DB::commit();

            $videoData = $video->toArray();
            $videoData['video_url'] = $video->video_url;
            $videoData['thumbnail_url'] = $video->thumbnail_url;

            return response()->json([
                'message' => 'Vidéo uploadée avec succès',
                'video' => $videoData
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Erreur upload vidéo: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de l\'upload de la vidéo'], 500);
        }
    }


    /**
     * Lister les vidéos (publiques)
     */
    public function index(Request $request): JsonResponse
    {
        $query = Video::with(['user', 'shop'])
            ->where('status', 'ready')
            ->where('is_public', true)
            ->where('published_at', '<=', now());

        if ($request->has('shop_id')) {
            $query->where('shop_id', $request->shop_id);
        }

        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('limit')) {
            $videos = $query->orderBy('published_at', 'desc')->limit($request->limit)->get();
        } else {
            $videos = $query->orderBy('published_at', 'desc')->paginate(20);
        }

        $videosArray = $videos instanceof \Illuminate\Pagination\LengthAwarePaginator
            ? $videos->through(function ($video) {
                $video->append(['video_url', 'thumbnail_url']);
                return $video;
            })
            : $videos->map(function ($video) {
                $video->append(['video_url', 'thumbnail_url']);
                return $video;
            });

        return response()->json(['videos' => $videosArray]);
    }

    /**
     * Mes vidéos (authentifié)
     */
    public function myVideos(Request $request): JsonResponse
    {
        $userId = auth()->id();

        // Log pour débogage
        Log::info('Fetching my videos', ['user_id' => $userId]);

        $videos = Video::where('user_id', $userId)
            ->with('shop')
            ->orderBy('created_at', 'desc')
            ->get();

        $videos->each(function ($video) {
            $video->append(['video_url', 'thumbnail_url']);
        });

        // Log pour débogage
        Log::info('My videos fetched', ['count' => $videos->count()]);

        return response()->json(['videos' => $videos]);
    }
    /**
     * Détails d'une vidéo (publique)
     */
    public function show($id): JsonResponse
    {
        $video = Video::with(['user', 'shop'])
            ->where('status', 'ready')
            ->where('is_public', true)
            ->findOrFail($id);

        $video->append(['video_url', 'thumbnail_url']);

        return response()->json(['video' => $video]);
    }

    /**
     * Vidéos tendances (publiques)
     */
    public function trending(Request $request): JsonResponse
    {
        $days = $request->get('days', 7);
        $limit = $request->get('limit', 20);

        $videos = Video::with(['user', 'shop'])
            ->where('status', 'ready')
            ->where('is_public', true)
            ->where('published_at', '<=', now())
            ->where('created_at', '>=', now()->subDays($days))
            ->orderBy('views_count', 'desc')
            ->orderBy('likes_count', 'desc')
            ->limit($limit)
            ->get();

        $videos->each(function ($video) {
            $video->append(['video_url', 'thumbnail_url']);
        });

        return response()->json(['videos' => $videos]);
    }

    /**
     * Liker/Unliker (authentifié)
     */
    public function toggleLike($id): JsonResponse
    {
        $video = Video::findOrFail($id);
        $userId = auth()->id();

        $existingLike = VideoLike::where('video_id', $id)->where('user_id', $userId)->first();

        if ($existingLike) {
            $existingLike->delete();
            $video->decrement('likes_count');
            return response()->json(['liked' => false, 'likes_count' => $video->likes_count]);
        } else {
            VideoLike::create(['video_id' => $id, 'user_id' => $userId]);
            $video->increment('likes_count');
            return response()->json(['liked' => true, 'likes_count' => $video->likes_count]);
        }
    }

    /**
     * Partager une vidéo (générer un lien partageable)
     */
    public function share($id): JsonResponse
    {
        $video = Video::where('status', 'ready')
            ->where('is_public', true)
            ->findOrFail($id);

        // Assuming front‑end Reel Feed page is at /reel/{id}
        $shareUrl = url('/reel/' . $video->id);

        return response()->json([
            'share_url' => $shareUrl,
        ]);
    }

    /**
     * Enregistrer une vue (publique)
     */
    public function recordView(Request $request, $id): JsonResponse
    {
        $video = Video::findOrFail($id);
        $userId = auth()->id();
        $watchDuration = $request->get('watch_duration', 0);

        $existingView = VideoView::where('video_id', $id)
            ->where(function($q) use ($userId, $request) {
                if ($userId) {
                    $q->where('user_id', $userId);
                } else {
                    $q->where('ip_address', $request->ip());
                }
            })
            ->whereDate('created_at', today())
            ->first();

        if (!$existingView) {
            $video->increment('views_count');

            VideoView::create([
                'video_id' => $id,
                'user_id' => $userId,
                'watch_duration_seconds' => $watchDuration,
                'counted_as_view' => $watchDuration >= 1.4,
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
                'started_at' => now(),
            ]);
        }

        return response()->json(['views_count' => $video->views_count]);
    }

    /**
     * Ajouter un commentaire (authentifié)
     */
    public function addComment(Request $request, $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'content' => 'required|string|max:1000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $video = Video::findOrFail($id);

        $comment = VideoComment::create([
            'video_id' => $id,
            'user_id' => auth()->id(),
            'content' => $request->content,
            'is_approved' => true,
        ]);

        $video->increment('comments_count');

        return response()->json(['comment' => $comment->load('user')], 201);
    }

    /**
     * Obtenir les commentaires (publique)
     */
    public function getComments($id): JsonResponse
    {
        $video = Video::findOrFail($id);

        $comments = VideoComment::where('video_id', $id)
            ->with('user')
            ->where('is_approved', true)
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json(['comments' => $comments]);
    }

    /**
     * Statistiques d'une vidéo (publique)
     */
    public function getStats($id): JsonResponse
    {
        $video = Video::where('status', 'ready')
            ->where('is_public', true)
            ->findOrFail($id);

        return response()->json([
            'stats' => [
                'views_count' => $video->views_count,
                'likes_count' => $video->likes_count,
                'comments_count' => $video->comments_count,
                'duration_seconds' => $video->duration_seconds,
                'created_at' => $video->created_at,
                'published_at' => $video->published_at,
            ]
        ]);
    }

    /**
     * Supprimer une vidéo (authentifié - propriétaire)
     */
    public function destroy($id): JsonResponse
    {
        $video = Video::where('user_id', auth()->id())->findOrFail($id);

        if ($video->video_path) {
            Storage::disk('public')->delete($video->video_path);
        }
        if ($video->thumbnail_path) {
            Storage::disk('public')->delete($video->thumbnail_path);
        }
        if ($video->processed_path) {
            Storage::disk('public')->delete($video->processed_path);
        }

        $video->delete();

        return response()->json(['message' => 'Vidéo supprimée avec succès']);
    }

    /**
     * Streamer une vidéo (PUBLIQUE - sans authentification)
     */
    public function stream($id): \Symfony\Component\HttpFoundation\StreamedResponse
    {
        $video = Video::where('status', 'ready')
            ->where('is_public', true)
            ->findOrFail($id);

        // Utiliser directement video_path (plus de compression)
        $videoPath = storage_path('app/public/' . $video->video_path);

        // Log pour débogage
        \Log::info('Streaming video', [
            'id' => $id,
            'video_path' => $video->video_path,
            'full_path' => $videoPath,
            'exists' => file_exists($videoPath),
        ]);

        if (!file_exists($videoPath)) {
            abort(404, 'Video file not found at: ' . $videoPath);
        }

        $fileSize = filesize($videoPath);
        $start = 0;
        $end = $fileSize - 1;

        if (request()->hasHeader('Range')) {
            $range = request()->header('Range');
            if (preg_match('/bytes=(\d+)-(\d*)/', $range, $matches)) {
                $start = intval($matches[1]);
                if (!empty($matches[2])) {
                    $end = intval($matches[2]);
                }
            }
        }

        $length = $end - $start + 1;
        $status = request()->hasHeader('Range') ? 206 : 200;

        return response()->stream(function () use ($videoPath, $start, $length) {
            $handle = fopen($videoPath, 'rb');
            if ($handle === false) {
                \Log::error('Failed to open video file for streaming', ['path' => $videoPath]);
                return;
            }
            fseek($handle, $start);
            echo fread($handle, $length);
            fclose($handle);
        }, $status, [
            'Content-Type' => 'video/mp4',
            'Content-Length' => $length,
            'Accept-Ranges' => 'bytes',
            'Content-Range' => "bytes $start-$end/$fileSize",
            'Cache-Control' => 'public, max-age=3600',
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Headers' => '*',
        ]);
    }
}
