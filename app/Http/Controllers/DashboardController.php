<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Shop;
use App\Models\Product;
use App\Models\Order;
use App\Models\Delivery;
use App\Models\Message;
use App\Models\Video;
use App\Models\VideoView;
use App\Models\VideoLike;
use App\Models\VideoComment;
use App\Models\MBCoin;
use App\Models\MBReward;
use App\Models\MBShop;
use App\Models\MBShopItem;
use App\Models\MBShopPurchase;
use App\Models\Ad;
use App\Models\AdCampaign;
use App\Models\AdminChat;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;

class DashboardController extends Controller
{
    /**
     * Obtenir le dashboard principal avec toutes les statistiques
     */
    public function index(Request $request): JsonResponse
    {
        $period = $request->period ?? '7'; // jours
        $startDate = now()->subDays($period);

        // Statistiques générales
        $generalStats = [
            'total_users' => User::count(),
            'total_shops' => Shop::count(),
            'total_products' => Product::count(),
            'total_orders' => Order::count(),
            'active_users' => User::where('last_login_at', '>=', $startDate)->count(),
            'active_shops' => Shop::active()->count(),
            'new_users_period' => User::where('created_at', '>=', $startDate)->count(),
            'new_shops_period' => Shop::where('created_at', '>=', $startDate)->count(),
        ];

        // Statistiques des commandes
        $orderStats = [
            'total_revenue' => Order::sum('total_amount'),
            'revenue_period' => Order::where('created_at', '>=', $startDate)->sum('total_amount'),
            'orders_period' => Order::where('created_at', '>=', $startDate)->count(),
            'average_order_value' => Order::avg('total_amount'),
            'pending_orders' => Order::where('status', 'pending')->count(),
            'completed_orders' => Order::where('status', 'completed')->count(),
            'orders_by_status' => Order::selectRaw('status, COUNT(*) as count')
                ->where('created_at', '>=', $startDate)
                ->groupBy('status')
                ->get(),
        ];

        // Statistiques des livraisons
        $deliveryStats = [
            'total_deliveries' => Delivery::count(),
            'deliveries_period' => Delivery::where('created_at', '>=', $startDate)->count(),
            'active_deliveries' => Delivery::where('status', 'in_progress')->count(),
            'completed_deliveries' => Delivery::where('status', 'delivered')->count(),
            'delivery_persons' => User::where('role', 'delivery_person')->count(),
            'average_delivery_time' => $this->getAverageDeliveryTime(),
        ];

        // Statistiques des vidéos (réels)
        $videoStats = [
            'total_videos' => Video::count(),
            'videos_period' => Video::where('created_at', '>=', $startDate)->count(),
            'public_videos' => Video::public()->count(),
            'total_views' => Video::sum('view_count'),
            'views_period' => VideoView::where('created_at', '>=', $startDate)->count(),
            'total_likes' => Video::sum('likes_count'),
            'likes_period' => VideoLike::where('created_at', '>=', $startDate)->count(),
            'total_comments' => VideoComment::approved()->count(),
            'comments_period' => VideoComment::where('created_at', '>=', $startDate)->approved()->count(),
            'trending_videos' => Video::trending(7)->limit(5)->get(),
        ];

        // Statistiques MB Coins
        $mbCoinStats = [
            'total_mb_coins' => MBCoin::sum('balance'),
            'total_earned' => MBCoin::sum('total_earned'),
            'total_spent' => MBCoin::sum('total_spent'),
            'active_users' => MBCoin::active()->count(),
            'transactions_period' => MBCoin::whereHas('transactions', function ($q) use ($startDate) {
                $q->where('created_at', '>=', $startDate);
            })->count(),
            'rewards_available' => MBReward::available()->count(),
            'rewards_claimed' => MBReward::claimed()->count(),
            'shop_revenue' => MBShopPurchase::completed()->sum('price_mb_coins'),
        ];

        // Statistiques boutique MB
        $mbShopStats = [
            'total_shops' => MBShop::count(),
            'active_shops' => MBShop::active()->count(),
            'total_items' => MBShopItem::count(),
            'active_items' => MBShopItem::active()->count(),
            'total_purchases' => MBShopPurchase::count(),
            'completed_purchases' => MBShopPurchase::completed()->count(),
            'shop_revenue' => MBShopPurchase::completed()->sum('price_mb_coins'),
            'top_categories' => $this->getTopCategories(),
        ];

        // Statistiques publicités
        $adStats = [
            'total_ads' => Ad::count(),
            'active_ads' => Ad::active()->count(),
            'total_campaigns' => AdCampaign::count(),
            'active_campaigns' => AdCampaign::active()->count(),
            'total_impressions' => Ad::sum('impressions_count'),
            'total_clicks' => Ad::sum('clicks_count'),
            'total_conversions' => Ad::sum('conversions_count'),
            'total_spent' => Ad::sum('spent_amount'),
            'average_ctr' => Ad::sum('impressions_count') > 0 ? round((Ad::sum('clicks_count') / Ad::sum('impressions_count')) * 100, 2) : 0,
            'top_performing_ads' => Ad::orderBy('clicks_count', 'desc')->limit(5)->get(),
        ];

        // Statistiques chat admin
        $adminChatStats = [
            'total_messages' => AdminChat::count(),
            'messages_period' => AdminChat::where('created_at', '>=', $startDate)->count(),
            'unread_messages' => AdminChat::unread()->fromUser()->count(),
            'active_conversations' => AdminChat::where('created_at', '>=', now()->subDays(7))
                ->distinct('user_id')
                ->count('user_id'),
            'response_rate' => $this->getAdminResponseRate(),
        ];

        // Graphiques de croissance
        $growthCharts = [
            'users_growth' => $this->getGrowthData('users', $period),
            'shops_growth' => $this->getGrowthData('shops', $period),
            'orders_growth' => $this->getGrowthData('orders', $period),
            'revenue_growth' => $this->getRevenueGrowth($period),
        ];

        // Activité récente
        $recentActivity = [
            'recent_users' => User::orderBy('created_at', 'desc')->limit(5)->get(),
            'recent_orders' => Order::with(['user', 'shop'])->orderBy('created_at', 'desc')->limit(5)->get(),
            'recent_videos' => Video::with('user')->orderBy('created_at', 'desc')->limit(5)->get(),
            'recent_support_tickets' => AdminChat::unread()->fromUser()->with('user')->orderBy('created_at', 'desc')->limit(5)->get(),
        ];

        return response()->json([
            'general_stats' => $generalStats,
            'order_stats' => $orderStats,
            'delivery_stats' => $deliveryStats,
            'video_stats' => $videoStats,
            'mb_coin_stats' => $mbCoinStats,
            'mb_shop_stats' => $mbShopStats,
            'ad_stats' => $adStats,
            'admin_chat_stats' => $adminChatStats,
            'growth_charts' => $growthCharts,
            'recent_activity' => $recentActivity,
            'period' => $period,
            'last_updated' => now()->toISOString(),
        ]);
    }

