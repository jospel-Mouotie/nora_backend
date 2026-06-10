<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderQrCode;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\ProductVariant;

class OrderController extends Controller
{
    /**
     * Créer une commande à partir du panier
     */
    public function createFromCart(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'delivery_address' => 'required|string|min:10',
            'notes' => 'nullable|string',
            'use_mb_coins' => 'nullable|boolean',
            'mb_coins_amount' => 'nullable|numeric|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = $request->user();
        $cart = $user->cart()->active()->with('items.productVariant.stock')->first();

        if (!$cart || $cart->items->isEmpty()) {
            return response()->json(['message' => 'Panier vide'], 422);
        }

        $validationResult = $this->validateCartItems($cart->items);
        if (!$validationResult['valid']) {
            return response()->json([
                'message' => 'Panier invalide',
                'invalid_items' => $validationResult['invalid_items']
            ], 422);
        }

        DB::beginTransaction();

        try {
            $finalAmount = $cart->total_amount - $cart->promotion_discount;
            $mbCoinsUsed = 0;

            if ($request->use_mb_coins && $request->mb_coins_amount) {
                $mbCoin = \App\Models\MBCoin::where('user_id', $user->id)->first();
                if (!$mbCoin || $mbCoin->balance < $request->mb_coins_amount) {
                    return response()->json(['message' => 'Solde MB Coins insuffisant'], 422);
                }
                if ($request->mb_coins_amount > $finalAmount) {
                    return response()->json(['message' => 'Le montant en MB Coins ne peut pas dépasser le total'], 422);
                }
                $mbCoin->spend($request->mb_coins_amount, 'Paiement commande hybride');
                $mbCoinsUsed = $request->mb_coins_amount;
                $finalAmount -= $mbCoinsUsed;
            }

            $order = Order::create([
                'order_number' => Order::generateOrderNumber(),
                'total_amount' => $cart->total_amount,
                'promotion_discount' => $cart->promotion_discount,
                'delivery_fee' => 0,
                'final_amount' => $finalAmount,
                'pin' => Order::generatePin(),
                'qr_code' => Order::generateQrCode(),
                'status' => 'pending_admin',
                'payment_status' => $finalAmount == 0 ? 'paid' : 'pending',
                'delivery_address' => $request->delivery_address,
                'notes' => $request->notes,
                'user_id' => $user->id,
                'shop_id' => $cart->items->first()->productVariant->product->shop_id,
            ]);

            // Créer les articles de commande
            foreach ($cart->items as $cartItem) {
                OrderItem::create([
                    'quantity' => $cartItem->quantity,
                    'unit_price' => $cartItem->unit_price,
                    'total_price' => $cartItem->total_price,
                    'promotion_discount' => $cartItem->promotion_discount,
                    'order_id' => $order->id,
                    'product_variant_id' => $cartItem->product_variant_id,
                ]);

                // Confirmer la réduction de stock
                $cartItem->productVariant->confirmStockReduction($cartItem->quantity);
            }

            // Créer le QR code
            OrderQrCode::create([
                'qr_code' => $order->qr_code,
                'expires_at' => now()->addHours(24), // Expire après 24h
                'order_id' => $order->id,
            ]);

            // Vider le panier
            $cart->items()->delete();
            $cart->update(['status' => 'abandoned']);

            DB::commit();

            return response()->json([
                'message' => 'Commande créée avec succès',
                'order' => $order->load(['items.productVariant.product', 'shop'])
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Erreur lors de la création de la commande',
                'error' => 'Une erreur interne est survenue'
            ], 500);
        }
    }

    /**
     * Lister les commandes de l'utilisateur
     */
    public function index(Request $request)
    {
        $orders = Order::with(['items.productVariant.product', 'shop', 'delivery'])
                           ->byUser($request->user()->id)
                           ->orderBy('created_at', 'desc')
                           ->paginate($request->get('per_page', 15));

        return response()->json($orders);
    }

