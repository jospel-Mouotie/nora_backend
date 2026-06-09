<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VariantStock extends Model
{
    use HasFactory;

    protected $fillable = [
        'quantity',
        'reserved_quantity',
        'low_stock_threshold',
        'low_stock_alert',
        'product_variant_id',
    ];

    protected $casts = [
        'low_stock_alert' => 'boolean',
    ];

    // Relations
    public function productVariant()
    {
        return $this->belongsTo(ProductVariant::class);
    }

    // Scopes
    public function scopeLowStock($query)
    {
        return $query->where('low_stock_alert', true);
    }

    public function scopeInStock($query)
    {
        return $query->whereRaw('quantity - reserved_quantity > 0');
    }

    public function scopeOutOfStock($query)
    {
        return $query->whereRaw('quantity - reserved_quantity <= 0');
    }

    // Méthodes utilitaires
    public function getAvailableQuantity()
    {
        return $this->quantity - $this->reserved_quantity;
    }

    public function isInStock()
    {
        return $this->getAvailableQuantity() > 0;
    }

    public function isOutOfStock()
    {
        return $this->getAvailableQuantity() <= 0;
    }

    public function isLowStock()
    {
        return $this->low_stock_alert || $this->getAvailableQuantity() <= $this->low_stock_threshold;
    }

    public function reserveQuantity($quantity)
    {
        if ($this->getAvailableQuantity() >= $quantity) {
            $this->increment('reserved_quantity', $quantity);
            return true;
        }
        
        return false;
    }

    public function releaseQuantity($quantity)
    {
        $this->decrement('reserved_quantity', $quantity);
    }

    public function confirmStockReduction($quantity)
    {
        $this->decrement('quantity', $quantity);
        $this->decrement('reserved_quantity', $quantity);
        
        // Vérifier et activer l'alerte stock bas
        if ($this->getAvailableQuantity() <= $this->low_stock_threshold) {
            $this->update(['low_stock_alert' => true]);
        }
    }

    public function adjustStock($quantity)
    {
        $this->increment('quantity', $quantity);
        
        // Réinitialiser l'alerte si le stock est suffisant
        if ($this->getAvailableQuantity() > $this->low_stock_threshold) {
            $this->update(['low_stock_alert' => false]);
        }
    }

    public function resetLowStockAlert()
    {
        $this->update(['low_stock_alert' => false]);
    }
}
