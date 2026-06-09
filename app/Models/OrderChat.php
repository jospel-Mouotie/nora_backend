<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class OrderChat extends Model
{
    protected $fillable = [
        'order_id',
        'sender_id',
        'sender_type', // 'admin', 'client', 'shop'
        'message',
        'chat_type', // 'admin_client' ou 'admin_shop'
        'is_read',
    ];

    protected $casts = [
        'is_read' => 'boolean',
    ];

    /**
     * Relation avec la commande
     */
    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    /**
     * Relation avec l'expéditeur (utilisateur)
     */
    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