    /**
     * Afficher une commande
     */
    public function show($id)
    {
        $order = Order::with(['items.productVariant.product', 'shop', 'user', 'delivery.tracking'])
                           ->find($id);

        if (!$order) {
            return response()->json(['message' => 'Commande non trouvée'], 404);
        }

        // Vérifier que l'utilisateur est le propriétaire ou admin
        if ($order->user_id !== auth()->id() && auth()->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        return response()->json($order);
    }

    /**
     * Confirmer une commande (admin uniquement)
     */
    public function confirm(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $order = Order::find($id);
        if (!$order) {
            return response()->json(['message' => 'Commande non trouvée'], 404);
        }

        $order->confirm();

        // Notifier la boutique
        // Ici on pourrait implémenter un système de notification

        return response()->json([
            'message' => 'Commande confirmée',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Marquer comme en préparation (boutique uniquement)
     */
    public function startPreparing(Request $request, $id)
    {
        $order = Order::with('shop')->find($id);
        if (!$order) {
            return response()->json(['message' => 'Commande non trouvée'], 404);
        }

        // Vérifier que l'utilisateur est le propriétaire de la boutique
        if ($order->shop->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $order->startPreparing();

        return response()->json([
            'message' => 'Commande en préparation',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Marquer comme prête (boutique uniquement)
     */
    public function markAsReady(Request $request, $id)
    {
        $order = Order::with('shop')->find($id);
        if (!$order) {
            return response()->json(['message' => 'Commande non trouvée'], 404);
        }

        if ($order->shop->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $order->markAsReady();

        return response()->json([
            'message' => 'Commande prête',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Marquer comme livrée (livreur uniquement)
     */
    public function markAsDelivered(Request $request, $id)
    {
        $order = Order::find($id);
        if (!$order) {
            return response()->json(['message' => 'Commande non trouvée'], 404);
        }

        // Vérifier que l'utilisateur est un livreur ou admin
        if (!in_array($request->user()->role, ['livreur', 'admin'])) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $order->markAsDelivered();

        return response()->json([
            'message' => 'Commande livrée',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Annuler une commande
     */
    public function cancel(Request $request, $id)
    {
        $order = Order::find($id);
        if (!$order) {
            return response()->json(['message' => 'Commande non trouvée'], 404);
        }

        // Vérifier que l'utilisateur est le propriétaire ou admin
        if ($order->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        if ($order->isDelivered()) {
            return response()->json(['message' => 'Impossible d\'annuler une commande livrée'], 422);
        }

        $order->cancel();

        // Libérer le stock
        foreach ($order->items as $item) {
            if ($item->productVariant && $item->productVariant->stock) {
                $item->productVariant->releaseStock($item->quantity);
            }
        }

        return response()->json([
            'message' => 'Commande annulée',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Mettre à jour le statut d'une commande (méthode générique)
     */
    public function updateStatus(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'status' => 'required|in:pending,confirmed,preparing,ready,in_delivery,delivered,cancelled',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $order = Order::with('shop')->find($id);
        if (!$order) {
            return response()->json(['message' => 'Commande non trouvée'], 404);
        }

        $newStatus = $request->status;
        $user = $request->user();

        // Vérifier les autorisations selon le statut
        switch ($newStatus) {
            case 'confirmed':
                if ($user->role !== 'admin') {
                    return response()->json(['message' => 'Non autorisé'], 403);
                }
                $order->confirm();
                break;
            case 'preparing':
            case 'ready':
                if (!$order->shop || $order->shop->user_id !== $user->id) {
                    return response()->json(['message' => 'Non autorisé'], 403);
                }
                if ($newStatus === 'preparing') {
                    $order->startPreparing();
                } else {
                    $order->markAsReady();
                }
                break;
            case 'in_delivery':
            case 'delivered':
                if (!in_array($user->role, ['livreur', 'admin'])) {
                    return response()->json(['message' => 'Non autorisé'], 403);
                }
                if ($newStatus === 'delivered') {
                    $order->markAsDelivered();
                } else {
                    $order->update(['status' => 'in_delivery']);
                }
                break;
            case 'cancelled':
                if ($order->user_id !== $user->id && $user->role !== 'admin') {
                    return response()->json(['message' => 'Non autorisé'], 403);
                }
                if ($order->isDelivered()) {
                    return response()->json(['message' => 'Impossible d\'annuler une commande livrée'], 422);
                }
                $order->cancel();
                // Libérer le stock
                foreach ($order->items as $item) {
                    if ($item->productVariant && $item->productVariant->stock) {
                        $item->productVariant->releaseStock($item->quantity);
                    }
                }
                break;
            default:
                $order->update(['status' => $newStatus]);
        }

        return response()->json([
            'message' => 'Statut mis à jour',
            'order' => $order->fresh()
        ]);
    }

    /**
     * Vérifier un PIN
     */
    public function verifyPin(Request $request, $pin)
    {
        $order = Order::with(['items.productVariant.product', 'user'])
                           ->where('pin', $pin)
                           ->first();

        if (!$order) {
            return response()->json(['message' => 'PIN invalide'], 404);
        }

        return response()->json([
            'valid' => true,
            'order' => $order
        ]);
    }

    /**
     * Vérifier un QR code
     */
    public function verifyQrCode(Request $request, $qrCode)
    {
        $qrCode = OrderQrCode::with(['order.items.productVariant.product', 'order.user'])
                                  ->where('qr_code', $qrCode)
                                  ->first();

        if (!$qrCode || !$qrCode->isValid()) {
            return response()->json(['message' => 'QR code invalide ou expiré'], 404);
        }

        return response()->json([
            'valid' => true,
            'order' => $qrCode->order
        ]);
    }

    /**
     * Marquer un QR code comme utilisé
     */
    public function useQrCode(Request $request, $qrCode)
    {
        $qrCode = OrderQrCode::with('order')->where('qr_code', $qrCode)->first();
        
        if (!$qrCode) {
            return response()->json(['message' => 'QR code non trouvé'], 404);
        }

        $qrCode->markAsUsed();

        return response()->json([
            'message' => 'QR code utilisé',
            'qr_code' => $qrCode->fresh()
        ]);
    }

    /**
     * Lister les commandes d'une boutique (propriétaire boutique)
     */
    public function byShop(Request $request)
    {
        $user = $request->user();
        
        if (!$user->shop) {
            return response()->json(['message' => 'Vous n\'avez pas de boutique'], 404);
        }

        $orders = Order::with(['items.productVariant.product', 'user', 'delivery'])
                           ->byShop($user->shop->id)
                           ->orderBy('created_at', 'desc')
                           ->paginate($request->get('per_page', 15));

        return response()->json($orders);
    }

    /**
     * Lister les commandes en attente (admin uniquement)
     */
    public function pendingOrders(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $orders = Order::with(['items.productVariant.product', 'user', 'shop'])
                           ->where('status', 'pending_admin')
                           ->orderBy('created_at', 'desc')
                           ->paginate($request->get('per_page', 15));

        return response()->json($orders);
    }

    /**
     * Assigner une commande à une boutique (admin uniquement)
     */
    public function assignToShop(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
            'shop_id' => 'required|exists:shops,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $order = Order::findOrFail($id);
        $order->shop_id = $request->shop_id;
        $order->status = 'pending'; // Commande envoyée à la boutique
        $order->save();

        return response()->json([
            'message' => 'Commande assignée à la boutique',
            'order' => $order->load(['items.productVariant.product', 'user', 'shop'])
        ]);
    }

    /**
     * Envoyer une commande à la boutique concernée (admin uniquement)
     */
    public function sendToShop(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $order = Order::with('shop')->findOrFail($id);
        
        if ($order->status !== 'pending_admin') {
            return response()->json(['message' => 'Cette commande n\'est pas en attente'], 400);
        }

        // La commande est déjà assignée à une boutique lors de la création
        // On change juste le statut pour l'envoyer à la boutique
        $order->status = 'pending';
        $order->save();

        return response()->json([
            'message' => 'Commande envoyée à la boutique',
            'order' => $order->load(['items.productVariant.product', 'user', 'shop'])
        ]);
    }

    /**
     * Valider les articles du panier
     */
    private function validateCartItems($cartItems)
    {
        $invalidItems = [];
        $isValid = true;

        foreach ($cartItems as $item) {
            if (!$item->isQuantityAvailable()) {
                $invalidItems[] = [
                    'item_id' => $item->id,
                    'product_name' => $item->productVariant->product->name ?? 'Inconnu',
                    'variant' => $item->productVariant->getFullName(),
                    'requested_quantity' => $item->quantity,
                    'available_quantity' => $item->getAvailableStock()
                ];
                $isValid = false;
            }
        }

        return [
            'valid' => $isValid,
            'invalid_items' => $invalidItems
        ];
    }
}
