<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\Product;
use App\Models\ProductVariant;

class CartController extends Controller
{
    /**
     * Obtenir le panier de l'utilisateur
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $cart = Cart::where('user_id', $user->id)
                    ->where('status', 'active')
                    ->first();

        if (!$cart) {
            return response()->json([
                'items' => [],
                'total_amount' => 0,
                'item_count' => 0
            ]);
        }

        // Récupérer les articles du panier
        $cartItems = DB::table('cart_items')
            ->join('product_variants', 'cart_items.product_variant_id', '=', 'product_variants.id')
            ->join('products', 'product_variants.product_id', '=', 'products.id')
            ->where('cart_items.cart_id', $cart->id)
            ->select(
                'cart_items.id',
                'cart_items.quantity',
                'cart_items.unit_price',
                'cart_items.total_price',
                'products.id as product_id',
                'products.name as product_name',
                'products.price',
                'products.images',
                'product_variants.id as variant_id',
                'product_variants.size',
                'product_variants.color',
                'product_variants.material',
                'product_variants.price_adjustment'
            )
            ->get();

        $total = $cartItems->sum('total_price');

        return response()->json([
            'items' => $cartItems,
            'total_amount' => $total,
            'item_count' => $cartItems->count()
        ]);
    }

/**
 * Ajouter un article au panier
 */
public function addItem(Request $request)
{
    // Lire le JSON correctement
    $input = $request->json()->all();
    
    if (empty($input)) {
        $input = $request->all();
    }

    // Validation accepte product_id OU variant_id
    $validator = Validator::make($input, [
        'variant_id' => 'required_without:product_id|exists:product_variants,id',
        'product_id' => 'required_without:variant_id|exists:products,id',
        'quantity' => 'required|integer|min:1',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'message' => 'Données invalides',
            'errors' => $validator->errors()
        ], 422);
    }

    $user = $request->user();
    $quantity = (int) $input['quantity'];
    
    // Récupérer le produit et la variante
    $product = null;
    $variant = null;
    
    if (isset($input['variant_id']) && $input['variant_id']) {
        // Cas 1: On a reçu un variant_id
        $variant = ProductVariant::with(['product', 'stock'])->find($input['variant_id']);
        if ($variant) {
            $product = $variant->product;
        }
    } elseif (isset($input['product_id']) && $input['product_id']) {
        // Cas 2: On a reçu un product_id, trouver ou créer une variante par défaut
        $product = Product::find($input['product_id']);
        
        if ($product) {
            // Chercher une variante existante pour ce produit
            $variant = ProductVariant::where('product_id', $product->id)->first();
            
            if (!$variant) {
                // Créer une variante par défaut
                $variant = ProductVariant::create([
                    'product_id' => $product->id,
                    'sku' => 'PROD-' . $product->id . '-DEFAULT',
                    'price_adjustment' => 0,
                    'is_active' => 1
                ]);
                
                // Créer le stock pour cette variante
                \App\Models\VariantStock::create([
                    'product_variant_id' => $variant->id,
                    'quantity' => 100,
                    'reserved_quantity' => 0,
                    'low_stock_threshold' => 5,
                    'low_stock_alert' => 0
                ]);
            }
        }
    }

    if (!$product || !$product->is_active) {
        return response()->json([
            'success' => false,
            'message' => 'Produit non disponible'
        ], 404);
    }

    // Vérifier le stock
    $stock = 0;
    if ($variant && $variant->stock) {
        $stock = $variant->stock->quantity;
    } else {
        $stock = 100; // Stock par défaut
    }

    if ($stock < $quantity) {
        return response()->json([
            'success' => false,
            'message' => 'Stock insuffisant',
            'available_stock' => $stock,
            'product_name' => $product->name
        ], 422);
    }

    // Obtenir ou créer le panier
    $cart = Cart::where('user_id', $user->id)
                ->where('status', 'active')
                ->first();
    
    if (!$cart) {
        $cart = Cart::create([
            'user_id' => $user->id,
            'status' => 'active',
            'total_amount' => 0
        ]);
    }

    // Vérifier si l'article existe déjà
    $existingItem = CartItem::where('cart_id', $cart->id)
                              ->where('product_variant_id', $variant->id)
                              ->first();

    $unitPrice = floatval($product->price);
    if ($variant && $variant->price_adjustment) {
        $unitPrice += floatval($variant->price_adjustment);
    }
    $totalPrice = $unitPrice * $quantity;

