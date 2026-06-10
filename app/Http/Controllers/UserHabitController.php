<?php

namespace App\Http\Controllers;

use App\Models\UserHabitTracker;
use App\Models\Product;
use App\Models\Category;
use App\Models\Shop;
use App\Models\Video;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;

class UserHabitController extends Controller
{
    /**
     * Enregistrer une action de l'utilisateur
     */
    public function trackAction(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'action_type' => 'required|in:view,search,click,purchase,like,share,bookmark',
            'entity_type' => 'required|in:product,shop,category,video',
            'entity_id' => 'required|string',
            'metadata' => 'nullable|array',
            'context' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $userId = auth()->id();
            
            $habit = UserHabitTracker::trackAction(
                $userId,
                $request->action_type,
                $request->entity_type,
                $request->entity_id,
                $request->metadata,
                $request->context
            );

            return response()->json([
                'success' => true,
                'message' => 'Action enregistrée avec succès',
                'habit' => $habit,
            ], 201);

        } catch (\Exception $e) {
            Log::error('Error in trackAction: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir l'historique des vues de l'utilisateur
     */
    public function getViewHistory(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 50;
        $entityType = $request->entity_type;

        try {
            $viewHistory = UserHabitTracker::getUserViewHistory($userId, $limit, $entityType);

            return response()->json([
                'success' => true,
                'view_history' => $viewHistory,
                'limit' => $limit,
                'entity_type' => $entityType,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getViewHistory: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir les catégories les plus consultées par l'utilisateur
     */
    public function getMostViewedCategories(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 10;
        $days = $request->days ?? 30;

        try {
            $mostViewedCategories = UserHabitTracker::getUserMostViewedCategories($userId, $limit, $days);

            $categories = Category::whereIn('id', $mostViewedCategories->pluck('entity_id'))
                                 ->get();

            $result = $mostViewedCategories->map(function ($item) use ($categories) {
                $category = $categories->firstWhere('id', $item->entity_id);
                return [
                    'category' => $category,
                    'view_count' => $item->view_count,
                ];
            });

            return response()->json([
                'success' => true,
                'most_viewed_categories' => $result,
                'limit' => $limit,
                'days' => $days,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getMostViewedCategories: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir les produits les plus consultés par l'utilisateur
     */
    public function getMostViewedProducts(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 20;
        $days = $request->days ?? 30;

        try {
            $mostViewedProducts = UserHabitTracker::getUserMostViewedProducts($userId, $limit, $days);

            $products = Product::whereIn('id', $mostViewedProducts->pluck('entity_id'))
                              ->with(['category', 'shop'])
                              ->get();

            $result = $mostViewedProducts->map(function ($item) use ($products) {
                $product = $products->firstWhere('id', $item->entity_id);
                return [
                    'product' => $product,
                    'view_count' => $item->view_count,
                ];
            });

            return response()->json([
                'success' => true,
                'most_viewed_products' => $result,
                'limit' => $limit,
                'days' => $days,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getMostViewedProducts: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir l'historique des recherches de l'utilisateur
     */
    public function getSearchHistory(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 20;
        $days = $request->days ?? 30;

        try {
            $searchHistory = UserHabitTracker::getUserSearchHistory($userId, $limit, $days);

            return response()->json([
                'success' => true,
                'search_history' => $searchHistory,
                'limit' => $limit,
                'days' => $days,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getSearchHistory: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir l'historique des achats de l'utilisateur
     */
    public function getPurchaseHistory(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 20;
        $days = $request->days ?? 90;

        try {
            $purchaseHistory = UserHabitTracker::getUserPurchaseHistory($userId, $limit, $days);

            $productIds = $purchaseHistory->pluck('entity_id');
            $products = Product::whereIn('id', $productIds)
                              ->with(['category', 'shop'])
                              ->get()
                              ->keyBy('id');

            $result = $purchaseHistory->map(function ($item) use ($products) {
                $product = $products->get($item->entity_id);
                return [
                    'product' => $product,
                    'metadata' => $item->metadata,
                    'action_time' => $item->action_time,
                    'formatted_time' => $item->formatted_time,
                    'formatted_date' => $item->formatted_date,
                ];
            });

            return response()->json([
                'success' => true,
                'purchase_history' => $result,
                'limit' => $limit,
                'days' => $days,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getPurchaseHistory: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir le pattern d'activité de l'utilisateur
     */
    public function getActivityPattern(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $days = $request->days ?? 7;

        try {
            $activityPattern = UserHabitTracker::getUserActivityPattern($userId, $days);

            return response()->json([
                'success' => true,
                'activity_pattern' => $activityPattern,
                'days' => $days,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getActivityPattern: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir les produits recommandés pour l'utilisateur (basé sur les habitudes)
     */
    public function getRecommendedProducts(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 10;
        $days = $request->days ?? 30;

        try {
            $recommendedProducts = UserHabitTracker::getRecommendedProducts($userId, $limit, $days);

            return response()->json([
                'success' => true,
                'recommended_products' => $recommendedProducts,
                'limit' => $limit,
                'days' => $days,
                'recommendation_type' => 'based_on_habits'
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getRecommendedProducts: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir les catégories recommandées pour l'utilisateur
     */
    public function getRecommendedCategories(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 10;
        $days = $request->days ?? 30;

        try {
            $recommendedCategories = UserHabitTracker::getRecommendedCategories($userId, $limit, $days);

            return response()->json([
                'success' => true,
                'recommended_categories' => $recommendedCategories,
                'limit' => $limit,
                'days' => $days,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getRecommendedCategories: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir les boutiques recommandées pour l'utilisateur
     */
    public function getRecommendedShops(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 10;
        $days = $request->days ?? 30;

        try {
            $mostViewedShops = UserHabitTracker::where('user_id', $userId)
                                              ->where('action_type', 'view')
                                              ->where('entity_type', 'shop')
                                              ->where('action_time', '>=', now()->subDays($days))
                                              ->groupBy('entity_id')
                                              ->selectRaw('entity_id, COUNT(*) as view_count')
                                              ->orderBy('view_count', 'desc')
                                              ->limit($limit * 2)
                                              ->pluck('entity_id');

            if ($mostViewedShops->isEmpty()) {
                $shops = Shop::active()
                           ->withCount(['products', 'orders'])
                           ->orderBy('orders_count', 'desc')
                           ->limit($limit)
                           ->get();
            } else {
                $viewedShops = Shop::whereIn('id', $mostViewedShops)
                                  ->with('products.category')
                                  ->get();

                $categoryIds = $viewedShops->pluck('products')
                                         ->flatten()
                                         ->pluck('category_id')
                                         ->unique();

                $shops = Shop::whereHas('products', function ($query) use ($categoryIds) {
                                $query->whereIn('category_id', $categoryIds);
                            })
                           ->whereNotIn('id', $mostViewedShops)
                           ->active()
                           ->withCount(['products', 'orders'])
                           ->orderBy('orders_count', 'desc')
                           ->limit($limit)
                           ->get();
            }

            return response()->json([
                'success' => true,
                'recommended_shops' => $shops,
                'limit' => $limit,
                'days' => $days,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getRecommendedShops: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir les vidéos recommandées pour l'utilisateur
     */
    public function getRecommendedVideos(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 10;
        $days = $request->days ?? 30;

        try {
            $mostViewedVideos = UserHabitTracker::where('user_id', $userId)
                                               ->where('action_type', 'view')
                                               ->where('entity_type', 'video')
                                               ->where('action_time', '>=', now()->subDays($days))
                                               ->groupBy('entity_id')
                                               ->selectRaw('entity_id, COUNT(*) as view_count')
                                               ->orderBy('view_count', 'desc')
                                               ->limit($limit * 2)
                                               ->pluck('entity_id');

            if ($mostViewedVideos->isEmpty()) {
                $videos = Video::public()
                             ->with(['user', 'shop'])
                             ->orderBy('view_count', 'desc')
                             ->limit($limit)
                             ->get();
            } else {
                $viewedVideos = Video::whereIn('id', $mostViewedVideos)
                                    ->with(['category', 'shop'])
                                    ->get();

                $categoryIds = $viewedVideos->pluck('category_id')->unique();
                $shopIds = $viewedVideos->pluck('shop_id')->unique();

                $videos = Video::public()
                             ->where(function ($query) use ($categoryIds, $shopIds) {
                                 $query->whereIn('category_id', $categoryIds)
                                       ->orWhereIn('shop_id', $shopIds);
                             })
                             ->whereNotIn('id', $mostViewedVideos)
                             ->with(['user', 'shop'])
                             ->orderBy('view_count', 'desc')
                             ->limit($limit)
                             ->get();
            }

            return response()->json([
                'success' => true,
                'recommended_videos' => $videos,
                'limit' => $limit,
                'days' => $days,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getRecommendedVideos: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Obtenir les statistiques des habitudes de l'utilisateur
     */
    public function getStats(): JsonResponse
    {
        $userId = auth()->id();

        try {
            $stats = [
                'total_actions' => UserHabitTracker::where('user_id', $userId)->count(),
                'views_count' => UserHabitTracker::where('user_id', $userId)->views()->count(),
                'searches_count' => UserHabitTracker::where('user_id', $userId)->searches()->count(),
                'purchases_count' => UserHabitTracker::where('user_id', $userId)->purchases()->count(),
                'clicks_count' => UserHabitTracker::where('user_id', $userId)->byActionType('click')->count(),
                'likes_count' => UserHabitTracker::where('user_id', $userId)->byActionType('like')->count(),
                'shares_count' => UserHabitTracker::where('user_id', $userId)->byActionType('share')->count(),
                'bookmarks_count' => UserHabitTracker::where('user_id', $userId)->byActionType('bookmark')->count(),
                'most_viewed_categories' => UserHabitTracker::getUserMostViewedCategories($userId, 5, 30),
                'most_viewed_products' => UserHabitTracker::getUserMostViewedProducts($userId, 5, 30),
                'recent_activity' => UserHabitTracker::where('user_id', $userId)
                                                   ->orderBy('action_time', 'desc')
                                                   ->limit(10)
                                                   ->get(),
                'activity_pattern' => UserHabitTracker::getUserActivityPattern($userId, 7),
            ];

            return response()->json([
                'success' => true,
                'stats' => $stats
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getStats: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Supprimer l'historique des habitudes de l'utilisateur
     */
    public function clearHistory(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'days' => 'nullable|integer|min:1',
            'action_type' => 'nullable|in:view,search,click,purchase,like,share,bookmark',
            'entity_type' => 'nullable|in:product,shop,category,video',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $userId = auth()->id();
            $query = UserHabitTracker::where('user_id', $userId);

            if ($request->days) {
                $query->where('action_time', '>=', now()->subDays($request->days));
            }

            if ($request->action_type) {
                $query->where('action_type', $request->action_type);
            }

            if ($request->entity_type) {
                $query->where('entity_type', $request->entity_type);
            }

            $deletedCount = $query->delete();

            return response()->json([
                'success' => true,
                'message' => 'Historique supprimé avec succès',
                'deleted_count' => $deletedCount,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in clearHistory: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }
}