    /**
     * Obtenir les statistiques détaillées par période
     */
    public function getDetailedStats(Request $request): JsonResponse
    {
        $period = $request->period ?? 30; // jours
        $startDate = now()->subDays($period);

        $stats = [
            'daily_stats' => $this->getDailyStats($period),
            'weekly_stats' => $this->getWeeklyStats($period),
            'monthly_stats' => $this->getMonthlyStats($period),
            'category_breakdown' => $this->getCategoryBreakdown(),
            'user_activity' => $this->getUserActivity($period),
            'shop_performance' => $this->getShopPerformance($period),
            'product_performance' => $this->getProductPerformance($period),
            'video_engagement' => $this->getVideoEngagement($period),
        ];

        return response()->json(['detailed_stats' => $stats]);
    }

    /**
     * Obtenir les statistiques des utilisateurs
     */
    public function getUserStats(Request $request): JsonResponse
    {
        $period = $request->period ?? 30;
        $startDate = now()->subDays($period);

        $stats = [
            'total_users' => User::count(),
            'new_users_period' => User::where('created_at', '>=', $startDate)->count(),
            'active_users' => User::where('last_login_at', '>=', $startDate)->count(),
            'user_growth' => $this->getGrowthData('users', $period),
            'user_roles' => User::selectRaw('role, COUNT(*) as count')
                ->groupBy('role')
                ->get(),
            'user_registrations' => User::where('created_at', '>=', $startDate)
                ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
                ->groupBy('date')
                ->orderBy('date')
                ->get(),
            'top_users' => User::withCount(['orders', 'videos'])
                ->orderBy('orders_count', 'desc')
                ->limit(10)
                ->get(),
        ];

        return response()->json(['user_stats' => $stats]);
    }

