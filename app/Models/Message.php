<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Message extends Model
{
    use HasFactory;

    protected $fillable = [
        'content',
        'type',
        'delivery_id',
        'sender_id',
        'receiver_id',
        'is_read',
        'read_at',
        'attachment_path',
        'sender_latitude',
        'sender_longitude',
    ];

    protected $casts = [
        'is_read' => 'boolean',
        'read_at' => 'datetime',
        'sender_latitude' => 'decimal:8',
        'sender_longitude' => 'decimal:8',
    ];

    public function delivery()
    {
        return $this->belongsTo(Delivery::class);
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function receiver()
    {
        return $this->belongsTo(User::class, 'receiver_id');
    }

    public function markAsRead()
    {
        if (!$this->is_read) {
            $this->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
        }
    }

    public function scopeForDelivery($query, $deliveryId)
    {
        return $query->where('delivery_id', $deliveryId);
    }

    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }

    public function scopeBetweenUsers($query, $userId1, $userId2)
    {
        return $query->where(function ($q) use ($userId1, $userId2) {
            $q->where('sender_id', $userId1)
              ->where('receiver_id', $userId2);
        })->orWhere(function ($q) use ($userId1, $userId2) {
            $q->where('sender_id', $userId2)
              ->where('receiver_id', $userId1);
        });
    }

    public function getFormattedTimeAttribute()
    {
        return $this->created_at->format('H:i');
    }

    public function getFormattedDateAttribute()
    {
        return $this->created_at->format('d/m/Y');
    }

    public function getLocationUrlAttribute()
    {
        if ($this->sender_latitude && $this->sender_longitude) {
            return "https://www.google.com/maps?q={$this->sender_latitude},{$this->sender_longitude}";
        }
        return null;
    }
}
