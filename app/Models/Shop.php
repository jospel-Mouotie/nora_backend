<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;


class Shop extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'address',
        'phone',
        'email',
        'photo',
        'status',
        'certifiee',
        'certifiee_at',
        'user_id',
    ];

    protected $casts = [
        'certifiee' => 'boolean',
        'certifiee_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    public function followers()
    {
        return $this->hasMany(ShopFollower::class);
    }

    public function likes()
    {
        return $this->hasMany(ShopLike::class);
    }

    public function banners()
    {
        return $this->hasMany(ShopBanner::class);
    }

    public function videos()
    {
        return $this->hasMany(Video::class);
    }

    public function publicVideos()
    {
        return $this->videos()->public()->ready()->published();
    }

    public function trendingVideos($days = 7)
    {
        return $this->videos()->trending($days);
    }

    // Scope pour les boutiques actives
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    // Scope pour les boutiques certifiées
    public function scopeCertifiee($query)
    {
        return $query->where('certifiee', true);
    }

    // Scope pour les boutiques en attente
    public function scopeEnAttente($query)
    {
        return $query->where('status', 'en_attente');
    }

    public function mbShops()
    {
        return $this->hasMany(MBShop::class);
    }

    public function activeMBShop()
    {
        return $this->mbShops()->active()->first();
    }

    public function getTotalMBRevenueAttribute()
    {
        return $this->mbShops()->withSum('items.purchases', function ($q) {
            $q->where('status', 'completed');
        })->get()->sum(function ($shop) {
            return $shop->items_sum_purchases_price_mb_coins ?? 0;
        });
    }
}