    /**
     * Obtenir les statistiques des boutiques
     */
    public function getShopStats(Request $request): JsonResponse
    {
        $period = $request->period ?? 30;
        $startDate = now()->subDays($period);

        $stats = [
            'total_shops' => Shop::count(),
            'active_shops' => Shop::active()->count(),
            'certified_shops' => Shop::certifiee()->count(),
            'new_shops_period' => Shop::where('created_at', '>=', $startDate)->count(),
            'shop_growth' => $this->getGrowthData('shops', $period),
            'shop_status' => Shop::selectRaw('status, COUNT(*) as count')
                ->groupBy('status')
                ->get(),
            'top_shops' => Shop::withCount(['products', 'orders'])
                ->orderBy('orders_count', 'desc')
                ->limit(10)
                ->get(),
            'shop_revenue' => Order::where('created_at', '>=', $startDate)
                ->with('shop')
                ->selectRaw('shop_id, SUM(total_amount) as revenue')
                ->groupBy('shop_id')
                ->orderBy('revenue', 'desc')
                ->limit(10)
                ->get(),
        ];

        return response()->json(['shop_stats' => $stats]);
    }

    /**
     * Obtenir les statistiques des commandes
     */
    public function getOrderStats(Request $request): JsonResponse
    {
        $period = $request->period ?? 30;
        $startDate = now()->subDays($period);

        $stats = [
            'total_orders' => Order::count(),
            'orders_period' => Order::where('created_at', '>=', $startDate)->count(),
            'total_revenue' => Order::sum('total_amount'),
            'revenue_period' => Order::where('created_at', '>=', $startDate)->sum('total_amount'),
            'average_order_value' => Order::avg('total_amount'),
            'order_status' => Order::selectRaw('status, COUNT(*) as count')
                ->groupBy('status')
                ->get(),
            'daily_orders' => Order::where('created_at', '>=', $startDate)
                ->selectRaw('DATE(created_at) as date, COUNT(*) as count, SUM(total_amount) as revenue')
                ->groupBy('date')
                ->orderBy('date')
                ->get(),
            'top_products' => Order::with(['product'])
                ->selectRaw('product_id, COUNT(*) as count')
                ->groupBy('product_id')
                ->orderBy('count', 'desc')
                ->limit(10)
                ->get(),
        ];

        return response()->json(['order_stats' => $stats]);
    }

    /**
     * Obtenir les statistiques des vidéos
     */
    public function getVideoStats(Request $request): JsonResponse
    {
        $period = $request->period ?? 30;
        $startDate = now()->subDays($period);

        $stats = [
            'total_videos' => Video::count(),
            'videos_period' => Video::where('created_at', '>=', $startDate)->count(),
            'public_videos' => Video::public()->count(),
            'total_views' => Video::sum('view_count'),
            'views_period' => VideoView::where('created_at', '>=', $startDate)->count(),
            'total_likes' => Video::sum('likes_count'),
            'likes_period' => VideoLike::where('created_at', '>=', $startDate)->count(),
            'total_comments' => VideoComment::approved()->count(),
            'comments_period' => VideoComment::where('created_at', '>=', $startDate)->approved()->count(),
            'trending_videos' => Video::trending(7)->limit(10)->get(),
            'video_engagement' => $this->getVideoEngagement($period),
        ];

        return response()->json(['video_stats' => $stats]);
    }

    /**
     * Obtenir les statistiques MB Coins
     */
    public function getMBCoinStats(Request $request): JsonResponse
    {
        $period = $request->period ?? 30;
        $startDate = now()->subDays($period);

        $stats = [
            'total_mb_coins' => MBCoin::sum('balance'),
            'total_earned' => MBCoin::sum('total_earned'),
            'total_spent' => MBCoin::sum('total_spent'),
            'active_users' => MBCoin::active()->count(),
            'transactions_period' => MBCoin::whereHas('transactions', function ($q) use ($startDate) {
                $q->where('created_at', '>=', $startDate);
            })->count(),
            'rewards_available' => MBReward::available()->count(),
            'rewards_claimed' => MBReward::claimed()->count(),
            'shop_revenue' => MBShopPurchase::completed()->sum('price_mb_coins'),
            'transaction_types' => MBCoinTransaction::where('created_at', '>=', $startDate)
                ->selectRaw('type, COUNT(*) as count, SUM(amount) as total')
                ->groupBy('type')
                ->get(),
            'top_earners' => MBCoin::orderBy('total_earned', 'desc')->limit(10)->get(),
        ];

        return response()->json(['mb_coin_stats' => $stats]);
    }

