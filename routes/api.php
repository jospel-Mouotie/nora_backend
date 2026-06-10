<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ShopController;
use App\Http\Controllers\ShopFollowController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\CartController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\DeliveryController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\VideoController;
use App\Http\Controllers\MBCoinController;
use App\Http\Controllers\MBRewardController;
use App\Http\Controllers\MBShopController;
use App\Http\Controllers\AdController;
use App\Http\Controllers\AdminChatController;
use App\Http\Controllers\AdminOrderChatController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\UserInterestController;
use App\Http\Controllers\UserHabitController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\InternalNotificationController;
use App\Http\Controllers\ShopCertificationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// ========== ROUTES PUBLIQUES (sans authentification) ==========

// Authentification
Route::post('/register', [AuthController::class, 'register'])->name('register');
Route::post('/login', [AuthController::class, 'login'])->name('login');
Route::post('/verify-code', [AuthController::class, 'verifyCode'])->name('verify-code');
Route::post('/resend-code', [AuthController::class, 'resendCode'])->name('resend-code');

// Catégories (publiques)
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/categories/tree', [CategoryController::class, 'root']);
Route::get('/categories/{id}', [CategoryController::class, 'show']);
Route::get('/categories/{id}/children', [CategoryController::class, 'children']);
Route::get('/categories/{id}/path', [CategoryController::class, 'path']);
Route::get('/categories/select-options', [CategoryController::class, 'selectOptions']);

// Produits (publiques)
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{id}', [ProductController::class, 'show']);
Route::get('/products/by-shop/{shopId}', [ProductController::class, 'byShop']);
Route::get('/products/by-category/{categoryId}', [ProductController::class, 'byCategory']);
Route::get('/products/promotions', [ProductController::class, 'promotions']);
Route::get('/products/recommended', [ProductController::class, 'getRecommended']);
Route::get('/products/trending-by-interests', [ProductController::class, 'getTrendingByInterests']);
Route::get('/products/{id}/similar', [ProductController::class, 'getSimilar']);

// Boutiques (publiques)
Route::get('/shops', [ShopController::class, 'index']);
Route::get('/shops/{id}', [ShopController::class, 'show']);
Route::get('/shops/{id}/followers', [ShopFollowController::class, 'followers']);

// Vidéos (publiques)
Route::get('/videos', [VideoController::class, 'index']);
Route::get('/videos/trending', [VideoController::class, 'trending']);
Route::get('/videos/{id}', [VideoController::class, 'show']);
Route::get('/videos/{id}/comments', [VideoController::class, 'getComments']);
Route::get('/videos/{id}/stats', [VideoController::class, 'getStats']);
Route::get('/videos/{id}/stream', [VideoController::class, 'stream']); // ✅ STREAM PUBLIC

// MB Coins - Leaderboard (public)
Route::get('/mb-coins/leaderboard', [MBCoinController::class, 'getLeaderboard']);

// MB Shop - Catalogue public
Route::get('/mb-shops', [MBShopController::class, 'getShops']);
Route::get('/mb-shops/{id}', [MBShopController::class, 'getShop']);
Route::get('/mb-shops/{shopId}/items', [MBShopController::class, 'getShopItems']);
Route::get('/mb-shop-items/{id}', [MBShopController::class, 'getItem']);
Route::get('/mb-shop-items/trending', [MBShopController::class, 'getTrendingItems']);
Route::get('/mb-shop-items/promotional', [MBShopController::class, 'getPromotionalItems']);
Route::get('/mb-shop-items/search', [MBShopController::class, 'searchItems']);
Route::get('/mb-shop-items/categories', [MBShopController::class, 'getCategories']);

// Publicités (publiques)
Route::get('/ads', [AdController::class, 'index']);
Route::get('/ads/active', [AdController::class, 'getActiveAds']);
Route::get('/ads/{id}', [AdController::class, 'show']);
Route::get('/ads/targeted', [AdController::class, 'getTargetedAds']);

// ========== ROUTES PROTÉGÉES (nécessitent authentification) ==========