    if ($existingItem) {
        $newQuantity = $existingItem->quantity + $quantity;
        $newTotalPrice = $unitPrice * $newQuantity;
        $existingItem->update([
            'quantity' => $newQuantity,
            'total_price' => $newTotalPrice
        ]);
    } else {
        CartItem::create([
            'cart_id' => $cart->id,
            'product_variant_id' => $variant->id,
            'quantity' => $quantity,
            'unit_price' => $unitPrice,
            'total_price' => $totalPrice,
            'promotion_discount' => 0
        ]);
    }

    // Mettre à jour le total du panier
    $this->updateCartTotal($cart);

    return response()->json([
        'success' => true,
        'message' => 'Produit ajouté au panier avec succès',
        'cart_id' => $cart->id,
        'total_amount' => $cart->total_amount,
        'item_count' => $cart->items->count()
    ]);
}

    /**
     * Mettre à jour la quantité d'un article
     */
    public function updateItem(Request $request, $itemId)
    {
        $input = $request->json()->all();
        if (empty($input)) {
            $input = $request->all();
        }

        $validator = Validator::make($input, [
            'quantity' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = $request->user();
        $quantity = (int) $input['quantity'];

        $cartItem = CartItem::find($itemId);
        if (!$cartItem) {
            return response()->json(['message' => 'Article non trouvé'], 404);
        }

        $cart = Cart::where('id', $cartItem->cart_id)->where('user_id', $user->id)->first();
        if (!$cart) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        // Récupérer le prix unitaire
        $variant = ProductVariant::find($cartItem->product_variant_id);
        if (!$variant) {
            return response()->json(['message' => 'Variante du produit non trouvée'], 404);
        }

        $product = Product::find($variant->product_id);
        if (!$product) {
            return response()->json(['message' => 'Produit non trouvé'], 404);
        }

        $unitPrice = floatval($product->price) + floatval($variant->price_adjustment);
        $totalPrice = $unitPrice * $quantity;

        $cartItem->update([
            'quantity' => $quantity,
            'total_price' => $totalPrice
        ]);

        $this->updateCartTotal($cart);

        return response()->json([
            'message' => 'Quantité mise à jour avec succès',
            'cart' => $this->getCartData($cart)
        ]);
    }

    /**
     * Supprimer un article du panier
     */
    public function removeItem(Request $request, $itemId)
    {
        $user = $request->user();

        $cartItem = CartItem::find($itemId);
        if (!$cartItem) {
            return response()->json(['message' => 'Article non trouvé'], 404);
        }

        $cart = Cart::where('id', $cartItem->cart_id)->where('user_id', $user->id)->first();
        if (!$cart) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $cartItem->delete();
        $this->updateCartTotal($cart);

        return response()->json([
            'message' => 'Article supprimé avec succès',
            'cart' => $this->getCartData($cart)
        ]);
    }

    /**
     * Vider le panier
     */
    public function clear(Request $request)
    {
        $user = $request->user();

        $cart = Cart::where('user_id', $user->id)
                    ->where('status', 'active')
                    ->first();

        if ($cart) {
            CartItem::where('cart_id', $cart->id)->delete();
            $cart->update(['total_amount' => 0]);
        }

        return response()->json([
            'message' => 'Panier vidé avec succès',
            'cart' => ['items' => [], 'total_amount' => 0, 'item_count' => 0]
        ]);
    }

    /**
     * Mettre à jour le total du panier
     */
 /**
 * Mettre à jour le total du panier
 */
private function updateCartTotal($cart)
{
    $total = CartItem::where('cart_id', $cart->id)->sum('total_price');
    $cart->update(['total_amount' => $total]);
}

    /**
     * Obtenir les données formatées du panier
     */
    private function getCartData($cart)
    {
        $items = DB::table('cart_items')
            ->join('product_variants', 'cart_items.product_variant_id', '=', 'product_variants.id')
            ->join('products', 'product_variants.product_id', '=', 'products.id')
            ->where('cart_items.cart_id', $cart->id)
            ->select(
                'cart_items.id',
                'cart_items.quantity',
                'cart_items.unit_price',
                'cart_items.total_price',
                'products.id as product_id',
                'products.name as product_name',
                'products.price',
                'products.promotion_price',
                'products.in_promotion',
                'products.images',
                'product_variants.id as variant_id',
                'product_variants.size',
                'product_variants.color',
                'product_variants.material',
                'product_variants.price_adjustment'
            )
            ->get();

        return [
            'items' => $items,
            'total_amount' => $cart->total_amount,
            'item_count' => $items->count()
        ];
    }
}