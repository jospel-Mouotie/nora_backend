<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ShopStory extends Model
{
    use HasFactory;

    protected $fillable = [
        'type',
        'content',
        'caption',
        'status',
        'expires_at',
        'shop_id',
        'product_id',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
    ];

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }

    // Scope pour les stories actives et non expirées
    public function scopeActive($query)
    {
        return $query->where('status', 'active')
                    ->where('expires_at', '>', now());
    }

    // Scope pour les stories en attente de validation
    public function scopeEnAttente($query)
    {
        return $query->where('status', 'en_attente');
    }

    // Vérifier si la story est expirée
    public function isExpired()
    {
        return $this->expires_at->isPast();
    }
}
