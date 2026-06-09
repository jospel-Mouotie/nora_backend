<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Cart extends Model
{
    use HasFactory;

    protected $fillable = [
        'total_amount',
        'promotion_discount',
        'status',
        'expires_at',
        'user_id',
    ];

    protected $casts = [
        'total_amount' => 'decimal:2',
        'promotion_discount' => 'decimal:2',
        'expires_at' => 'datetime',
        'status' => 'string',
    ];

    // Relations
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function items()
    {
        return $this->hasMany(CartItem::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeExpired($query)
    {
        return $query->where('status', 'expired');
    }

    public function scopeAbandoned($query)
    {
        return $query->where('status', 'abandoned');
    }

    // Méthodes utilitaires
    public function isActive()
    {
        return $this->status === 'active';
    }

    public function isExpired()
    {
        return $this->expires_at && $this->expires_at->isPast();
    }

    public function isAbandoned()
    {
        return $this->status === 'abandoned';
    }

    public function getTotalItems()
    {
        return $this->items()->sum('quantity');
    }

    public function calculateTotal()
    {
        return $this->items()->sum('total_price');
    }

    public function updateTotal()
    {
        $this->total_amount = $this->calculateTotal();
        $this->save();
    }

    public function applyPromotionDiscount($discount)
    {
        $this->promotion_discount = $discount;
        $this->total_amount = max(0, $this->calculateTotal() - $discount);
        $this->save();
    }

    public function expire()
    {
        $this->update([
            'status' => 'expired',
            'expires_at' => now()
        ]);
    }

    public function abandon()
    {
        $this->update([
            'status' => 'abandoned'
        ]);
    }

    // Nettoyer les paniers expirés (méthode statique)
    public static function cleanupExpired()
    {
        self::where('expires_at', '<', now())
            ->where('status', 'active')
            ->update(['status' => 'expired']);
    }

    // Scope pour les paniers sur le point d'expirer
    public function scopeExpiringSoon($query, $hours = 24)
    {
        return $query->active()
                    ->where('expires_at', '<=', now()->addHours($hours));
    }
}
