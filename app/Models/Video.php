<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Video extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'video_path',
        'trim_start',
        'trim_end',
        'thumbnail_path',
        'status',
        'duration_seconds',
        'resolution',
        'file_size_mb',
        'format',
        'is_public',
        'allow_comments',
        'allow_downloads',
        'published_at',
        'user_id',
        'shop_id',
        'metadata',
        'processed_path',
    ];

    protected $appends = ['video_url', 'thumbnail_url'];

    protected $casts = [
        'is_public' => 'boolean',
        'allow_comments' => 'boolean',
        'allow_downloads' => 'boolean',
        'published_at' => 'datetime',
        'metadata' => 'array',
        'file_size_mb' => 'decimal:2',
        'trim_start' => 'double',
        'trim_end' => 'double',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function views()
    {
        return $this->hasMany(VideoView::class);
    }

    public function likes()
    {
        return $this->hasMany(VideoLike::class);
    }

    public function comments()
    {
        return $this->hasMany(VideoComment::class);
    }

    public function approvedComments()
    {
        return $this->comments()->where('is_approved', true);
    }

    public function getFormattedDurationAttribute()
    {
        if (!$this->duration_seconds) {
            return '00:00';
        }

        $minutes = floor($this->duration_seconds / 60);
        $seconds = $this->duration_seconds % 60;

        return sprintf('%02d:%02d', $minutes, $seconds);
    }

    public function getFormattedFileSizeAttribute()
    {
        if (!$this->file_size_mb) {
            return '0 MB';
        }

        if ($this->file_size_mb < 1024) {
            return number_format($this->file_size_mb, 2) . ' MB';
        }

        $gb = $this->file_size_mb / 1024;
        return number_format($gb, 2) . ' GB';
    }

    public function getStreamUrlAttribute()
    {
        // Utiliser directement video_path (plus de compression)
        if ($this->video_path) {
            return asset('storage/' . $this->video_path);
        }

        return null;
    }

    public function getIsLikedByUserAttribute()
    {
        if (!auth()->check()) {
            return false;
        }

        return $this->likes()->where('user_id', auth()->id())->exists();
    }

    public function incrementViewCount($userId = null, $watchDuration = null)
    {
        // Créer un enregistrement de vue
        $view = $this->views()->create([
            'user_id' => $userId,
            'watch_duration_seconds' => $watchDuration,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);

        // Compter comme vue seulement si >= 1.4 secondes
        if ($watchDuration && $watchDuration >= 1.4) {
            $this->increment('view_count');
        }

        return $view;
    }

    public function toggleLike($userId)
    {
        $like = $this->likes()->where('user_id', $userId)->first();

        if ($like) {
            $like->delete();
            $this->decrement('likes_count');
            return false; // Unliked
        } else {
            $this->likes()->create(['user_id' => $userId]);
            $this->increment('likes_count');
            return true; // Liked
        }
    }

    public function scopePublic($query)
    {
        return $query->where('is_public', true);
    }

    public function scopeReady($query)
    {
        return $query->where('status', 'ready');
    }

    public function scopePublished($query)
    {
        return $query->whereNotNull('published_at')
                    ->where('published_at', '<=', now());
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function scopeTrending($query, $days = 7)
    {
        return $query->withCount(['views' => function ($q) use ($days) {
                    $q->where('created_at', '>=', now()->subDays($days));
                }])
                ->withCount(['likes' => function ($q) use ($days) {
                    $q->where('created_at', '>=', now()->subDays($days));
                }])
                ->orderBy('views_count', 'desc')
                ->orderBy('likes_count', 'desc');
    }
    // app/Models/Video.php

// Ajouter ces méthodes dans le modèle Video

/**
 * Obtenir l'URL complète de la vidéo
 */
public function getVideoUrlAttribute(): string
{
    if (!$this->video_path) {
        return '';
    }
    return asset('storage/' . $this->video_path);
}

/**
 * Obtenir l'URL complète de la miniature
 */
public function getThumbnailUrlAttribute(): string
{
    if (!$this->thumbnail_path) {
        return '';
    }
    return asset('storage/' . $this->thumbnail_path);
}
}
