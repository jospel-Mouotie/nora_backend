<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\VariantStock;
use App\Models\Shop;
use App\Models\UserInterest;
use App\Models\UserHabitTracker;

class ProductController extends Controller
{
    /**
     * Lister les produits (avec filtres)
     */
    public function index(Request $request)
    {
        try {
            $query = Product::with(['category', 'variants.stock', 'shop'])
                             ->available();

            // Filtres
            if ($request->has('shop_id')) {
                $query->byShop($request->shop_id);
            }

            if ($request->has('category_id')) {
                $query->byCategory($request->category_id);
            }

            if ($request->has('search')) {
                $query->search($request->search);
            }

            if ($request->has('in_promotion')) {
                $query->inPromotion();
            }

            $products = $query->orderBy('created_at', 'desc')
                               ->paginate($request->get('per_page', 15));

            return response()->json([
                'success' => true,
                'products' => $products
            ]);

        } catch (\Exception $e) {
            Log::error('Error in index: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération des produits'
            ], 500);
        }
    }

    /**
     * Créer un nouveau produit (propriétaire boutique uniquement)
     */
    public function store(Request $request)
    {
        try {
            Log::info('=== STORE PRODUCT START ===');
            Log::info('Request data:', $request->all());

            $user = $request->user();

            // Permettre aux clients de créer une boutique automatiquement s'ils n'en ont pas
            if (!$user->shop) {
                $shop = Shop::create([
                    'user_id' => $user->id,
                    'name' => $user->name . '\'s Shop',
                    'description' => 'Boutique de ' . $user->name,
                    'address' => $request->address ?? 'Adresse non renseignée',
                    'phone' => $request->phone ?? $user->phone ?? '',
                    'email' => $request->email ?? $user->email,
                    'status' => 'active',
                    'is_active' => true,
                ]);
                $user->refresh();
                Log::info('Shop created automatically:', ['shop_id' => $shop->id]);
            }

            if (!$user->shop->is_active) {
                return response()->json([
                    'success' => false,
                    'message' => 'Votre boutique n\'est pas active'
                ], 403);
            }

            // Validation - sans champ 'stock' au niveau produit
            $validator = Validator::make($request->all(), [
                'name' => 'required|string|max:255',
                'description' => 'required|string',
                'price' => 'required|numeric|min:0',
                'sku' => 'required|string|unique:products,sku',
                'category_id' => 'required|exists:categories,id',
                'images' => 'nullable|array',
                'variants' => 'nullable|array',
                'variants.*.size' => 'nullable|string|max:50',
                'variants.*.color' => 'nullable|string|max:50',
                'variants.*.material' => 'nullable|string|max:50',
                'variants.*.price_adjustment' => 'nullable|numeric',
                'variants.*.stock' => 'required|integer|min:0',
                'variants.*.sku' => 'required|string|unique:product_variants,sku',
            ]);

            if ($validator->fails()) {
                Log::warning('Validation failed:', $validator->errors()->toArray());
                return response()->json([
                    'success' => false,
                    'errors' => $validator->errors()
                ], 422);
            }

            $data = $request->all();
            $data['shop_id'] = $user->shop->id;

            // Traitement des images
            $imagesJson = null;
            if ($request->has('images') && $request->images !== null) {
                $images = $request->images;
                if (is_array($images)) {
                    $imagesJson = json_encode($images);
                }
            }

            // Création du produit SANS champ 'stock'
            $product = Product::create([
                'name' => $data['name'],
                'description' => $data['description'],
                'price' => $data['price'],
                'sku' => $data['sku'],
                'category_id' => $data['category_id'],
                'shop_id' => $data['shop_id'],
                'images' => $imagesJson,
                'is_active' => true,
            ]);

            Log::info('Product created:', ['product_id' => $product->id]);

            // Gestion des variantes et du stock
            if ($request->has('variants') && is_array($request->variants) && count($request->variants) > 0) {
                foreach ($request->variants as $variantData) {
                    // Créer la variante
                    $variant = ProductVariant::create([
                        'product_id' => $product->id,
                        'size' => $variantData['size'] ?? null,
                        'color' => $variantData['color'] ?? null,
                        'material' => $variantData['material'] ?? null,
                        'sku' => $variantData['sku'],
                        'price_adjustment' => $variantData['price_adjustment'] ?? 0,
                        'is_active' => true,
                    ]);

                    // Créer le stock pour cette variante
                    VariantStock::create([
                        'product_variant_id' => $variant->id,
                        'quantity' => $variantData['stock'],
                        'reserved_quantity' => 0,
                        'low_stock_threshold' => 5,
                        'low_stock_alert' => false,
                    ]);

                    Log::info('Variant created:', [
                        'variant_id' => $variant->id,
                        'stock' => $variantData['stock']
                    ]);
                }
            } else {
                // Si pas de variantes, créer une variante par défaut
                $defaultVariant = ProductVariant::create([
                    'product_id' => $product->id,
                    'sku' => $data['sku'] . '-DEFAULT',
                    'price_adjustment' => 0,
                    'is_active' => true,
                ]);

                $initialStock = $request->input('stock', 0);

                VariantStock::create([
                    'product_variant_id' => $defaultVariant->id,
                    'quantity' => $initialStock,
                    'reserved_quantity' => 0,
                    'low_stock_threshold' => 5,
                    'low_stock_alert' => false,
                ]);

                Log::info('Default variant created:', [
                    'variant_id' => $defaultVariant->id,
                    'stock' => $initialStock
                ]);
            }

            return response()->json([
                'success' => true,
                'message' => 'Produit créé avec succès',
                'product' => $product->load(['variants.stock'])
            ], 201);

        } catch (\Exception $e) {
            Log::error('Error in store method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la création du produit'
            ], 500);
        }
    }

    /**
     * Mettre à jour un produit
     */
    public function update(Request $request, $id)
    {
        try {
            $user = $request->user();
            $product = Product::find($id);

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => 'Produit non trouvé'
                ], 404);
            }

            if ($product->shop->user_id !== $user->id && $user->role !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autorisé'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'name' => 'sometimes|string|max:255',
                'description' => 'sometimes|string',
                'price' => 'sometimes|numeric|min:0',
                'category_id' => 'sometimes|exists:categories,id',
                'is_active' => 'sometimes|boolean',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'errors' => $validator->errors()
                ], 422);
            }

            $updateData = [];
            if ($request->has('name')) $updateData['name'] = $request->name;
            if ($request->has('description')) $updateData['description'] = $request->description;
            if ($request->has('price')) $updateData['price'] = $request->price;
            if ($request->has('category_id')) $updateData['category_id'] = $request->category_id;
            if ($request->has('is_active')) $updateData['is_active'] = $request->is_active;

            $product->update($updateData);

            // Si mise à jour du stock, mettre à jour la variante par défaut
            if ($request->has('stock')) {
                $defaultVariant = $product->variants()->first();
                if ($defaultVariant && $defaultVariant->stock) {
                    $defaultVariant->stock->update([
                        'quantity' => $request->stock
                    ]);
                }
            }

            return response()->json([
                'success' => true,
                'message' => 'Produit mis à jour avec succès',
                'product' => $product->fresh()->load(['variants.stock'])
            ]);

        } catch (\Exception $e) {
            Log::error('Error in update method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la mise à jour du produit'
            ], 500);
        }
    }

    /**
     * Supprimer un produit
     */
    public function destroy(Request $request, $id)
    {
        try {
            $user = $request->user();
            $product = Product::find($id);

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => 'Produit non trouvé'
                ], 404);
            }

            if ($product->shop->user_id !== $user->id && $user->role !== 'admin') {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autorisé'
                ], 403);
            }

            $product->delete();

            return response()->json([
                'success' => true,
                'message' => 'Produit supprimé avec succès'
            ]);

        } catch (\Exception $e) {
            Log::error('Error in destroy method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la suppression du produit'
            ], 500);
        }
    }

    /**
     * Afficher un produit
     */
    public function show($id)
    {
        try {
            $product = Product::with(['category', 'variants.stock', 'shop'])
                               ->find($id);

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => 'Produit non trouvé'
                ], 404);
            }

            return response()->json([
                'success' => true,
                'product' => $product
            ]);

        } catch (\Exception $e) {
            Log::error('Error in show method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération du produit'
            ], 500);
        }
    }

    /**
     * Produits par boutique
     */
    public function byShop($shopId)
    {
        try {
            $products = Product::where('shop_id', $shopId)
                               ->with(['category', 'variants.stock'])
                               ->where('is_active', true)
                               ->orderBy('created_at', 'desc')
                               ->paginate(15);

            return response()->json([
                'success' => true,
                'products' => $products
            ]);

        } catch (\Exception $e) {
            Log::error('Error in byShop method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération des produits'
            ], 500);
        }
    }

    /**
     * Produits par catégorie
     */
    public function byCategory($categoryId)
    {
        try {
            $products = Product::where('category_id', $categoryId)
                               ->with(['shop', 'variants.stock'])
                               ->where('is_active', true)
                               ->orderBy('created_at', 'desc')
                               ->paginate(15);

            return response()->json([
                'success' => true,
                'products' => $products
            ]);

        } catch (\Exception $e) {
            Log::error('Error in byCategory method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération des produits'
            ], 500);
        }
    }

    /**
     * Produits en promotion
     */
    public function promotions(Request $request)
    {
        try {
            $products = Product::where('in_promotion', true)
                               ->where('promotion_start', '<=', now())
                               ->where('promotion_end', '>=', now())
                               ->with(['shop', 'category', 'variants.stock'])
                               ->leftJoin('shops', 'products.shop_id', '=', 'shops.id')
                               ->orderBy('shops.certifiee', 'desc')
                               ->orderBy('products.created_at', 'desc')
                               ->select('products.*')
                               ->paginate($request->get('limit', 15));

            return response()->json([
                'success' => true,
                'products' => $products
            ]);

        } catch (\Exception $e) {
            Log::error('Error in promotions method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération des promotions'
            ], 500);
        }
    }

    /**
     * Mes produits (produits du vendeur connecté)
     */
    public function myProducts(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user->shop) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous n\'avez pas de boutique',
                    'products' => []
                ], 404);
            }

            $products = Product::where('shop_id', $user->shop->id)
                               ->with(['category', 'variants.stock'])
                               ->orderBy('created_at', 'desc')
                               ->paginate(15);

            return response()->json([
                'success' => true,
                'products' => $products
            ]);

        } catch (\Exception $e) {
            Log::error('Error in myProducts method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération de vos produits',
                'products' => []
            ], 500);
        }
    }

    /**
     * Activer une promotion
     */
    public function activatePromotion(Request $request, $id)
    {
        try {
            $user = $request->user();
            $product = Product::find($id);

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => 'Produit non trouvé'
                ], 404);
            }

            if ($product->shop->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autorisé'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'promotion_price' => 'required|numeric|min:0',
                'promotion_start' => 'required|date',
                'promotion_end' => 'required|date|after:promotion_start',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'errors' => $validator->errors()
                ], 422);
            }

            $percentage = 0;
            if ($product->price > 0) {
                $percentageValue = (1 - $request->promotion_price / $product->price) * 100;
                $percentage = (int) round($percentageValue);
            }

            $product->update([
                'in_promotion' => true,
                'promotion_price' => $request->promotion_price,
                'promotion_start' => Carbon::parse($request->promotion_start),
                'promotion_end' => Carbon::parse($request->promotion_end),
                'promotion_percentage' => $percentage,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Promotion activée',
                'product' => $product->fresh()
            ]);

        } catch (\Exception $e) {
            Log::error('Error in activatePromotion method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de l\'activation de la promotion'
            ], 500);
        }
    }

    /**
     * Désactiver une promotion
     */
    public function deactivatePromotion(Request $request, $id)
    {
        try {
            $user = $request->user();
            $product = Product::find($id);

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => 'Produit non trouvé'
                ], 404);
            }

            if ($product->shop->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autorisé'
                ], 403);
            }

            $product->update([
                'in_promotion' => false,
                'promotion_price' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'promotion_percentage' => null,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Promotion désactivée',
                'product' => $product->fresh()
            ]);

        } catch (\Exception $e) {
            Log::error('Error in deactivatePromotion method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la désactivation de la promotion'
            ], 500);
        }
    }

    /**
     * Variantes d'un produit
     */
    public function variants($productId)
    {
        try {
            $variants = ProductVariant::where('product_id', $productId)
                                      ->with('stock')
                                      ->where('is_active', true)
                                      ->get();

            return response()->json([
                'success' => true,
                'variants' => $variants
            ]);

        } catch (\Exception $e) {
            Log::error('Error in variants method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération des variantes'
            ], 500);
        }
    }

    /**
     * Ajouter une variante
     */
    public function addVariant(Request $request, $productId)
    {
        try {
            $user = $request->user();
            $product = Product::find($productId);

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'message' => 'Produit non trouvé'
                ], 404);
            }

            if ($product->shop->user_id !== $user->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Non autorisé'
                ], 403);
            }

            $validator = Validator::make($request->all(), [
                'size' => 'nullable|string|max:50',
                'color' => 'nullable|string|max:50',
                'material' => 'nullable|string|max:50',
                'price_adjustment' => 'nullable|numeric',
                'stock' => 'required|integer|min:0',
                'sku' => 'required|string|unique:product_variants,sku',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'errors' => $validator->errors()
                ], 422);
            }

            $variant = ProductVariant::create([
                'product_id' => $productId,
                'size' => $request->size,
                'color' => $request->color,
                'material' => $request->material,
                'price_adjustment' => $request->price_adjustment ?? 0,
                'sku' => $request->sku,
                'is_active' => true,
            ]);

            VariantStock::create([
                'product_variant_id' => $variant->id,
                'quantity' => $request->stock,
                'reserved_quantity' => 0,
                'low_stock_threshold' => 5,
                'low_stock_alert' => false,
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Variante ajoutée avec succès',
                'variant' => $variant->load('stock')
            ], 201);

        } catch (\Exception $e) {
            Log::error('Error in addVariant method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de l\'ajout de la variante'
            ], 500);
        }
    }

   
    /**
     * Produits similaires
     */
    public function getSimilar(Request $request, $productId)
    {
        try {
            $product = Product::find($productId);

            if (!$product) {
                return response()->json([
                    'success' => false,
                    'error' => 'Produit non trouvé'
                ], 404);
            }

            $limit = $request->get('limit', 10);

            $similarProducts = Product::with(['category', 'shop', 'variants.stock'])
                                      ->where('is_active', true)
                                      ->where('id', '!=', $productId)
                                      ->where('category_id', $product->category_id)
                                      ->orderBy('view_count', 'desc')
                                      ->limit($limit)
                                      ->get();

            return response()->json([
                'success' => true,
                'similar_products' => $similarProducts,
                'original_product' => $product,
                'limit' => $limit,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getSimilar method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération des produits similaires'
            ], 500);
        }
    }

    /**
     * Produits tendance par intérêts
     */
    public function getTrendingByInterests(Request $request)
    {
        try {
            $limit = $request->get('limit', 15);
            $user = $request->user();

            $query = Product::with(['category', 'shop', 'variants.stock'])
                            ->where('is_active', true);

            // ✅ Utilisation correcte de UserInterest
            if ($user) {
                $interestIds = UserInterest::where('user_id', $user->id)
                                          ->where('is_active', true)
                                          ->pluck('category_id')
                                          ->toArray();
                
                if (!empty($interestIds)) {
                    $query->whereIn('category_id', $interestIds);
                }
            }

            $products = $query->orderBy('view_count', 'desc')
                              ->orderBy('sales_count', 'desc')
                              ->limit($limit)
                              ->get();

            return response()->json([
                'success' => true,
                'trending_products' => $products,
                'limit' => $limit,
                'has_interests' => $user ? !empty($interestIds) : false,
            ]);

        } catch (\Exception $e) {
            Log::error('Error in getTrendingByInterests: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json([
                'success' => false,
                'message' => 'Une erreur est survenue lors de la récupération des produits tendance'
            ], 500);
        }
    }
    /**
 * Produits recommandés (page d'accueil) - Version améliorée avec UserHabitTracker
 */
