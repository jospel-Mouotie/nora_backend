<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CartItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'quantity',
        'unit_price',
        'total_price',
        'promotion_discount',
        'cart_id',
        'product_id',
        'variant_id',
        'product_variant_id',
    ];

    protected $casts = [
        'unit_price' => 'decimal:2',
        'total_price' => 'decimal:2',
        'promotion_discount' => 'decimal:2',
    ];

    // Relations
    public function cart()
    {
        return $this->belongsTo(Cart::class);
    }

    public function productVariant()
    {
        return $this->belongsTo(ProductVariant::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    public function variant()
    {
        return $this->belongsTo(ProductVariant::class, 'variant_id');
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

    public function updateQuantity($quantity)
    {
        $this->quantity = $quantity;
        $this->total_price = $this->unit_price * $quantity;
        $this->save();
    }

    public function applyPromotionDiscount($discount)
    {
        $this->promotion_discount = $discount;
        $this->save();
    }

    public function removePromotionDiscount()
    {
        $this->promotion_discount = 0;
        $this->save();
    }

    // Vérifier si le produit est encore en stock
    public function isInStock()
    {
        return $this->productVariant && $this->productVariant->isInStock();
    }

    public function getAvailableStock()
    {
        return $this->productVariant ? $this->productVariant->getAvailableQuantity() : 0;
    }

    // Vérifier si la quantité demandée est disponible
    public function isQuantityAvailable()
    {
        return $this->getAvailableStock() >= $this->quantity;
    }

    // Calculer le prix unitaire avec promotion
    public function getUnitPriceWithPromotion()
    {
        if ($this->quantity > 0) {
            return ($this->total_price - $this->promotion_discount) / $this->quantity;
        }
        return $this->unit_price;
    }
}