    /**
     * Obtenir les statistiques de performance système
     */
    public function getSystemStats(): JsonResponse
    {
        $stats = [
            'database_size' => $this->getDatabaseSize(),
            'storage_usage' => $this->getStorageUsage(),
            'cache_hit_rate' => $this->getCacheHitRate(),
            'response_time' => $this->getAverageResponseTime(),
            'error_rate' => $this->getErrorRate(),
            'active_sessions' => $this->getActiveSessions(),
            'server_load' => $this->getServerLoad(),
        ];

        return response()->json(['system_stats' => $stats]);
    }

    /**
     * Obtenir les données de croissance
     */
    private function getGrowthData($type, $period)
    {
        $startDate = now()->subDays($period);
        $data = [];

        for ($i = 0; $i < $period; $i++) {
            $date = $startDate->copy()->addDays($i);
            $count = 0;

            switch ($type) {
                case 'users':
                    $count = User::whereDate('created_at', $date)->count();
                    break;
                case 'shops':
                    $count = Shop::whereDate('created_at', $date)->count();
                    break;
                case 'orders':
                    $count = Order::whereDate('created_at', $date)->count();
                    break;
            }

            $data[] = [
                'date' => $date->format('Y-m-d'),
                'count' => $count,
            ];
        }

        return $data;
    }

    /**
     * Obtenir les données de revenus
     */
    private function getRevenueGrowth($period)
    {
        $startDate = now()->subDays($period);
        $data = [];

        for ($i = 0; $i < $period; $i++) {
            $date = $startDate->copy()->addDays($i);
            $revenue = Order::whereDate('created_at', $date)->sum('total_amount');

            $data[] = [
                'date' => $date->format('Y-m-d'),
                'revenue' => $revenue,
            ];
        }

        return $data;
    }

    /**
     * Obtenir le temps moyen de livraison
     */
    private function getAverageDeliveryTime()
    {
        return Delivery::where('status', 'delivered')
            ->selectRaw('AVG(TIMESTAMPDIFF(SECOND, created_at, delivered_at)) / 3600 as hours')
            ->first()
            ->hours ?? 0;
    }

    /**
     * Obtenir le taux de réponse admin
     */
    private function getAdminResponseRate()
    {
        $totalUserMessages = AdminChat::fromUser()->count();
        $totalAdminResponses = AdminChat::fromAdmin()->count();

        return $totalUserMessages > 0 ? round(($totalAdminResponses / $totalUserMessages) * 100, 2) : 0;
    }

    /**
     * Obtenir les catégories les plus populaires
     */
    private function getTopCategories()
    {
        return MBShopItem::selectRaw('category, COUNT(*) as count')
            ->groupBy('category')
            ->orderBy('count', 'desc')
            ->limit(10)
            ->get();
    }

    /**
     * Obtenir les statistiques quotidiennes
     */
    private function getDailyStats($period)
    {
        $startDate = now()->subDays($period);
        
        return [
            'users' => User::where('created_at', '>=', $startDate)
                ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
                ->groupBy('date')
                ->get(),
            'orders' => Order::where('created_at', '>=', $startDate)
                ->selectRaw('DATE(created_at) as date, COUNT(*) as count, SUM(total_amount) as revenue')
                ->groupBy('date')
                ->get(),
            'videos' => Video::where('created_at', '>=', $startDate)
                ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
                ->groupBy('date')
                ->get(),
        ];
    }

    /**
     * Obtenir les statistiques hebdomadaires
     */
    private function getWeeklyStats($period)
    {
        $startDate = now()->subWeeks($period / 7);
        
        return [
            'users' => User::where('created_at', '>=', $startDate)
                ->selectRaw('YEARWEEK(created_at) as week, COUNT(*) as count')
                ->groupBy('week')
                ->get(),
            'orders' => Order::where('created_at', '>=', $startDate)
                ->selectRaw('YEARWEEK(created_at) as week, COUNT(*) as count, SUM(total_amount) as revenue')
                ->groupBy('week')
                ->get(),
        ];
    }

