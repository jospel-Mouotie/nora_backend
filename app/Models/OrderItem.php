<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'quantity',
        'unit_price',
        'total_price',
        'promotion_discount',
        'order_id',
        'product_variant_id',
    ];

    protected $casts = [
        'unit_price' => 'decimal:2',
        'total_price' => 'decimal:2',
        'promotion_discount' => 'decimal:2',
    ];

    // Relations
    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function productVariant()
    {
        return $this->belongsTo(ProductVariant::class);
    }

    public function product()
    {
        return $this->hasOneThrough(Product::class, ProductVariant::class);
    }

    // Méthodes utilitaires
    public function getFinalPrice()
    {
        return max(0, $this->total_price - $this->promotion_discount);
    }

    public function hasPromotion()
    {
        return $this->promotion_discount > 0;
    }

    public function getUnitPriceWithPromotion()
    {
        if ($this->quantity > 0) {
            return ($this->total_price - $this->promotion_discount) / $this->quantity;
        }
        return $this->unit_price;
    }
}
