<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdminChat extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'admin_id',
        'content',
        'type',
        'sender_type',
        'is_read',
        'read_at',
        'attachment_path',
        'metadata',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'read_at' => 'datetime',
        'metadata' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function admin()
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    public function getAttachmentUrlAttribute()
    {
        if ($this->attachment_path) {
            return asset('storage/' . $this->attachment_path);
        }
        return null;
    }

    public function getFormattedTimeAttribute()
    {
        return $this->created_at->diffForHumans();
    }

    public function getIsFromUserAttribute()
    {
        return $this->sender_type === 'user';
    }

    public function getIsFromAdminAttribute()
    {
        return $this->sender_type === 'admin';
    }

    public function getTypeLabelAttribute()
    {
        $types = [
            'text' => 'Texte',
            'image' => 'Image',
            'file' => 'Fichier',
            'system' => 'Système',
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function markAsRead()
    {
        $this->update([
            'is_read' => true,
            'read_at' => now(),
        ]);
    }

    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    public function scopeFromUser($query)
    {
        return $query->where('sender_type', 'user');
    }

    public function scopeFromAdmin($query)
    {
        return $query->where('sender_type', 'admin');
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeForAdmin($query, $adminId)
    {
        return $query->where('admin_id', $adminId);
    }

    public function scopeRecent($query, $limit = 50)
    {
        return $query->orderBy('created_at', 'desc')->limit($limit);
    }

    public function scopeWithParticipants($query)
    {
        return $query->with(['user', 'admin']);
    }
}
