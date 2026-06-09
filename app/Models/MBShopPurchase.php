<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class MBShopPurchase extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'mb_shop_item_id',
        'price_mb_coins',
        'status',
        'metadata',
        'payment_reference',
        'delivered_at',
        'refunded_at',
        'refund_reason',
    ];

    protected $casts = [
        'price_mb_coins' => 'decimal:2',
        'metadata' => 'array',
        'delivered_at' => 'datetime',
        'refunded_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function mbShopItem()
    {
        return $this->belongsTo(MBShopItem::class);
    }

    public function getFormattedPriceAttribute()
    {
        return number_format($this->price_mb_coins, 2, ',', ' ') . ' MB';
    }

    public function getStatusLabelAttribute()
    {
        $statuses = [
            'pending' => 'En Attente',
            'completed' => 'Complété',
            'cancelled' => 'Annulé',
            'refunded' => 'Remboursé',
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getIsPendingAttribute()
    {
        return $this->status === 'pending';
    }

    public function getIsCompletedAttribute()
    {
        return $this->status === 'completed';
    }

    public function getIsCancelledAttribute()
    {
        return $this->status === 'cancelled';
    }

    public function getIsRefundedAttribute()
    {
        return $this->status === 'refunded';
    }

    public function markAsCompleted()
    {
        $this->update([
            'status' => 'completed',
            'delivered_at' => now(),
        ]);
    }

    public function markAsCancelled()
    {
        $this->update(['status' => 'cancelled']);
    }

    public function refund($reason = null)
    {
        if ($this->status === 'refunded') {
            throw new \Exception('Achat déjà remboursé');
        }

        return DB::transaction(function () use ($reason) {
            // Rembourser les MB Coins
            $mbCoin = MBCoin::where('user_id', $this->user_id)->first();
            $mbCoin->earn($this->price_mb_coins, 'Remboursement achat', 'refund', $this->id);

            // Mettre à jour l'achat
            $this->update([
                'status' => 'refunded',
                'refunded_at' => now(),
                'refund_reason' => $reason,
            ]);

            // Remettre l'article en stock si physique
            if ($this->mbShopItem && $this->mbShopItem->type !== 'digital') {
                $this->mbShopItem->increment('stock');
            }

            return $this;
        });
    }

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeRefunded($query)
    {
        return $query->where('status', 'refunded');
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeByItem($query, $itemId)
    {
        return $query->where('mb_shop_item_id', $itemId);
    }

    public function scopeInPeriod($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }
}
