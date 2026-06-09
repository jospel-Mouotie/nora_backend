<?php

namespace App\Http\Controllers;

use App\Models\MBShop;
use App\Models\MBShopItem;
use App\Models\MBShopPurchase;
use App\Models\MBCoin;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class MBShopController extends Controller
{
    /**
     * Obtenir toutes les boutiques MB
     */
    public function getShops(Request $request): JsonResponse
    {
        $query = MBShop::withCount('activeItems');

        if ($request->featured) {
            $query->featured();
        } else {
            $query->active()->orderByOrder();
        }

        $shops = $query->paginate($request->limit ?? 20);

        return response()->json(['shops' => $shops]);
    }

    /**
     * Obtenir les détails d'une boutique MB
     */
    public function getShop($id): JsonResponse
    {
        $shop = MBShop::with(['activeItems', 'featuredItems'])
            ->findOrFail($id);

        return response()->json(['shop' => $shop]);
    }

    /**
     * Obtenir les articles d'une boutique MB
     */
    public function getShopItems(Request $request, $shopId): JsonResponse
    {
        $shop = MBShop::findOrFail($shopId);
        
        $query = MBShopItem::where('mb_shop_id', $shopId)
            ->with('mbShop');

        // Filtres
        if ($request->category) {
            $query->byCategory($request->category);
        }

        if ($request->type) {
            $query->byType($request->type);
        }

        if ($request->featured) {
            $query->featured();
        } else {
            $query->active()->available();
        }

        if ($request->min_price) {
            $query->where('price_mb_coins', '>=', $request->min_price);
        }

        if ($request->max_price) {
            $query->where('price_mb_coins', '<=', $request->max_price);
        }

        if ($request->in_stock) {
            $query->inStock();
        }

        $items = $query->orderByOrder()->paginate($request->limit ?? 20);

        return response()->json([
            'items' => $items,
            'shop' => $shop,
            'categories' => $shop->items()->pluck('category')->unique()->filter()->values(),
        ]);
    }

    /**
     * Obtenir les détails d'un article
     */
    public function getItem($id): JsonResponse
    {
        $item = MBShopItem::with(['mbShop', 'purchases' => function ($q) {
            $q->where('user_id', auth()->id());
        }])->findOrFail($id);

        // Ajouter des informations supplémentaires
        $item->can_purchase = $item->canBePurchasedBy(auth()->id());
        $item->user_purchase_count = $item->purchases()
            ->where('user_id', auth()->id())
            ->count();

        return response()->json(['item' => $item]);
    }

    /**
     * Acheter un article
     */
    public function purchaseItem(Request $request, $id): JsonResponse
    {
        $item = MBShopItem::findOrFail($id);

        if (!$item->is_available) {
            return response()->json(['error' => 'Cet article n\'est pas disponible'], 400);
        }

        if (!$item->canBePurchasedBy(auth()->id())) {
            return response()->json(['error' => 'Vous ne pouvez pas acheter cet article'], 400);
        }

        $validator = Validator::make($request->all(), [
            'quantity' => 'nullable|integer|min:1|max:10',
            'delivery_address' => 'required_if:item.type,physical|array',
            'delivery_address.address' => 'required_if:item.type,physical|string|max:500',
            'delivery_address.city' => 'required_if:item.type,physical|string|max:100',
            'delivery_address.postal_code' => 'required_if:item.type,physical|string|max:20',
            'delivery_address.country' => 'required_if:item.type,physical|string|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $purchase = $item->purchase(auth()->id());

            // Ajouter les informations de livraison si article physique
            if ($item->type === 'physical' && $request->delivery_address) {
                $purchase->update([
                    'metadata->delivery_address' => $request->delivery_address,
                ]);
            }

            return response()->json([
                'message' => 'Achat effectué avec succès',
                'purchase' => $purchase->load(['mbShopItem', 'user']),
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 400);
        }
    }

    /**
     * Obtenir les achats de l'utilisateur
     */
    public function getPurchases(Request $request): JsonResponse
    {
        $query = MBShopPurchase::where('user_id', auth()->id())
            ->with(['mbShopItem', 'mbShopItem.mbShop']);

        // Filtres
        if ($request->status) {
            switch ($request->status) {
                case 'pending':
                    $query->pending();
                    break;
                case 'completed':
                    $query->completed();
                    break;
                case 'cancelled':
                    $query->cancelled();
                    break;
                case 'refunded':
                    $query->refunded();
                    break;
            }
        }

        if ($request->shop_id) {
            $query->whereHas('mbShopItem', function ($q) use ($request) {
                $q->where('mb_shop_id', $request->shop_id);
            });
        }

        if ($request->type) {
            $query->whereHas('mbShopItem', function ($q) use ($request) {
                $q->where('type', $request->type);
            });
        }

        $purchases = $query->orderBy('created_at', 'desc')
            ->paginate($request->limit ?? 20);

        return response()->json(['purchases' => $purchases]);
    }

    /**
     * Obtenir les détails d'un achat
     */
    public function getPurchase($id): JsonResponse
    {
        $purchase = MBShopPurchase::where('user_id', auth()->id())
            ->with(['mbShopItem', 'mbShopItem.mbShop'])
            ->findOrFail($id);

        return response()->json(['purchase' => $purchase]);
    }

    /**
     * Annuler un achat en attente
     */
    public function cancelPurchase($id): JsonResponse
    {
        $purchase = MBShopPurchase::where('user_id', auth()->id())
            ->where('status', 'pending')
            ->findOrFail($id);

        try {
            $purchase->markAsCancelled();

            // Rembourser les MB Coins
            $mbCoin = MBCoin::where('user_id', auth()->id())->first();
            $mbCoin->earn(
                $purchase->price_mb_coins,
                'Annulation achat: ' . $purchase->mbShopItem->name,
                'refund',
                $purchase->id
            );

            return response()->json([
                'message' => 'Achat annulé et remboursé',
                'purchase' => $purchase->fresh(),
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Demander un remboursement
     */
    public function requestRefund(Request $request, $id): JsonResponse
    {
        $purchase = MBShopPurchase::where('user_id', auth()->id())
            ->where('status', 'completed')
            ->findOrFail($id);

        $validator = Validator::make($request->all(), [
            'reason' => 'required|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Vérifier si le remboursement est possible (délai de 7 jours)
        if ($purchase->created_at->lt(now()->subDays(7))) {
            return response()->json(['error' => 'Délai de remboursement dépassé (7 jours)'], 400);
        }

        try {
            $purchase->refund($request->reason);

            return response()->json([
                'message' => 'Demande de remboursement soumise',
                'purchase' => $purchase->fresh(),
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Obtenir les articles tendances
     */
    public function getTrendingItems(Request $request): JsonResponse
    {
        $period = $request->period ?? 7; // jours
        
        $query = MBShopItem::with(['mbShop'])
            ->active()
            ->available()
            ->withCount(['purchases' => function ($q) use ($period) {
                $q->where('created_at', '>=', now()->subDays($period));
            }])
            ->orderBy('purchases_count', 'desc')
            ->orderBy('created_at', 'desc');

        if ($request->category) {
            $query->byCategory($request->category);
        }

        if ($request->type) {
            $query->byType($request->type);
        }

        if ($request->min_price) {
            $query->where('price_mb_coins', '>=', $request->min_price);
        }

        if ($request->max_price) {
            $query->where('price_mb_coins', '<=', $request->max_price);
        }

        $items = $query->limit($request->limit ?? 20)->get();

        return response()->json(['trending_items' => $items]);
    }

    /**
     * Obtenir les articles en promotion
     */
    public function getPromotionalItems(Request $request): JsonResponse
    {
        $items = MBShopItem::with(['mbShop'])
            ->active()
            ->featured()
            ->available()
            ->orderBy('sort_order', 'asc')
            ->orderBy('created_at', 'desc')
            ->limit($request->limit ?? 20)
            ->get();

        return response()->json(['promotional_items' => $items]);
    }

    /**
     * Rechercher des articles
     */
    public function searchItems(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'query' => 'required|string|min:2|max:100',
            'shop_id' => 'nullable|exists:m_b_shops,id',
            'category' => 'nullable|string|max:50',
            'type' => 'nullable|in:digital,physical,voucher,subscription',
            'min_price' => 'nullable|numeric|min:0',
            'max_price' => 'nullable|numeric|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $query = MBShopItem::with(['mbShop'])
            ->active()
            ->available();

        if ($request->shop_id) {
            $query->where('mb_shop_id', $request->shop_id);
        }

        // Recherche textuelle
        $query->where(function ($q) use ($request) {
            $q->where('name', 'LIKE', '%' . $request->query . '%')
              ->orWhere('description', 'LIKE', '%' . $request->query . '%')
              ->orWhere('category', 'LIKE', '%' . $request->query . '%');
        });

        if ($request->category) {
            $query->byCategory($request->category);
        }

        if ($request->type) {
            $query->byType($request->type);
        }

        if ($request->min_price) {
            $query->where('price_mb_coins', '>=', $request->min_price);
        }

        if ($request->max_price) {
            $query->where('price_mb_coins', '<=', $request->max_price);
        }

        $items = $query->orderByOrder()->paginate($request->limit ?? 20);

        return response()->json([
            'items' => $items,
            'search_query' => $request->query,
        ]);
    }

    /**
     * Obtenir les catégories disponibles
     */
    public function getCategories(Request $request): JsonResponse
    {
        $shopId = $request->shop_id;
        
        $query = MBShopItem::select('category')
            ->whereNotNull('category')
            ->active()
            ->available();

        if ($shopId) {
            $query->where('mb_shop_id', $shopId);
        }

        $categories = $query->distinct()
            ->orderBy('category')
            ->pluck('category')
            ->filter()
            ->values();

        return response()->json(['categories' => $categories]);
    }

    /**
     * Créer une boutique MB (admin)
     */
    public function createShop(Request $request): JsonResponse
    {
        $this->authorize('manage-mb-shops');

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'logo' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:2048', // 2MB
            'banner' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:5120', // 5MB
            'status' => 'required|in:active,inactive,maintenance',
            'is_featured' => 'boolean',
            'sort_order' => 'integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $data = $request->only(['name', 'description', 'status', 'is_featured', 'sort_order']);

            // Upload logo
            if ($request->hasFile('logo')) {
                $data['logo'] = $request->file('logo')->store('mb-shop-logos', 'public');
            }

            // Upload banner
            if ($request->hasFile('banner')) {
                $data['banner'] = $request->file('banner')->store('mb-shop-banners', 'public');
            }

            $shop = MBShop::create($data);

            return response()->json([
                'message' => 'Boutique MB créée avec succès',
                'shop' => $shop,
            ], 201);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Mettre à jour une boutique MB (admin)
     */
    public function updateShop(Request $request, $id): JsonResponse
    {
        $this->authorize('manage-mb-shops');

        $shop = MBShop::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'logo' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:2048',
            'banner' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:5120',
            'status' => 'required|in:active,inactive,maintenance',
            'is_featured' => 'boolean',
            'sort_order' => 'integer|min:0',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $data = $request->only(['name', 'description', 'status', 'is_featured', 'sort_order']);

            // Upload logo
            if ($request->hasFile('logo')) {
                // Supprimer l'ancien logo
                if ($shop->logo) {
                    Storage::disk('public')->delete($shop->logo);
                }
                $data['logo'] = $request->file('logo')->store('mb-shop-logos', 'public');
            }

            // Upload banner
            if ($request->hasFile('banner')) {
                // Supprimer l'ancienne banner
                if ($shop->banner) {
                    Storage::disk('public')->delete($shop->banner);
                }
                $data['banner'] = $request->file('banner')->store('mb-shop-banners', 'public');
            }

            $shop->update($data);

            return response()->json([
                'message' => 'Boutique MB mise à jour',
                'shop' => $shop->fresh(),
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Supprimer une boutique MB (admin)
     */
    public function deleteShop($id): JsonResponse
    {
        $this->authorize('manage-mb-shops');

        $shop = MBShop::findOrFail($id);

        try {
            // Supprimer les fichiers
            if ($shop->logo) {
                Storage::disk('public')->delete($shop->logo);
            }
            if ($shop->banner) {
                Storage::disk('public')->delete($shop->banner);
            }

            $shop->delete();

            return response()->json(['message' => 'Boutique MB supprimée']);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Obtenir les statistiques des boutiques (admin)
     */
    public function getShopStats(): JsonResponse
    {
        $this->authorize('manage-mb-shops');

        $stats = [
            'total_shops' => MBShop::count(),
            'active_shops' => MBShop::active()->count(),
            'featured_shops' => MBShop::featured()->count(),
            'total_items' => MBShopItem::count(),
            'active_items' => MBShopItem::active()->count(),
            'total_purchases' => MBShopPurchase::count(),
            'completed_purchases' => MBShopPurchase::completed()->count(),
            'total_revenue' => MBShopPurchase::completed()->sum('price_mb_coins'),
            'top_shops' => MBShop::withCount(['purchases' => function ($q) {
                $q->completed();
            }])
            ->orderBy('purchases_count', 'desc')
            ->limit(10)
            ->get(),
        ];

        return response()->json(['stats' => $stats]);
    }
}
