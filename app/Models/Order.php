<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_number',
        'total_amount',
        'promotion_discount',
        'delivery_fee',
        'final_amount',
        'pin',
        'qr_code',
        'status',
        'payment_status',
        'delivery_address',
        'notes',
        'delivered_at',
        'confirmed_at',
        'user_id',
        'shop_id',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'promotion_discount' => 'decimal:2',
        'delivery_fee' => 'decimal:2',
        'final_amount' => 'decimal:2',
        'delivered_at' => 'datetime',
        'confirmed_at' => 'datetime',
        'status' => 'string',
        'payment_status' => 'string',
    ];

    // Relations
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function qrCodes()
    {
        return $this->hasMany(OrderQrCode::class);
    }

    // Scopes
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeConfirmed($query)
    {
        return $query->where('status', 'confirmed');
    }

    public function scopePreparing($query)
    {
        return $query->where('status', 'preparing');
    }

    public function scopeReady($query)
    {
        return $query->where('status', 'ready');
    }

    public function scopeDelivered($query)
    {
        return $query->where('status', 'delivered');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopePaid($query)
    {
        return $query->where('payment_status', 'paid');
    }

    public function scopePendingPayment($query)
    {
        return $query->where('payment_status', 'pending');
    }

    // Méthodes utilitaires
    public function isPending()
    {
        return $this->status === 'pending';
    }

    public function isConfirmed()
    {
        return $this->status === 'confirmed';
    }

    public function isPreparing()
    {
        return $this->status === 'preparing';
    }

    public function isReady()
    {
        return $this->status === 'ready';
    }

    public function isDelivered()
    {
        return $this->status === 'delivered';
    }

    public function isCancelled()
    {
        return $this->status === 'cancelled';
    }

    public function isPaid()
    {
        return $this->payment_status === 'paid';
    }

    public function isPaymentPending()
    {
        return $this->payment_status === 'pending';
    }

    public function confirm()
    {
        $this->update([
            'status' => 'confirmed',
            'confirmed_at' => now()
        ]);
    }

    public function startPreparing()
    {
        $this->update(['status' => 'preparing']);
    }

    public function markAsReady()
    {
        $this->update(['status' => 'ready']);
    }

    public function markAsDelivered()
    {
        $this->update([
            'status' => 'delivered',
            'delivered_at' => now()
        ]);
    }

    public function cancel()
    {
        $this->update(['status' => 'cancelled']);
    }

    public function markAsPaid()
    {
        $this->update(['payment_status' => 'paid']);
    }


    // Calculer le montant final
    public function calculateFinalAmount()
    {
        return max(0, $this->total_amount - $this->promotion_discount + $this->delivery_fee);
    }

    public function updateFinalAmount()
    {
        $this->final_amount = $this->calculateFinalAmount();
        $this->save();
    }

    // Scope pour les commandes d'une boutique
    public function scopeByShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    // Scope pour les commandes d'un utilisateur
    public function scopeByUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    // Scope pour recherche par numéro de commande
    public function scopeByOrderNumber($query, $orderNumber)
    {
        return $query->where('order_number', 'like', "%{$orderNumber}%");
    }
}
