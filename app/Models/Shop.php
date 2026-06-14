<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;

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
        'banner',
        'status',
        'certifiee',
        'certifiee_at',
        'user_id',
        // Nouveaux champs
        'delivery_cities',
        'delivery_price',
        'free_delivery_min_amount',
        'delivery_type',
        'latitude',
        'longitude',
        'opening_hours',
        'facebook_url',
        'instagram_url',
        'whatsapp_number',
    ];

    protected $casts = [
        'certifiee' => 'boolean',
        'certifiee_at' => 'datetime',
        'delivery_cities' => 'array', // JSON casté en tableau PHP
        'opening_hours' => 'array',
        'delivery_price' => 'decimal:2',
        'free_delivery_min_amount' => 'decimal:2',
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
    ];

    protected $appends = [
        'has_pending_certification',
    ];

    // Relations
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function products()
    {
        return $this->hasMany(Product::class);
    }

    public function categories()
    {
        return $this->belongsToMany(Category::class, 'shop_categories')
                    ->withTimestamps();
    }

    public function followers()
    {
        return $this->hasMany(ShopFollower::class);
    }

    public function likes()
    {
        return $this->hasMany(ShopLike::class);
    }

    public function certificationRequests()
    {
        return $this->hasMany(ShopCertificationRequest::class);
    }

    public function getHasPendingCertificationAttribute()
    {
        return $this->certificationRequests()->whereIn('status', ['pending', 'paid'])->exists();
    }

    // banners() relation removed - ShopBanner model doesn't exist

    public function videos()
    {
        return $this->hasMany(Video::class);
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeCertifiee($query)
    {
        return $query->where('certifiee', true);
    }

    public function scopeEnAttente($query)
    {
        return $query->where('status', 'en_attente');
    }

    // Accesseurs pour les URLs
    public function getPhotoUrlAttribute()
    {
        return $this->photo ? Storage::url($this->photo) : null;
    }

    public function getBannerUrlAttribute()
    {
        return $this->banner ? Storage::url($this->banner) : null;
    }

    // Accesseurs pour les villes de livraison
    public function getDeliveryCitiesListAttribute()
    {
        return is_array($this->delivery_cities) ? $this->delivery_cities : [];
    }

    public function getDeliveryCitiesStringAttribute()
    {
        return implode(', ', $this->getDeliveryCitiesListAttribute());
    }

    // Accesseurs pour les horaires
    public function getOpeningHoursFormattedAttribute()
    {
        if (!$this->opening_hours) return null;

        $hours = $this->opening_hours;
        $days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
        $formatted = [];

        foreach ($days as $day) {
            if (isset($hours[$day])) {
                $formatted[] = ucfirst($day) . ': ' . ($hours[$day]['open'] ?? 'Fermé');
            }
        }

        return $formatted;
    }

    // Vérifier si la boutique livre dans une ville donnée
    public function deliversToCity($city)
    {
        if (empty($this->delivery_cities)) return true; // Si aucune ville spécifiée, on livre partout
        return in_array($city, $this->delivery_cities);
    }

    // Calculer le prix de livraison
    public function calculateDeliveryPrice($amount, $city = null)
    {
        // Livraison gratuite si montant minimum atteint
        if ($this->free_delivery_min_amount && $amount >= $this->free_delivery_min_amount) {
            return 0;
        }

        // Vérifier si on livre dans cette ville
        if ($city && !$this->deliversToCity($city)) {
            return null; // Livraison non disponible
        }

        return $this->delivery_price;
    }

    public function publicVideos()
    {
        return $this->videos()->public()->ready()->published();
    }

    public function trendingVideos($days = 7)
    {
        return $this->videos()->trending($days);
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

    // Catégories
    public function getCategoriesIdsAttribute()
    {
        return $this->categories->pluck('id')->toArray();
    }

    public function syncCategories(array $categoryIds)
    {
        return $this->categories()->sync($categoryIds);
    }
}
