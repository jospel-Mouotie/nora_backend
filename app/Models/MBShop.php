<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MBShop extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'logo',
        'banner',
        'status',
        'is_featured',
        'sort_order',
        'settings',
    ];

    protected $casts = [
        'is_featured' => 'boolean',
        'settings' => 'array',
    ];

    public function items()
    {
        return $this->hasMany(MBShopItem::class);
    }

    public function activeItems()
    {
        return $this->items()->where('status', 'active');
    }

    public function featuredItems()
    {
        return $this->items()->where('is_featured', true);
    }

    public function getLogoUrlAttribute()
    {
        if ($this->logo) {
            return asset('storage/' . $this->logo);
        }
        return null;
    }

    public function getBannerUrlAttribute()
    {
        if ($this->banner) {
            return asset('storage/' . $this->banner);
        }
        return null;
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    public function scopeOrderByOrder($query)
    {
        return $query->orderBy('sort_order', 'asc')->orderBy('created_at', 'desc');
    }

    public function getTotalItemsAttribute()
    {
        return $this->items()->count();
    }

    public function getActiveItemsAttribute()
    {
        return $this->items()->where('status', 'active')->count();
    }

    public function getLowStockItemsAttribute()
    {
        return $this->items()->where('stock', '<=', 5)->count();
    }

    public function updateItemCounts()
    {
        $this->update([
            'total_items' => $this->getTotalItemsAttribute(),
            'active_items' => $this->getActiveItemsAttribute(),
            'low_stock_items' => $this->getLowStockItemsAttribute(),
        ]);
    }
}
