<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'price',
        'promotion_price',
        'promotion_percentage',
        'promotion_start',
        'promotion_end',
        'is_active',
        'in_promotion',
        'sku',
        'images',
        'category_id',
        'shop_id',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'promotion_price' => 'decimal:2',
        'promotion_start' => 'datetime',
        'promotion_end' => 'datetime',
        'is_active' => 'boolean',
        'in_promotion' => 'boolean',
        'images' => 'array',
    ];

    // Relations
    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function variants()
    {
        return $this->hasMany(ProductVariant::class);
    }

    public function stockVariants()
    {
        return $this->hasManyThrough(ProductVariant::class, VariantStock::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeInPromotion($query)
    {
        return $query->where('in_promotion', true)
                    ->where('promotion_start', '<=', now())
                    ->where('promotion_end', '>=', now());
    }

    public function scopeAvailable($query)
    {
        return $query->active()
                    ->whereHas('shop', function($shopQuery) {
                        $shopQuery->active();
                    });
    }

    public function scopeByShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function scopeByCategory($query, $categoryId)
    {
        return $query->where('category_id', $categoryId);
    }

    // Méthodes pour les promotions
    public function isInPromotion()
    {
        if (!$this->in_promotion) {
            return false;
        }

        $now = now();
        return $this->promotion_start->lte($now) && $this->promotion_end->gte($now);
    }

    public function getPromotionalPrice()
    {
        if ($this->isInPromotion()) {
            return $this->promotion_price;
        }

        return $this->price;
    }

    public function getPromotionPercentage()
    {
        if ($this->isInPromotion() && $this->promotion_percentage) {
            return $this->promotion_percentage;
        }

        return 0;
    }

    public function activatePromotion($percentage, $startDate, $endDate)
    {
        $this->update([
            'in_promotion' => true,
            'promotion_percentage' => $percentage,
            'promotion_price' => $this->price * (1 - $percentage / 100),
            'promotion_start' => $startDate,
            'promotion_end' => $endDate,
        ]);
    }

    public function deactivatePromotion()
    {
        $this->update([
            'in_promotion' => false,
            'promotion_percentage' => null,
            'promotion_price' => null,
            'promotion_start' => null,
            'promotion_end' => null,
        ]);
    }

    // Vérification du stock total
    public function getTotalStock()
    {
        return $this->stockVariants()->sum('quantity');
    }

    public function getAvailableStock()
    {
        return $this->stockVariants()->sum('quantity') - $this->stockVariants()->sum('reserved_quantity');
    }

    // Vérification si le produit est en stock
    public function isInStock()
    {
        return $this->getAvailableStock() > 0;
    }

    // Obtenir les images (JSON array)
    public function getImagesArray()
    {
        return $this->images ? json_decode($this->images, true) : [];
    }

    public function setImagesArray($images)
    {
        $this->images = json_encode($images);
    }

    // Scope pour recherche
    public function scopeSearch($query, $term)
    {
        return $query->where(function($q) use ($term) {
            $q->where('name', 'like', "%{$term}%")
              ->orWhere('description', 'like', "%{$term}%")
              ->orWhere('sku', 'like', "%{$term}%");
        });
    }
}
