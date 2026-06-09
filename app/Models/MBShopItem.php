<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class MBShopItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'mb_shop_id',
        'name',
        'description',
        'image',
        'price_mb_coins',
        'type',
        'category',
        'stock',
        'max_per_user',
        'is_active',
        'is_featured',
        'is_limited',
        'starts_at',
        'ends_at',
        'metadata',
        'sort_order',
    ];

    protected $casts = [
        'price_mb_coins' => 'decimal:2',
        'is_active' => 'boolean',
        'is_featured' => 'boolean',
        'is_limited' => 'boolean',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'metadata' => 'array',
    ];

    public function mbShop()
    {
        return $this->belongsTo(MBShop::class);
    }

    public function purchases()
    {
        return $this->hasMany(MBShopPurchase::class);
    }

    public function getImageUrlAttribute()
    {
        if ($this->image) {
            return asset('storage/' . $this->image);
        }
        return null;
    }

    public function getFormattedPriceAttribute()
    {
        return number_format($this->price_mb_coins, 2, ',', ' ') . ' MB';
    }

    public function getIsAvailableAttribute()
    {
        if (!$this->is_active) {
            return false;
        }

        if ($this->starts_at && $this->starts_at->isFuture()) {
            return false;
        }

        if ($this->ends_at && $this->ends_at->isPast()) {
            return false;
        }

        if ($this->stock <= 0) {
            return false;
        }

        return true;
    }

    public function getIsLowStockAttribute()
    {
        return $this->stock <= 5;
    }

    public function getIsOutOfStockAttribute()
    {
        return $this->stock <= 0;
    }

    public function getTypeLabelAttribute()
    {
        $types = [
            'digital' => 'Produit Digital',
            'physical' => 'Produit Physique',
            'voucher' => 'Bon d\'Achat',
            'subscription' => 'Abonnement',
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function canBePurchasedBy($userId)
    {
        if (!$this->is_available) {
            return false;
        }

        if ($this->is_limited && $this->max_per_user) {
            $purchasedCount = $this->purchases()
                ->where('user_id', $userId)
                ->count();

            if ($purchasedCount >= $this->max_per_user) {
                return false;
            }
        }

        return true;
    }

    public function purchase($userId)
    {
        if (!$this->canBePurchasedBy($userId)) {
            throw new \Exception('Cet article ne peut pas être acheté');
        }

        $mbCoin = MBCoin::where('user_id', $userId)->first();
        
        if (!$mbCoin || $mbCoin->balance < $this->price_mb_coins) {
            throw new \Exception('Solde MB Coins insuffisant');
        }

        return DB::transaction(function () use ($userId, $mbCoin) {
            // Débiter le compte
            $mbCoin->spend(
                $this->price_mb_coins,
                "Achat: {$this->name}",
                'purchase',
                $this->id
            );

            // Créer l'achat
            $purchase = MBShopPurchase::create([
                'user_id' => $userId,
                'mb_shop_item_id' => $this->id,
                'price_mb_coins' => $this->price_mb_coins,
                'status' => 'completed',
                'metadata' => [
                    'item_name' => $this->name,
                    'item_type' => $this->type,
                ],
            ]);

            // Décrémenter le stock
            if ($this->type !== 'digital') {
                $this->decrement('stock');
            }

            return $purchase;
        });
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    public function scopeInStock($query)
    {
        return $query->where('stock', '>', 0);
    }

    public function scopeAvailable($query)
    {
        return $query->where('is_active', true)
                    ->where(function ($q) {
                        $q->whereNull('starts_at')
                          ->orWhere('starts_at', '<=', now());
                    })
                    ->where(function ($q) {
                        $q->whereNull('ends_at')
                          ->orWhere('ends_at', '>', now());
                    })
                    ->where('stock', '>', 0);
    }

    public function scopeByCategory($query, $category)
    {
        return $query->where('category', $category);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeOrderByOrder($query)
    {
        return $query->orderBy('sort_order', 'asc')->orderBy('created_at', 'desc');
    }
}
