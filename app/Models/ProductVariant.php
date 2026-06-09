<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductVariant extends Model
{
    use HasFactory;

    protected $fillable = [
        'size',
        'color',
        'material',
        'sku',
        'price_adjustment',
        'image',
        'is_active',
        'product_id',
    ];

    protected $casts = [
        'price_adjustment' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    // Relations
    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function stock()
    {
        return $this->hasOne(VariantStock::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeInStock($query)
    {
        return $query->whereHas('stock', function($stockQuery) {
            $stockQuery->whereRaw('quantity - reserved_quantity > 0');
        });
    }

    public function scopeBySize($query, $size)
    {
        return $query->where('size', $size);
    }

    public function scopeByColor($query, $color)
    {
        return $query->where('color', $color);
    }

    // Méthodes utilitaires
    public function getFullName()
    {
        $parts = [];
        if ($this->size) $parts[] = $this->size;
        if ($this->color) $parts[] = $this->color;
        if ($this->material) $parts[] = $this->material;
        
        return implode(' - ', $parts);
    }

    public function getStockQuantity()
    {
        return $this->stock ? $this->stock->quantity : 0;
    }

    public function getAvailableQuantity()
    {
        return $this->stock ? ($this->stock->quantity - $this->stock->reserved_quantity) : 0;
    }

    public function isInStock()
    {
        return $this->getAvailableQuantity() > 0;
    }

    public function isLowStock()
    {
        return $this->stock && $this->stock->low_stock_alert;
    }

    public function getPrice()
    {
        $basePrice = $this->product ? $this->product->price : 0;
        return $basePrice + $this->price_adjustment;
    }

    public function getPromotionalPrice()
    {
        if ($this->product && $this->product->isInPromotion()) {
            return $this->product->getPromotionalPrice() + $this->price_adjustment;
        }
        
        return $this->getPrice();
    }

    // Réservation de stock
    public function reserveStock($quantity)
    {
        if ($this->getAvailableQuantity() >= $quantity) {
            $this->stock->increment('reserved_quantity', $quantity);
            return true;
        }
        
        return false;
    }

    public function releaseStock($quantity)
    {
        if ($this->stock) {
            $this->stock->decrement('reserved_quantity', $quantity);
        }
    }

    public function confirmStockReduction($quantity)
    {
        if ($this->stock) {
            $this->stock->decrement('quantity', $quantity);
            $this->stock->decrement('reserved_quantity', $quantity);
            
            // Vérifier alerte stock bas
            if ($this->stock->quantity <= $this->stock->low_stock_threshold) {
                $this->stock->update(['low_stock_alert' => true]);
            }
        }
    }
}
