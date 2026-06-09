<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserHabitTracker extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'action_type',
        'entity_type',
        'entity_id',
        'metadata',
        'action_time',
        'session_id',
        'ip_address',
        'user_agent',
        'context',
    ];

    protected $casts = [
        'metadata' => 'array',
        'action_time' => 'datetime',
        'context' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function getActionTypeLabelAttribute()
    {
        $types = [
            'view' => 'Vue',
            'search' => 'Recherche',
            'click' => 'Clic',
            'purchase' => 'Achat',
            'like' => 'Like',
            'share' => 'Partage',
            'bookmark' => 'Favori',
        ];

        return $types[$this->action_type] ?? $this->action_type;
    }

    public function getEntityTypeLabelAttribute()
    {
        $types = [
            'product' => 'Produit',
            'shop' => 'Boutique',
            'category' => 'Catégorie',
            'video' => 'Vidéo',
        ];

        return $types[$this->entity_type] ?? $this->entity_type;
    }

    public function getFormattedTimeAttribute()
    {
        return $this->action_time->format('H:i');
    }

    public function getFormattedDateAttribute()
    {
        return $this->action_time->format('d/m/Y');
    }

    // Méthodes statiques pour le suivi des habitudes
    public static function trackAction($userId, $actionType, $entityType, $entityId, $metadata = null, $context = null)
    {
        return self::create([
            'user_id' => $userId,
            'action_type' => $actionType,
            'entity_type' => $entityType,
            'entity_id' => $entityId,
            'metadata' => $metadata,
            'action_time' => now(),
            'session_id' => session()->getId(),
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'context' => $context,
        ]);
    }

    public static function trackProductView($userId, $productId, $metadata = null)
    {
        return self::trackAction($userId, 'view', 'product', $productId, $metadata);
    }

    public static function trackProductSearch($userId, $searchQuery, $resultsCount = null)
    {
        return self::trackAction($userId, 'search', 'product', 'search', [
            'query' => $searchQuery,
            'results_count' => $resultsCount,
        ]);
    }

    public static function trackProductClick($userId, $productId, $context = null)
    {
        return self::trackAction($userId, 'click', 'product', $productId, null, $context);
    }

    public static function trackProductPurchase($userId, $productId, $orderId, $amount = null)
    {
        return self::trackAction($userId, 'purchase', 'product', $productId, [
            'order_id' => $orderId,
            'amount' => $amount,
        ]);
    }

    public static function trackShopView($userId, $shopId, $metadata = null)
    {
        return self::trackAction($userId, 'view', 'shop', $shopId, $metadata);
    }

    public static function trackCategoryView($userId, $categoryId, $metadata = null)
    {
        return self::trackAction($userId, 'view', 'category', $categoryId, $metadata);
    }

    public static function trackVideoView($userId, $videoId, $duration = null)
    {
        return self::trackAction($userId, 'view', 'video', $videoId, [
            'duration' => $duration,
        ]);
    }

    // Méthodes d'analyse des habitudes
    public static function getUserViewHistory($userId, $limit = 50, $entityType = null)
    {
        $query = self::where('user_id', $userId)
                   ->where('action_type', 'view')
                   ->orderBy('action_time', 'desc');

        if ($entityType) {
            $query->where('entity_type', $entityType);
        }

        return $query->limit($limit)->get();
    }

    public static function getUserMostViewedCategories($userId, $limit = 10, $days = 30)
    {
        $startDate = now()->subDays($days);

        return self::where('user_id', $userId)
                   ->where('action_type', 'view')
                   ->where('entity_type', 'category')
                   ->where('action_time', '>=', $startDate)
                   ->groupBy('entity_id')
                   ->selectRaw('entity_id, COUNT(*) as view_count')
                   ->orderBy('view_count', 'desc')
                   ->limit($limit)
                   ->get();
    }

    public static function getUserMostViewedProducts($userId, $limit = 20, $days = 30)
    {
        $startDate = now()->subDays($days);

        return self::where('user_id', $userId)
                   ->where('action_type', 'view')
                   ->where('entity_type', 'product')
                   ->where('action_time', '>=', $startDate)
                   ->groupBy('entity_id')
                   ->selectRaw('entity_id, COUNT(*) as view_count')
                   ->orderBy('view_count', 'desc')
                   ->limit($limit)
                   ->get();
    }

    public static function getUserSearchHistory($userId, $limit = 20, $days = 30)
    {
        $startDate = now()->subDays($days);

        return self::where('user_id', $userId)
                   ->where('action_type', 'search')
                   ->where('action_time', '>=', $startDate)
                   ->orderBy('action_time', 'desc')
                   ->limit($limit)
                   ->get();
    }

    public static function getUserPurchaseHistory($userId, $limit = 20, $days = 90)
    {
        $startDate = now()->subDays($days);

        return self::where('user_id', $userId)
                   ->where('action_type', 'purchase')
                   ->where('action_time', '>=', $startDate)
                   ->orderBy('action_time', 'desc')
                   ->limit($limit)
                   ->get();
    }

    public static function getUserActivityPattern($userId, $days = 7)
    {
        $startDate = now()->subDays($days);

        return self::where('user_id', $userId)
                   ->where('action_time', '>=', $startDate)
                   ->selectRaw('DATE(action_time) as date, action_type, COUNT(*) as count')
                   ->groupBy('date', 'action_type')
                   ->orderBy('date', 'desc')
                   ->get();
    }

    public static function getRecommendedProducts($userId, $limit = 10, $days = 30)
    {
        // Basé sur les produits les plus vus par l'utilisateur
        $mostViewedProducts = self::getUserMostViewedProducts($userId, $limit * 2, $days)
                                    ->pluck('entity_id');

        if ($mostViewedProducts->isEmpty()) {
            // Si l'utilisateur n'a pas d'historique, retourner les produits les plus populaires
            return Product::with(['category', 'shop'])
                           ->orderBy('view_count', 'desc')
                           ->limit($limit)
                           ->get();
        }

        // Trouver des produits similaires basés sur les catégories vues
        $viewedProducts = Product::whereIn('id', $mostViewedProducts)
                                ->pluck('category_id');

        return Product::whereIn('category_id', $viewedProducts)
                       ->whereNotIn('id', $mostViewedProducts)
                       ->with(['category', 'shop'])
                       ->orderBy('view_count', 'desc')
                       ->limit($limit)
                       ->get();
    }

    public static function getRecommendedCategories($userId, $limit = 10, $days = 30)
    {
        // Basé sur les catégories les plus consultées par l'utilisateur
        $mostViewedCategories = self::getUserMostViewedCategories($userId, $limit * 2, $days)
                                     ->pluck('entity_id');

        if ($mostViewedCategories->isEmpty()) {
            // Si l'utilisateur n'a pas d'historique, retourner les catégories les plus populaires
            return Category::orderBy('products_count', 'desc')
                           ->limit($limit)
                           ->get();
        }

        // Trouver des catégories similaires basées sur les utilisateurs avec les mêmes intérêts
        $similarCategories = Category::whereIn('parent_id', $mostViewedCategories)
                                  ->orWhereIn('id', $mostViewedCategories)
                                  ->orderBy('products_count', 'desc')
                                  ->limit($limit)
                                  ->get();

        return $similarCategories;
    }

    // Scopes pour les requêtes
    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeByActionType($query, $actionType)
    {
        return $query->where('action_type', $actionType);
    }

    public function scopeByEntityType($query, $entityType)
    {
        return $query->where('entity_type', $entityType);
    }

    public function scopeInPeriod($query, $startDate, $endDate)
    {
        return $query->whereBetween('action_time', [$startDate, $endDate]);
    }

    public function scopeRecent($query, $limit = 50)
    {
        return $query->orderBy('action_time', 'desc')->limit($limit);
    }

    public function scopeViews($query)
    {
        return $query->where('action_type', 'view');
    }

    public function scopeSearches($query)
    {
        return $query->where('action_type', 'search');
    }

    public function scopePurchases($query)
    {
        return $query->where('action_type', 'purchase');
    }
}