Route::middleware('auth:sanctum')->group(function () {
    // Utilisateur
    Route::get('/user', function (Request $request) {
        return $request->user();
    });
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/user', [AuthController::class, 'updateProfile']);
    Route::post('/user/profile-picture', [AuthController::class, 'updateProfilePicture']);
    
    // FCM Token Management
    Route::post('/fcm-token', [AuthController::class, 'updateFcmToken']);
    Route::delete('/fcm-token', [AuthController::class, 'removeFcmToken']);

    // Gestion des boutiques (création, modification, suppression)
    Route::post('/shops', [ShopController::class, 'store']);
    Route::put('/shops/{id}', [ShopController::class, 'update']);
    Route::delete('/shops/{id}', [ShopController::class, 'destroy']);
    Route::get('/mes-boutiques', [ShopController::class, 'mesBoutiques']);

    // Admin - Validation des boutiques
    Route::get('/admin/shops/en-attente', [ShopController::class, 'enAttente']);
    Route::get('/admin/shops/pending', [ShopController::class, 'enAttente']);
    Route::post('/admin/shops/{id}/valider', [ShopController::class, 'valider']);
    Route::post('/admin/shops/{id}/refuser', [ShopController::class, 'refuser']);

    // Certification Boutiques
    Route::post('/shops/{shopId}/request-certification', [ShopCertificationController::class, 'requestCertification']);
    Route::post('/shops/certifications/{requestId}/pay', [ShopCertificationController::class, 'payCertification']);
    Route::get('/admin/certifications/pending', [ShopCertificationController::class, 'adminPendingRequests']);
    Route::post('/admin/certifications/{requestId}/validate', [ShopCertificationController::class, 'adminValidate']);
    Route::post('/admin/certifications/{requestId}/reject', [ShopCertificationController::class, 'adminReject']);

    // Abonnements et likes des boutiques
    Route::post('/shops/{id}/follow', [ShopFollowController::class, 'follow']);
    Route::delete('/shops/{id}/follow', [ShopFollowController::class, 'unfollow']);
    Route::get('/my-followed-shops', [ShopFollowController::class, 'myFollowedShops']);
    Route::post('/shops/{id}/like', [ShopFollowController::class, 'like']);
    Route::delete('/shops/{id}/like', [ShopFollowController::class, 'unlike']);
    Route::get('/shops/{id}/is-following', [ShopFollowController::class, 'isFollowing']);
    Route::get('/shops/{id}/has-liked', [ShopFollowController::class, 'hasLiked']);

    // Admin - Gestion des catégories
    Route::post('/admin/categories', [CategoryController::class, 'store']);
    Route::put('/admin/categories/{id}', [CategoryController::class, 'update']);
    Route::delete('/admin/categories/{id}', [CategoryController::class, 'destroy']);

    // Gestion des produits (création, modification, suppression)
    Route::post('/products', [ProductController::class, 'store']);
    Route::put('/products/{id}', [ProductController::class, 'update']);
    Route::delete('/products/{id}', [ProductController::class, 'destroy']);
    Route::get('/my-products', [ProductController::class, 'myProducts']);

    // Variantes de produits
    Route::get('/products/{id}/variants', [ProductController::class, 'variants']);
    Route::post('/products/{id}/variants', [ProductController::class, 'addVariant']);

    // Promotions
    Route::post('/products/{id}/activate-promotion', [ProductController::class, 'activatePromotion']);
    Route::post('/products/{id}/deactivate-promotion', [ProductController::class, 'deactivatePromotion']);

    // Panier (nécessite connexion)
    Route::get('/cart', [CartController::class, 'index']);
    Route::post('/cart/add', [CartController::class, 'addItem']);
    Route::put('/cart/items/{id}', [CartController::class, 'updateItem']);
    Route::delete('/cart/items/{id}', [CartController::class, 'removeItem']);
    Route::delete('/cart', [CartController::class, 'clear']);
    Route::get('/cart/count', [CartController::class, 'getCartCount']);
    Route::post('/cart/validate', [CartController::class, 'validateCart']);
    Route::post('/cart/apply-promotion', [CartController::class, 'applyPromotion']);

    // Commandes (nécessite connexion)
    Route::get('/orders', [OrderController::class, 'index']);
    Route::post('/orders', [OrderController::class, 'createFromCart']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::post('/orders/{id}/confirm', [OrderController::class, 'confirm']);
    Route::post('/orders/{id}/prepare', [OrderController::class, 'startPreparing']);
    Route::post('/orders/{id}/ready', [OrderController::class, 'markAsReady']);
    Route::post('/orders/{id}/deliver', [OrderController::class, 'markAsDelivered']);
    Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);
    Route::post('/orders/{id}/status', [OrderController::class, 'updateStatus']);
    Route::post('/orders/verify-pin/{pin}', [OrderController::class, 'verifyPin']);
    Route::post('/orders/verify-qr/{qrCode}', [OrderController::class, 'verifyQrCode']);
    Route::post('/orders/use-qr/{qrCode}', [OrderController::class, 'useQrCode']);

    // Commandes par boutique (propriétaire)
    Route::get('/my-shop-orders', [OrderController::class, 'byShop']);

    // Admin - Commandes en attente
    Route::get('/admin/orders/pending', [OrderController::class, 'pendingOrders']);
    Route::post('/admin/orders/{id}/assign-shop', [OrderController::class, 'assignToShop']);
    Route::post('/admin/orders/{id}/send-to-shop', [OrderController::class, 'sendToShop']);

    // Chat admin-client sur les commandes
    Route::get('/admin-order-chat/client/{orderId}/messages', [AdminOrderChatController::class, 'getClientMessages']);
    Route::post('/admin-order-chat/client/{orderId}/send', [AdminOrderChatController::class, 'sendClientMessage']);
    Route::put('/admin-order-chat/{orderId}/mark-read', [AdminOrderChatController::class, 'markAsRead']);
    Route::get('/admin-order-chat/unread-count', [AdminOrderChatController::class, 'getUnreadCount']);
    Route::get('/admin-order-chat/recent-conversations', [AdminOrderChatController::class, 'getRecentConversations']);

    // Chat admin-boutique sur les commandes
    Route::get('/admin-order-chat/shop/{orderId}/messages', [AdminOrderChatController::class, 'getShopMessages']);
    Route::post('/admin-order-chat/shop/{orderId}/send', [AdminOrderChatController::class, 'sendShopMessage']);

    // Livraisons
    Route::post('/deliveries', [DeliveryController::class, 'store']);
    Route::get('/deliveries/{delivery}', [DeliveryController::class, 'show']);
    Route::put('/deliveries/{delivery}/location', [DeliveryController::class, 'updateLocation']);
    Route::post('/deliveries/{delivery}/assign', [DeliveryController::class, 'assignDeliveryPerson']);
    Route::post('/deliveries/{delivery}/pickup', [DeliveryController::class, 'markAsPickedUp']);
    Route::post('/deliveries/{delivery}/deliver', [DeliveryController::class, 'markAsDelivered']);
    Route::post('/deliveries/{delivery}/cancel', [DeliveryController::class, 'cancel']);

    // Livreurs
    Route::get('/deliveries/delivery-person', [DeliveryController::class, 'getDeliveryPersonDeliveries']);
    Route::get('/delivery-persons/nearby', [DeliveryController::class, 'findNearbyDeliveryPersons']);

    // Statistiques livraisons
    Route::get('/deliveries/stats', [DeliveryController::class, 'getStats']);

    // Chat client-livreur
    Route::post('/chat/send', [ChatController::class, 'sendMessage']);
    Route::post('/chat/send-location', [ChatController::class, 'sendLocation']);
    Route::get('/chat/delivery/{deliveryId}/messages', [ChatController::class, 'getMessages']);
    Route::put('/chat/messages/{messageId}/read', [ChatController::class, 'markAsRead']);
    Route::put('/chat/delivery/{deliveryId}/read-all', [ChatController::class, 'markAllAsRead']);
    Route::get('/chat/unread-count', [ChatController::class, 'getUnreadCount']);
    Route::get('/chat/recent', [ChatController::class, 'getRecentChats']);
    Route::delete('/chat/messages/{messageId}', [ChatController::class, 'deleteMessage']);
    // Share video link
    Route::get('/videos/{id}/share', [VideoController::class, 'share']);
    Route::delete('/videos/{id}', [VideoController::class, 'destroy']);

    // Vidéos (upload et interactions - PROTÉGÉES)
    Route::post('/videos/upload', [VideoController::class, 'upload']);
    Route::get('/videos/my', [VideoController::class, 'myVideos']); // ✅ MES VIDÉOS (authentifié)
    // ✅ La route stream a été déplacée dans les routes publiques
    Route::post('/videos/{id}/view', [VideoController::class, 'recordView']);
    Route::post('/videos/{id}/like', [VideoController::class, 'toggleLike']);
    Route::post('/videos/{id}/comments', [VideoController::class, 'addComment']);

    // Avis & Notes (Reviews)
    Route::get('/reviews', [ReviewController::class, 'index']);
    Route::post('/reviews', [ReviewController::class, 'store']);

    // Notifications Internes
    Route::get('/notifications', [InternalNotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [InternalNotificationController::class, 'unreadCount']);
    Route::put('/notifications/{id}/read', [InternalNotificationController::class, 'markAsRead']);
    Route::put('/notifications/read-all', [InternalNotificationController::class, 'markAllAsRead']);

    // MB Coins (solde, transactions, retraits)
    Route::get('/mb-coins/balance', [MBCoinController::class, 'getBalance']);
    Route::get('/mb-coins/transactions', [MBCoinController::class, 'getTransactions']);
    Route::post('/mb-coins/withdraw', [MBCoinController::class, 'requestWithdrawal']);
    Route::get('/mb-coins/stats', [MBCoinController::class, 'getStats']);
    Route::get('/mb-coins/recent-activity', [MBCoinController::class, 'getRecentActivity']);

    // Admin MB Coins
    Route::post('/admin/mb-coins/add', [MBCoinController::class, 'addCoins']);
    Route::post('/admin/mb-coins/remove', [MBCoinController::class, 'removeCoins']);

    // Récompenses MB Coins
    Route::get('/mb-rewards', [MBRewardController::class, 'index']);
    Route::post('/mb-rewards/{id}/claim', [MBRewardController::class, 'claim']);
    Route::get('/mb-rewards/available', [MBRewardController::class, 'getAvailable']);
    Route::post('/mb-rewards/video-view', [MBRewardController::class, 'createVideoViewReward']);
    Route::post('/mb-rewards/video-like', [MBRewardController::class, 'createVideoLikeReward']);
    Route::post('/mb-rewards/referral', [MBRewardController::class, 'createReferralReward']);
    Route::post('/mb-rewards/daily-bonus', [MBRewardController::class, 'createDailyBonus']);
    Route::get('/mb-rewards/stats', [MBRewardController::class, 'getStats']);
    Route::post('/mb-rewards/process-video', [MBRewardController::class, 'processVideoRewards']);

    // Admin Récompenses MB
    Route::get('/admin/mb-rewards/pending', [MBRewardController::class, 'getPendingRewards']);
    Route::post('/admin/mb-rewards/mark-expired', [MBRewardController::class, 'markExpiredRewards']);

    // Boutique MB (achats)
    Route::post('/mb-shop-items/{id}/purchase', [MBShopController::class, 'purchaseItem']);
    Route::get('/mb-shop-purchases', [MBShopController::class, 'getPurchases']);
    Route::get('/mb-shop-purchases/{id}', [MBShopController::class, 'getPurchase']);
    Route::post('/mb-shop-purchases/{id}/cancel', [MBShopController::class, 'cancelPurchase']);
    Route::post('/mb-shop-purchases/{id}/refund', [MBShopController::class, 'requestRefund']);

    // Admin Boutique MB
    Route::post('/admin/mb-shops', [MBShopController::class, 'createShop']);
    Route::put('/admin/mb-shops/{id}', [MBShopController::class, 'updateShop']);
    Route::delete('/admin/mb-shops/{id}', [MBShopController::class, 'deleteShop']);
    Route::get('/admin/mb-shops/stats', [MBShopController::class, 'getShopStats']);

    // Publicités (création, gestion)
    Route::post('/ads', [AdController::class, 'store']);
    Route::put('/ads/{id}', [AdController::class, 'update']);
    Route::delete('/ads/{id}', [AdController::class, 'destroy']);
    Route::post('/ads/{id}/start', [AdController::class, 'start']);
    Route::post('/ads/{id}/pause', [AdController::class, 'pause']);
    Route::post('/ads/{id}/impression', [AdController::class, 'recordImpression']);
    Route::post('/ads/{id}/click', [AdController::class, 'recordClick']);
    Route::post('/ads/{id}/conversion', [AdController::class, 'recordConversion']);
    Route::get('/ads/{id}/stats', [AdController::class, 'getStats']);
    Route::get('/ads/shop/{shopId}', [AdController::class, 'getShopAds']);
    Route::get('/ads/latest', [AdController::class, 'index']);
    Route::get('/ads/global-stats', [AdController::class, 'getGlobalStats']);

    // Chat admin-client
    Route::get('/admin-chat', [AdminChatController::class, 'index']);
    Route::get('/admin-chat/conversation/{userId}', [AdminChatController::class, 'getConversation']);
    Route::post('/admin-chat/send', [AdminChatController::class, 'sendMessage']);
    Route::put('/admin-chat/mark-read', [AdminChatController::class, 'markAsRead']);
    Route::put('/admin-chat/mark-all-read/{userId}', [AdminChatController::class, 'markAllAsRead']);
    Route::get('/admin-chat/unread-count', [AdminChatController::class, 'getUnreadCount']);
    Route::get('/admin-chat/recent-conversations', [AdminChatController::class, 'getRecentConversations']);
    Route::delete('/admin-chat/{id}', [AdminChatController::class, 'deleteMessage']);
    Route::get('/admin-chat/stats', [AdminChatController::class, 'getStats']);
    Route::post('/admin-chat/transfer/{userId}', [AdminChatController::class, 'transferConversation']);
    Route::get('/admin-chat/unread-messages', [AdminChatController::class, 'getAdminUnreadMessages']);

    // Dashboard admin
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/dashboard/detailed-stats', [DashboardController::class, 'getDetailedStats']);
    Route::get('/dashboard/users', [DashboardController::class, 'getUserStats']);
    Route::get('/dashboard/shops', [DashboardController::class, 'getShopStats']);
    Route::get('/dashboard/orders', [DashboardController::class, 'getOrderStats']);
    Route::get('/dashboard/videos', [DashboardController::class, 'getVideoStats']);
    Route::get('/dashboard/mb-coins', [DashboardController::class, 'getMBCoinStats']);
    Route::get('/dashboard/system', [DashboardController::class, 'getSystemStats']);

    // Centres d'intérêt des utilisateurs
    Route::get('/user-interests', [UserInterestController::class, 'index']);
    Route::post('/user-interests', [UserInterestController::class, 'store']);
    Route::put('/user-interests/{id}', [UserInterestController::class, 'update']);
    Route::delete('/user-interests/{id}', [UserInterestController::class, 'destroy']);
    Route::get('/user-interests/recommended-categories', [UserInterestController::class, 'getRecommendedCategories']);
    Route::get('/user-interests/available-categories', [UserInterestController::class, 'getAvailableCategories']);
    Route::post('/user-interests/select-multiple', [UserInterestController::class, 'selectMultiple']);
    Route::get('/user-interests/popular', [UserInterestController::class, 'getPopularCategories']);
    Route::get('/user-interests/priority/{priorityLevel}', [UserInterestController::class, 'getByPriority']);
    Route::put('/user-interests/priorities', [UserInterestController::class, 'updatePriorities']);
    Route::get('/user-interests/stats', [UserInterestController::class, 'getStats']);
    Route::delete('/user-interests/reset', [UserInterestController::class, 'reset']);

    // Suivi des habitudes des utilisateurs
    Route::post('/user-habits/track', [UserHabitController::class, 'trackAction']);
    Route::get('/user-habits/view-history', [UserHabitController::class, 'getViewHistory']);
    Route::get('/user-habits/most-viewed-categories', [UserHabitController::class, 'getMostViewedCategories']);
    Route::get('/user-habits/most-viewed-products', [UserHabitController::class, 'getMostViewedProducts']);
    Route::get('/user-habits/search-history', [UserHabitController::class, 'getSearchHistory']);
    Route::get('/user-habits/purchase-history', [UserHabitController::class, 'getPurchaseHistory']);
    Route::get('/user-habits/activity-pattern', [UserHabitController::class, 'getActivityPattern']);
    Route::get('/user-habits/recommended-products', [UserHabitController::class, 'getRecommendedProducts']);
    Route::get('/user-habits/recommended-categories', [UserHabitController::class, 'getRecommendedCategories']);
    Route::get('/user-habits/recommended-shops', [UserHabitController::class, 'getRecommendedShops']);
    Route::get('/user-habits/recommended-videos', [UserHabitController::class, 'getRecommendedVideos']);
    Route::get('/user-habits/stats', [UserHabitController::class, 'getStats']);
    Route::delete('/user-habits/clear', [UserHabitController::class, 'clearHistory']);
    Route::get('/user-habits/export', [UserHabitController::class, 'exportData']);
});