public function getRecommended(Request $request)
{
    try {
        $limit = $request->get('limit', 20);
        $user = $request->user();

        $query = Product::with(['category', 'shop', 'variants.stock'])
                        ->where('is_active', true);

        // 🔥 PRIORITÉ 1: Recommandations basées sur les habitudes (UserHabitTracker)
        if ($user) {
            $habitBasedProducts = UserHabitTracker::getRecommendedProducts($user->id, $limit, 30);
            
            if ($habitBasedProducts->isNotEmpty()) {
                return response()->json([
                    'success' => true,
                    'recommended_products' => $habitBasedProducts,
                    'recommendation_type' => 'personalized_by_habits'
                ]);
            }
        }

        // 🔥 PRIORITÉ 2: Filtrer par intérêts (UserInterest)
        if ($user && $user->hasInterests()) {
            $interestIds = $user->getInterestIds();
            if (!empty($interestIds)) {
                $query->whereIn('category_id', $interestIds);
            }
        }

        // 🔥 PRIORITÉ 3: Produits populaires par défaut
        $products = $query->orderBy('view_count', 'desc')
                          ->orderBy('sales_count', 'desc')
                          ->limit($limit)
                          ->get();

        return response()->json([
            'success' => true,
            'recommended_products' => $products,
            'recommendation_type' => $user ? 'personalized_by_interests' : 'popular'
        ]);

    } catch (\Exception $e) {
        Log::error('Error in getRecommended method: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
        return response()->json([
            'success' => false,
            'message' => 'Une erreur est survenue lors de la récupération des recommandations'
        ], 500);
    }
}
}