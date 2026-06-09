<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VideoComment extends Model
{
    use HasFactory;

    protected $fillable = [
        'content',
        'video_id',
        'user_id',
        'parent_id',
        'is_approved',
        'likes_count',
        'replies_count',
        'edited_at',
    ];

    protected $casts = [
        'is_approved' => 'boolean',
        'edited_at' => 'datetime',
    ];

    public function video()
    {
        return $this->belongsTo(Video::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function parent()
    {
        return $this->belongsTo(VideoComment::class, 'parent_id');
    }

    public function replies()
    {
        return $this->hasMany(VideoComment::class, 'parent_id');
    }

    public function approvedReplies()
    {
        return $this->replies()->where('is_approved', true);
    }

    public function isReply()
    {
        return !is_null($this->parent_id);
    }

    public function isParent()
    {
        return is_null($this->parent_id);
    }

    public function getFormattedTimeAttribute()
    {
        return $this->created_at->diffForHumans();
    }

    public function getIsEditedAttribute()
    {
        return !is_null($this->edited_at);
    }

    public function updateRepliesCount()
    {
        $this->update([
            'replies_count' => $this->replies()->where('is_approved', true)->count()
        ]);
    }

    public function approve()
    {
        $this->update(['is_approved' => true]);
        
        // Mettre à jour le compteur de réponses du parent
        if ($this->parent) {
            $this->parent->updateRepliesCount();
        }
    }

    public function disapprove()
    {
        $this->update(['is_approved' => false]);
        
        // Mettre à jour le compteur de réponses du parent
        if ($this->parent) {
            $this->parent->updateRepliesCount();
        }
    }

    public function edit($content)
    {
        $this->update([
            'content' => $content,
            'edited_at' => now(),
        ]);
    }

    public function incrementLikesCount()
    {
        $this->increment('likes_count');
    }

    public function decrementLikesCount()
    {
        $this->decrement('likes_count');
    }

    public function scopeApproved($query)
    {
        return $query->where('is_approved', true);
    }

    public function scopePending($query)
    {
        return $query->where('is_approved', false);
    }

    public function scopeFromUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeForVideo($query, $videoId)
    {
        return $query->where('video_id', $videoId);
    }

    public function scopeParents($query)
    {
        return $query->whereNull('parent_id');
    }

    public function scopeReplies($query)
    {
        return $query->whereNotNull('parent_id');
    }

    public function scopeWithReplies($query)
    {
        return $query->with(['replies' => function ($q) {
            $q->approved()->orderBy('created_at');
        }]);
    }
}