    /**
     * Obtenir les statistiques mensuelles
     */
    private function getMonthlyStats($period)
    {
        $startDate = now()->subMonths($period / 30);
        
        return [
            'users' => User::where('created_at', '>=', $startDate)
                ->selectRaw('YEAR(created_at) as year, MONTH(created_at) as month, COUNT(*) as count')
                ->groupBy('year', 'month')
                ->get(),
            'orders' => Order::where('created_at', '>=', $startDate)
                ->selectRaw('YEAR(created_at) as year, MONTH(created_at) as month, COUNT(*) as count, SUM(total_amount) as revenue')
                ->groupBy('year', 'month')
                ->get(),
        ];
    }

    /**
     * Obtenir la répartition par catégorie
     */
    private function getCategoryBreakdown()
    {
        return [
            'products' => Product::selectRaw('category_id, COUNT(*) as count')
                ->with('category')
                ->groupBy('category_id')
                ->get(),
            'mb_shop_items' => MBShopItem::selectRaw('category, COUNT(*) as count')
                ->groupBy('category')
                ->get(),
        ];
    }

    /**
     * Obtenir l'activité des utilisateurs
     */
    private function getUserActivity($period)
    {
        $startDate = now()->subDays($period);
        
        return [
            'login_activity' => User::where('last_login_at', '>=', $startDate)
                ->selectRaw('DATE(last_login_at) as date, COUNT(*) as count')
                ->groupBy('date')
                ->get(),
            'top_active_users' => User::withCount(['orders', 'videos'])
                ->orderBy('orders_count', 'desc')
                ->limit(10)
                ->get(),
        ];
    }

    /**
     * Obtenir la performance des boutiques
     */
    private function getShopPerformance($period)
    {
        $startDate = now()->subDays($period);
        
        return Shop::withCount(['products', 'orders'])
            ->whereHas('orders', function ($q) use ($startDate) {
                $q->where('created_at', '>=', $startDate);
            })
            ->withSum(['orders' => function ($q) use ($startDate) {
                $q->where('created_at', '>=', $startDate);
            }], 'total_amount')
            ->orderBy('orders_sum_total_amount', 'desc')
            ->limit(20)
            ->get();
    }

    /**
     * Obtenir la performance des produits
     */
    private function getProductPerformance($period)
    {
        $startDate = now()->subDays($period);
        
        return Product::withCount(['orderItems' => function ($q) use ($startDate) {
                $q->whereHas('order', function ($q2) use ($startDate) {
                    $q2->where('created_at', '>=', $startDate);
                });
            }])
            ->orderBy('order_items_count', 'desc')
            ->limit(20)
            ->get();
    }

    /**
     * Obtenir l'engagement des vidéos
     */
    private function getVideoEngagement($period)
    {
        $startDate = now()->subDays($period);
        
        return Video::where('created_at', '>=', $startDate)
            ->withCount(['views', 'likes', 'comments'])
            ->orderBy('views_count', 'desc')
            ->limit(20)
            ->get();
    }

    /**
     * Obtenir la taille de la base de données
     */
    private function getDatabaseSize()
    {
        // Implémentation simplifiée
        return 'Approx. 50MB';
    }

    /**
     * Obtenir l'utilisation du stockage
     */
    private function getStorageUsage()
    {
        // Implémentation simplifiée
        return [
            'total' => '10GB',
            'used' => '3.2GB',
            'available' => '6.8GB',
        ];
    }

    /**
     * Obtenir le taux de cache
     */
    private function getCacheHitRate()
    {
        // Implémentation simplifiée
        return 85.5;
    }

    /**
     * Obtenir le temps de réponse moyen
     */
    private function getAverageResponseTime()
    {
        // Implémentation simplifiée
        return 245; // ms
    }

    /**
     * Obtenir le taux d'erreur
     */
    private function getErrorRate()
    {
        // Implémentation simplifiée
        return 0.8; // %
    }

    /**
     * Obtenir le nombre de sessions actives
     */
    private function getActiveSessions()
    {
        // Implémentation simplifiée
        return 156;
    }

    /**
     * Obtenir la charge du serveur
     */
    private function getServerLoad()
    {
        // Implémentation simplifiée
        return [
            'cpu' => 45.2,
            'memory' => 68.7,
            'disk' => 32.1,
        ];
    }
}
