<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CartApiController extends Controller
{
    public function add(Request $request)
    {
        try {
            $user = $request->user();
            $data = $request->json()->all();
            
            $productId = $data['product_id'] ?? null;
            $quantity = $data['quantity'] ?? 1;
            
            if (!$productId) {
                return response()->json(['success' => false, 'message' => 'product_id requis'], 400);
            }
            
            // Vérifier le produit
            $product = DB::table('products')->where('id', $productId)->first();
            if (!$product || !$product->is_active) {
                return response()->json(['success' => false, 'message' => 'Produit non trouvé'], 404);
            }
            
            // Chercher ou créer une variante pour ce produit
            $variant = DB::table('product_variants')
                ->where('product_id', $productId)
                ->first();
            
            if (!$variant) {
                // Créer une variante par défaut
                $variantId = DB::table('product_variants')->insertGetId([
                    'product_id' => $productId,
                    'sku' => 'PROD-' . $productId . '-DEFAULT',
                    'price_adjustment' => 0,
                    'is_active' => 1,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
                
                // Créer le stock
                DB::table('variant_stocks')->insert([
                    'product_variant_id' => $variantId,
                    'quantity' => 100,
                    'reserved_quantity' => 0,
                    'low_stock_threshold' => 5,
                    'low_stock_alert' => 0,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
            } else {
                $variantId = $variant->id;
            }
            
            // Créer ou récupérer le panier
            $cart = DB::table('carts')
                ->where('user_id', $user->id)
                ->where('status', 'active')
                ->first();
            
            if (!$cart) {
                $cartId = DB::table('carts')->insertGetId([
                    'user_id' => $user->id,
                    'status' => 'active',
                    'total_amount' => 0,
                    'promotion_discount' => 0,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
            } else {
                $cartId = $cart->id;
            }
            
            // Ajouter l'article
            $existingItem = DB::table('cart_items')
                ->where('cart_id', $cartId)
                ->where('product_variant_id', $variantId)
                ->first();
            
            $unitPrice = floatval($product->price);
            $totalPrice = $unitPrice * $quantity;
            
            if ($existingItem) {
                $newQuantity = $existingItem->quantity + $quantity;
                $newTotalPrice = $unitPrice * $newQuantity;
                DB::table('cart_items')
                    ->where('id', $existingItem->id)
                    ->update([
                        'quantity' => $newQuantity,
                        'total_price' => $newTotalPrice,
                        'updated_at' => now()
                    ]);
            } else {
                DB::table('cart_items')->insert([
                    'cart_id' => $cartId,
                    'product_variant_id' => $variantId,
                    'quantity' => $quantity,
                    'unit_price' => $unitPrice,
                    'total_price' => $totalPrice,
                    'promotion_discount' => 0,
                    'created_at' => now(),
                    'updated_at' => now()
                ]);
            }
            
            // Recalculer le total
            $items = DB::table('cart_items')->where('cart_id', $cartId)->get();
            $total = $items->sum('total_price');
            
            DB::table('carts')->where('id', $cartId)->update([
                'total_amount' => $total,
                'updated_at' => now()
            ]);
            
            return response()->json([
                'success' => true,
                'message' => 'Produit ajouté au panier',
                'cart_id' => $cartId,
                'total_amount' => $total,
                'item_count' => $items->count()
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Une erreur interne est survenue',
                'line' => $e->getLine(),
                'file' => basename($e->getFile())
            ], 500);
        }
    }
    
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            
            $cart = DB::table('carts')
                ->where('user_id', $user->id)
                ->where('status', 'active')
                ->first();
            
            if (!$cart) {
                return response()->json([
                    'success' => true,
                    'data' => ['items' => [], 'total_amount' => 0, 'item_count' => 0]
                ]);
            }
            
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
                    'products.images',
                    'product_variants.id as variant_id'
                )
                ->get();
            
            return response()->json([
                'success' => true,
                'data' => [
                    'items' => $items,
                    'total_amount' => floatval($cart->total_amount),
                    'item_count' => $items->count()
                ]
            ]);
            
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Une erreur interne est survenue'], 500);
        }
    }
    
    public function remove(Request $request, $itemId)
    {
        try {
            $user = $request->user();
            
            $item = DB::table('cart_items')->where('id', $itemId)->first();
            if (!$item) {
                return response()->json(['success' => false, 'message' => 'Article non trouvé'], 404);
            }
            
            $cart = DB::table('carts')->where('id', $item->cart_id)->first();
            if ($cart->user_id != $user->id) {
                return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
            }
            
            DB::table('cart_items')->where('id', $itemId)->delete();
            
            // Recalculer le total
            $items = DB::table('cart_items')->where('cart_id', $cart->id)->get();
            $total = $items->sum('total_price');
            
            DB::table('carts')->where('id', $cart->id)->update([
                'total_amount' => $total,
                'updated_at' => now()
            ]);
            
            return response()->json(['success' => true, 'message' => 'Article supprimé']);
            
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Une erreur interne est survenue'], 500);
        }
    }
    
    public function clear(Request $request)
    {
        try {
            $user = $request->user();
            
            $cart = DB::table('carts')
                ->where('user_id', $user->id)
                ->where('status', 'active')
                ->first();
            
            if ($cart) {
                DB::table('cart_items')->where('cart_id', $cart->id)->delete();
                DB::table('carts')->where('id', $cart->id)->update(['total_amount' => 0]);
            }
            
            return response()->json(['success' => true, 'message' => 'Panier vidé']);
            
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => 'Une erreur interne est survenue'], 500);
        }
    }
    
    public function count(Request $request)
    {
        try {
            $user = $request->user();
            $cart = DB::table('carts')->where('user_id', $user->id)->where('status', 'active')->first();
            $count = $cart ? DB::table('cart_items')->where('cart_id', $cart->id)->count() : 0;
            return response()->json(['success' => true, 'count' => $count]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'count' => 0], 500);
        }
    }
}