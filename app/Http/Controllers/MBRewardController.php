<?php

namespace App\Http\Controllers;

use App\Models\MBReward;
use App\Models\MBCoin;
use App\Models\Video;
use App\Models\VideoView;
use App\Models\VideoLike;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class MBRewardController extends Controller
{
    /**
     * Obtenir les récompenses de l'utilisateur
     */
    public function index(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'status' => 'nullable|in:available,claimed,expired',
            'type' => 'nullable|in:daily_bonus,video_view,video_like,comment,referral,achievement,special',
            'limit' => 'nullable|integer|min:1|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $mbCoin = MBCoin::where('user_id', auth()->id())->firstOrFail();
        $query = $mbCoin->rewards()->with('mbCoin');

        if ($request->status) {
            switch ($request->status) {
                case 'available':
                    $query->available();
                    break;
                case 'claimed':
                    $query->claimed();
                    break;
                case 'expired':
                    $query->expired();
                    break;
            }
        }

        if ($request->type) {
            $query->byType($request->type);
        }

        $rewards = $query->orderBy('created_at', 'desc')
            ->paginate($request->limit ?? 20);

        return response()->json([
            'rewards' => $rewards,
            'summary' => [
                'total_available' => $mbCoin->rewards()->available()->count(),
                'total_claimed' => $mbCoin->rewards()->claimed()->count(),
                'total_expired' => $mbCoin->rewards()->expired()->count(),
            ]
        ]);
    }

    /**
     * Réclamer une récompense
     */
    public function claim($id): JsonResponse
    {
        $reward = MBReward::where('id', $id)
            ->where('user_id', auth()->id())
            ->firstOrFail();

        try {
            $claimedReward = $reward->claim();

            return response()->json([
                'message' => 'Récompense réclamée avec succès',
                'reward' => $claimedReward->load('mbCoin'),
                'new_balance' => $claimedReward->mbCoin->formatted_balance,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error claiming reward: ' . $e->getMessage(), ['reward_id' => $id, 'user_id' => auth()->id()]);
            return response()->json(['error' => 'Impossible de réclamer cette récompense'], 400);
        }
    }

    /**
     * Obtenir les récompenses disponibles
     */
    public function getAvailable(Request $request): JsonResponse
    {
        $mbCoin = MBCoin::where('user_id', auth()->id())->firstOrFail();
        
        $availableRewards = $mbCoin->rewards()
            ->available()
            ->orderBy('expires_at', 'asc')
            ->get();

        return response()->json([
            'available_rewards' => $availableRewards,
            'total_value' => $availableRewards->sum('amount'),
        ]);
    }

    /**
     * Créer une récompense de visionnage vidéo
     */
    public function createVideoViewReward(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'video_id' => 'required|exists:videos,id',
            'user_id' => 'required|exists:users,id',
            'amount' => 'required|numeric|min:0.01|max:10',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Vérifier si l'utilisateur a déjà regardé cette vidéo aujourd'hui
        $existingReward = MBReward::where('user_id', $request->user_id)
            ->where('source_type', 'video')
            ->where('source_id', $request->video_id)
            ->where('type', 'video_view')
            ->whereDate('created_at', today())
            ->first();

        if ($existingReward) {
            return response()->json(['error' => 'Récompense déjà accordée pour cette vidéo aujourd\'hui'], 400);
        }

        try {
            $reward = MBReward::createVideoViewReward(
                $request->user_id,
                $request->video_id,
                $request->amount
            );

            return response()->json([
                'message' => 'Récompense de visionnage créée',
                'reward' => $reward,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error creating video view reward: ' . $e->getMessage(), ['video_id' => $request->video_id, 'user_id' => $request->user_id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de la création de la récompense'], 500);
        }
    }

    /**
     * Créer une récompense de like vidéo
     */
    public function createVideoLikeReward(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'video_id' => 'required|exists:videos,id',
            'user_id' => 'required|exists:users,id',
            'amount' => 'required|numeric|min:0.01|max:5',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Vérifier si l'utilisateur a déjà liké cette vidéo
        $existingLike = VideoLike::where('user_id', $request->user_id)
            ->where('video_id', $request->video_id)
            ->first();

        if (!$existingLike) {
            return response()->json(['error' => 'L\'utilisateur n\'a pas liké cette vidéo'], 400);
        }

        // Vérifier si une récompense existe déjà
        $existingReward = MBReward::where('user_id', $request->user_id)
            ->where('source_type', 'video')
            ->where('source_id', $request->video_id)
            ->where('type', 'video_like')
            ->first();

        if ($existingReward) {
            return response()->json(['error' => 'Récompense déjà accordée pour ce like'], 400);
        }

        try {
            $reward = MBReward::createVideoLikeReward(
                $request->user_id,
                $request->video_id,
                $request->amount
            );

            return response()->json([
                'message' => 'Récompense de like créée',
                'reward' => $reward,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error creating video like reward: ' . $e->getMessage(), ['video_id' => $request->video_id, 'user_id' => $request->user_id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de la création de la récompense'], 500);
        }
    }

    /**
     * Créer une récompense de parrainage
     */
    public function createReferralReward(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'referrer_id' => 'required|exists:users,id',
            'referred_id' => 'required|exists:users,id|different:referrer_id',
            'amount' => 'required|numeric|min:1|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Vérifier si le parrainage existe déjà
        $existingReward = MBReward::where('user_id', $request->referrer_id)
            ->where('type', 'referral')
            ->where('metadata->referred_user_id', $request->referred_id)
            ->first();

        if ($existingReward) {
            return response()->json(['error' => 'Parrainage déjà enregistré'], 400);
        }

        try {
            $reward = MBReward::createReferralReward(
                $request->referrer_id,
                $request->referred_id,
                $request->amount
            );

            return response()->json([
                'message' => 'Récompense de parrainage créée',
                'reward' => $reward,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error creating referral reward: ' . $e->getMessage(), ['referrer_id' => $request->referrer_id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de la création de la récompense de parrainage'], 500);
        }
    }

    /**
     * Créer un bonus quotidien
     */
    public function createDailyBonus(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'amount' => 'required|numeric|min:0.1|max:50',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Vérifier si le bonus quotidien a déjà été donné aujourd'hui
        $existingBonus = MBReward::where('user_id', $request->user_id)
            ->where('type', 'daily_bonus')
            ->whereDate('created_at', today())
            ->first();

        if ($existingBonus) {
            return response()->json(['error' => 'Bonus quotidien déjà accordé aujourd\'hui'], 400);
        }

        try {
            $reward = MBReward::createDailyBonus($request->user_id, $request->amount);

            return response()->json([
                'message' => 'Bonus quotidien créé',
                'reward' => $reward,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error creating daily bonus: ' . $e->getMessage(), ['user_id' => $request->user_id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de la création du bonus quotidien'], 500);
        }
    }

    /**
     * Obtenir les statistiques de récompenses
     */
    public function getStats(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'period' => 'nullable|in:7,30,90,365',
            'user_id' => 'nullable|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $userId = $request->user_id ?? auth()->id();
        $period = $request->period ?? 30;
        $startDate = now()->subDays($period);

        $mbCoin = MBCoin::where('user_id', $userId)->firstOrFail();

        $stats = [
            'total_rewards' => $mbCoin->rewards()->count(),
            'available_rewards' => $mbCoin->rewards()->available()->count(),
            'claimed_rewards' => $mbCoin->rewards()->claimed()->count(),
            'expired_rewards' => $mbCoin->rewards()->expired()->count(),
            'total_available_value' => $mbCoin->rewards()->available()->sum('amount'),
            'period_stats' => [
                'rewards_period' => $mbCoin->rewards()
                    ->where('created_at', '>=', $startDate)
                    ->count(),
                'claimed_period' => $mbCoin->rewards()
                    ->where('created_at', '>=', $startDate)
                    ->claimed()
                    ->count(),
                'value_period' => $mbCoin->rewards()
                    ->where('created_at', '>=', $startDate)
                    ->claimed()
                    ->sum('amount'),
            ],
            'by_type' => $mbCoin->rewards()
                ->where('created_at', '>=', $startDate)
                ->selectRaw('type, COUNT(*) as count, SUM(amount) as total')
                ->groupBy('type')
                ->get(),
        ];

        return response()->json(['stats' => $stats]);
    }

    /**
     * Traiter automatiquement les récompenses (job)
     */
    public function processVideoRewards(): JsonResponse
    {
        // Cette méthode peut être appelée par un job planifié
        // pour traiter les récompenses automatiques
        
        $processedCount = 0;
        
        // Traiter les visionnages de vidéos (après 1.4s)
        $videoViews = VideoView::where('counted_as_view', true)
            ->whereNull('reward_processed_at')
            ->where('created_at', '>=', now()->subHours(24))
            ->get();

        foreach ($videoViews as $view) {
            if ($view->user_id) {
                try {
                    MBReward::createVideoViewReward(
                        $view->user_id,
                        $view->video_id,
                        0.5 // 0.5 MB par vue
                    );
                    
                    $view->update(['reward_processed_at' => now()]);
                    $processedCount++;
                } catch (\Exception $e) {
                    \Log::error('Erreur traitement récompense vue: ' . $e->getMessage());
                }
            }
        }

        return response()->json([
            'message' => 'Récompenses traitées',
            'processed_count' => $processedCount,
        ]);
    }

    /**
     * Obtenir les récompenses en attente
     */
    public function getPendingRewards(): JsonResponse
    {
        $this->authorize('manage-rewards');

        $pendingRewards = MBReward::where('is_claimed', false)
            ->where('expires_at', '>', now())
            ->with('user')
            ->orderBy('expires_at', 'asc')
            ->paginate(50);

        return response()->json(['pending_rewards' => $pendingRewards]);
    }

    /**
     * Marquer des récompenses comme expirées (job)
     */
    public function markExpiredRewards(): JsonResponse
    {
        $expiredCount = MBReward::where('expires_at', '<', now())
            ->where('is_claimed', false)
            ->update(['is_claimed' => true, 'claimed_at' => now()]);

        return response()->json([
            'message' => 'Récompenses expirées marquées',
            'expired_count' => $expiredCount,
        ]);
    }
}
