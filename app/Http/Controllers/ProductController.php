<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
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

        return response()->json($products);
    }

    /**
     * Créer un nouveau produit (propriétaire boutique uniquement)
     */
    public function store(Request $request)
    {
        $user = $request->user();

        // Permettre aux clients de créer une boutique automatiquement s'ils n'en ont pas
        if (!$user->shop) {
            // Créer automatiquement une boutique pour le client
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
        }

        if (!$user->shop->is_active) {
            return response()->json(['message' => 'Votre boutique n\'est pas active'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'price' => 'required|numeric|min:0',
            'sku' => 'required|string|unique:products',
            'category_id' => 'required|exists:categories,id',
            'stock' => 'required|integer|min:0',
            'images' => 'nullable|array',
            'variants' => 'nullable|array',
            'variants.*.size' => 'nullable|string|max:50',
            'variants.*.color' => 'nullable|string|max:50',
            'variants.*.material' => 'nullable|string|max:50',
            'variants.*.price_adjustment' => 'nullable|numeric',
            'variants.*.stock' => 'required|integer|min:0',
            'variants.*.sku' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();
        $data['shop_id'] = $user->shop->id;

        // Vérifier si images est un tableau
        $imagesJson = null;
        if ($request->has('images') && $request->images !== null) {
            $images = $request->images;
            if (is_array($images)) {
                $imagesJson = json_encode($images);
            }
        }

        // Créer le produit
        $product = Product::create([
            'name' => $data['name'],
            'description' => $data['description'],
            'price' => $data['price'],
            'sku' => $data['sku'],
            'stock' => $data['stock'],
            'category_id' => $data['category_id'],
            'shop_id' => $data['shop_id'],
            'images' => $imagesJson,
            'is_active' => true,
        ]);

        // Créer les variantes si présentes
        if ($request->has('variants') && is_array($request->variants)) {
            foreach ($request->variants as $variantData) {
                ProductVariant::create([
                    'product_id' => $product->id,
                    'size' => $variantData['size'] ?? null,
                    'color' => $variantData['color'] ?? null,
                    'material' => $variantData['material'] ?? null,
                    'sku' => $variantData['sku'],
                    'price_adjustment' => $variantData['price_adjustment'] ?? 0,
                    'stock' => $variantData['stock'],
                    'is_active' => true,
                ]);
            }
        }

        return response()->json([
            'message' => 'Produit créé avec succès',
            'product' => $product->load(['variants'])
        ], 201);
    }

    /**
     * Mettre à jour un produit
     */
    public function update(Request $request, $id)
    {
        $user = $request->user();
        $product = Product::find($id);

        if (!$product) {
            return response()->json(['message' => 'Produit non trouvé'], 404);
        }

        if ($product->shop->user_id !== $user->id && $user->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|string|max:255',
            'description' => 'sometimes|string',
            'price' => 'sometimes|numeric|min:0',
            'stock' => 'sometimes|integer|min:0',
            'category_id' => 'sometimes|exists:categories,id',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $updateData = [];
        if ($request->has('name')) $updateData['name'] = $request->name;
        if ($request->has('description')) $updateData['description'] = $request->description;
        if ($request->has('price')) $updateData['price'] = $request->price;
        if ($request->has('stock')) $updateData['stock'] = $request->stock;
        if ($request->has('category_id')) $updateData['category_id'] = $request->category_id;
        if ($request->has('is_active')) $updateData['is_active'] = $request->is_active;

        $product->update($updateData);

        return response()->json([
            'message' => 'Produit mis à jour avec succès',
            'product' => $product->fresh()
        ]);
    }

    /**
     * Supprimer un produit
     */
    public function destroy(Request $request, $id)
    {
        $user = $request->user();
        $product = Product::find($id);

        if (!$product) {
            return response()->json(['message' => 'Produit non trouvé'], 404);
        }

        if ($product->shop->user_id !== $user->id && $user->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $product->delete();

        return response()->json(['message' => 'Produit supprimé avec succès']);
    }

    /**
     * Afficher un produit
     */
    public function show($id)
    {
        $product = Product::with(['category', 'variants', 'shop'])
                           ->find($id);

        if (!$product) {
            return response()->json(['message' => 'Produit non trouvé'], 404);
        }

        return response()->json($product);
    }

    /**
     * Produits par boutique
     */
    public function byShop($shopId)
    {
        $products = Product::where('shop_id', $shopId)
                           ->with(['category', 'variants'])
                           ->where('is_active', true)
                           ->orderBy('created_at', 'desc')
                           ->paginate(15);

        return response()->json($products);
    }

    /**
     * Produits par catégorie
     */
    public function byCategory($categoryId)
    {
        $products = Product::where('category_id', $categoryId)
                           ->with(['shop', 'variants'])
                           ->where('is_active', true)
                           ->orderBy('created_at', 'desc')
                           ->paginate(15);

        return response()->json($products);
    }

    /**
     * Produits en promotion
     */
    public function promotions()
    {
        $products = Product::where('in_promotion', true)
                           ->where('promotion_start', '<=', now())
                           ->where('promotion_end', '>=', now())
                           ->with(['shop', 'category'])
                           ->leftJoin('shops', 'products.shop_id', '=', 'shops.id')
                           ->orderBy('shops.certifiee', 'desc')
                           ->orderBy('products.created_at', 'desc')
                           ->select('products.*')
                           ->paginate(15);

        return response()->json($products);
    }

    /**
     * Mes produits
     */
    public function myProducts(Request $request)
    {
        $user = $request->user();

        if (!$user->shop) {
            return response()->json(['message' => 'Vous n\'avez pas de boutique'], 404);
        }

        $products = Product::where('shop_id', $user->shop->id)
                           ->with(['category', 'variants'])
                           ->orderBy('created_at', 'desc')
                           ->paginate(15);

        return response()->json($products);
    }

    /**
     * Activer une promotion
     */
    public function activatePromotion(Request $request, $id)
    {
        $user = $request->user();
        $product = Product::find($id);

        if (!$product) {
            return response()->json(['message' => 'Produit non trouvé'], 404);
        }

        if ($product->shop->user_id !== $user->id) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $validator = Validator::make($request->all(), [
            'promotion_price' => 'required|numeric|min:0',
            'promotion_start' => 'required|date',
            'promotion_end' => 'required|date|after:promotion_start',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Calculer le pourcentage de réduction
        $percentage = 0;
        if ($product->price > 0) {
            $percentageValue = (1 - $request->promotion_price / $product->price) * 100;
            $percentage = (int) round($percentageValue);
        }

        $product->update([
            'in_promotion' => true,
            'promotion_price' => $request->promotion_price,
            'promotion_start' => $request->promotion_start,
            'promotion_end' => $request->promotion_end,
            'promotion_percentage' => $percentage,
        ]);

        return response()->json([
            'message' => 'Promotion activée',
            'product' => $product->fresh()
        ]);
    }

    /**
     * Désactiver une promotion
     */
    public function deactivatePromotion(Request $request, $id)
    {
        $user = $request->user();
        $product = Product::find($id);

        if (!$product) {
            return response()->json(['message' => 'Produit non trouvé'], 404);
        }

        if ($product->shop->user_id !== $user->id) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $product->update([
            'in_promotion' => false,
            'promotion_price' => null,
            'promotion_start' => null,
            'promotion_end' => null,
            'promotion_percentage' => null,
        ]);

        return response()->json([
            'message' => 'Promotion désactivée',
            'product' => $product->fresh()
        ]);
    }

    /**
     * Variantes d'un produit
     */
    public function variants($productId)
    {
        $variants = ProductVariant::where('product_id', $productId)
                                  ->where('is_active', true)
                                  ->get();

        return response()->json($variants);
    }

    /**
     * Ajouter une variante
     */
    public function addVariant(Request $request, $productId)
    {
        $user = $request->user();
        $product = Product::find($productId);

        if (!$product) {
            return response()->json(['message' => 'Produit non trouvé'], 404);
        }

        if ($product->shop->user_id !== $user->id) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $validator = Validator::make($request->all(), [
            'size' => 'nullable|string|max:50',
            'color' => 'nullable|string|max:50',
            'material' => 'nullable|string|max:50',
            'price_adjustment' => 'nullable|numeric',
            'stock' => 'required|integer|min:0',
            'sku' => 'required|string|unique:product_variants',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $variant = ProductVariant::create([
            'product_id' => $productId,
            'size' => $request->size,
            'color' => $request->color,
            'material' => $request->material,
            'price_adjustment' => $request->price_adjustment ?? 0,
            'stock' => $request->stock,
            'sku' => $request->sku,
            'is_active' => true,
        ]);

        return response()->json([
            'message' => 'Variante ajoutée',
            'variant' => $variant
        ], 201);
    }

    /**
     * Produits recommandés (page d'accueil)
     */
    public function getRecommended(Request $request)
    {
        $limit = $request->get('limit', 20);

        $products = Product::with(['category', 'shop'])
                           ->where('is_active', true)
                           ->orderBy('view_count', 'desc')
                           ->orderBy('sales_count', 'desc')
                           ->limit($limit)
                           ->get();

        return response()->json([
            'recommended_products' => $products,
            'recommendation_type' => 'popular'
        ]);
    }

    /**
     * Produits similaires
     */
    public function getSimilar(Request $request, $productId)
    {
        $product = Product::find($productId);

        if (!$product) {
            return response()->json(['error' => 'Produit non trouvé'], 404);
        }

        $limit = $request->get('limit', 10);

        $similarProducts = Product::with(['category', 'shop'])
                                  ->where('is_active', true)
                                  ->where('id', '!=', $productId)
                                  ->where('category_id', $product->category_id)
                                  ->orderBy('view_count', 'desc')
                                  ->limit($limit)
                                  ->get();

        return response()->json([
            'similar_products' => $similarProducts,
            'original_product' => $product,
            'limit' => $limit,
        ]);
    }

    /**
     * Produits tendance par intérêts
     */
    public function getTrendingByInterests(Request $request)
    {
        $limit = $request->get('limit', 15);

        $products = Product::with(['category', 'shop'])
                           ->where('is_active', true)
                           ->orderBy('view_count', 'desc')
                           ->orderBy('sales_count', 'desc')
                           ->limit($limit)
                           ->get();

        return response()->json([
            'trending_products' => $products,
            'limit' => $limit,
        ]);
    }
}
