<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderQrCode;
use App\Models\Cart;
use App\Models\CartItem;
use App\Models\ProductVariant;
use App\Traits\ApiResponse;
use App\Traits\AuthorizesRoles;

class OrderController extends Controller
{
    use ApiResponse, AuthorizesRoles;

    /**
     * Créer une commande à partir du panier
     */
    public function createFromCart(Request $request)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'delivery_address' => 'required|string|min:10',
            'notes' => 'nullable|string',
            'use_mb_coins' => 'nullable|boolean',
            'mb_coins_amount' => 'nullable|numeric|min:1',
        ])) {
            return $error;
        }

        $user = $request->user();
        $cart = $user->cart()->active()->with('items.productVariant.stock')->first();

        if (!$cart || $cart->items->isEmpty()) {
            return $this->errorResponse('Panier vide', 422);
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
                    return $this->errorResponse('Solde MB Coins insuffisant', 422);
                }
                if ($request->mb_coins_amount > $finalAmount) {
                    return $this->errorResponse('Le montant en MB Coins ne peut pas dépasser le total', 422);
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

            return $this->createdResponse(
                ['order' => $order->load(['items.productVariant.product', 'shop'])],
                'Commande créée avec succès'
            );

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->serverErrorResponse('Erreur lors de la création de la commande');
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
            return $this->notFoundResponse('Commande');
        }

        // Vérifier que l'utilisateur est le propriétaire ou admin
        if ($error = $this->authorizeOwnerOrAdmin(request(), $order->user_id)) {
            return $error;
        }

        return response()->json($order);
    }

    /**
     * Confirmer une commande (admin uniquement)
     */
    public function confirm(Request $request, $id)
    {
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
        }

        $order = Order::find($id);
        if (!$order) {
            return $this->notFoundResponse('Commande');
        }

        $order->confirm();

        return $this->successResponse(
            ['order' => $order->fresh()],
            'Commande confirmée'
        );
    }

    /**
     * Marquer comme en préparation (boutique uniquement)
     */
    public function startPreparing(Request $request, $id)
    {
        $order = Order::with('shop')->find($id);
        if (!$order) {
            return $this->notFoundResponse('Commande');
        }

        // Vérifier que l'utilisateur est le propriétaire de la boutique
        if ($order->shop->user_id !== $request->user()->id) {
            return $this->unauthorizedResponse();
        }

        $order->startPreparing();

        return $this->successResponse(
            ['order' => $order->fresh()],
            'Commande en préparation'
        );
    }

    /**
     * Marquer comme prête (boutique uniquement)
     */
    public function markAsReady(Request $request, $id)
    {
        $order = Order::with('shop')->find($id);
        if (!$order) {
            return $this->notFoundResponse('Commande');
        }

        if ($order->shop->user_id !== $request->user()->id) {
            return $this->unauthorizedResponse();
        }

        $order->markAsReady();

        return $this->successResponse(
            ['order' => $order->fresh()],
            'Commande prête'
        );
    }

    /**
     * Marquer comme livrée (livreur uniquement)
     */
    public function markAsDelivered(Request $request, $id)
    {
        $order = Order::find($id);
        if (!$order) {
            return $this->notFoundResponse('Commande');
        }

        if ($error = $this->authorizeRoles($request, ['livreur', 'admin'])) {
            return $error;
        }

        $order->markAsDelivered();

        return $this->successResponse(
            ['order' => $order->fresh()],
            'Commande livrée'
        );
    }

    /**
     * Annuler une commande
     */
    public function cancel(Request $request, $id)
    {
        $order = Order::find($id);
        if (!$order) {
            return $this->notFoundResponse('Commande');
        }

        if ($error = $this->authorizeOwnerOrAdmin($request, $order->user_id)) {
            return $error;
        }

        if ($order->isDelivered()) {
            return $this->errorResponse('Impossible d\'annuler une commande livrée', 422);
        }

        $order->cancel();

        // Libérer le stock
        foreach ($order->items as $item) {
            if ($item->productVariant && $item->productVariant->stock) {
                $item->productVariant->releaseStock($item->quantity);
            }
        }

        return $this->successResponse(
            ['order' => $order->fresh()],
            'Commande annulée'
        );
    }

    /**
     * Mettre à jour le statut d'une commande (méthode générique)
     */
    public function updateStatus(Request $request, $id)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'status' => 'required|in:pending,confirmed,preparing,ready,in_delivery,delivered,cancelled',
        ])) {
            return $error;
        }

        $order = Order::with('shop')->find($id);
        if (!$order) {
            return $this->notFoundResponse('Commande');
        }

        $newStatus = $request->status;
        $user = $request->user();

        // Vérifier les autorisations selon le statut
        switch ($newStatus) {
            case 'confirmed':
                if ($user->role !== 'admin') {
                    return $this->unauthorizedResponse();
                }
                $order->confirm();
                break;
            case 'preparing':
            case 'ready':
                if (!$order->shop || $order->shop->user_id !== $user->id) {
                    return $this->unauthorizedResponse();
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
                    return $this->unauthorizedResponse();
                }
                if ($newStatus === 'delivered') {
                    $order->markAsDelivered();
                } else {
                    $order->update(['status' => 'in_delivery']);
                }
                break;
            case 'cancelled':
                if ($order->user_id !== $user->id && $user->role !== 'admin') {
                    return $this->unauthorizedResponse();
                }
                if ($order->isDelivered()) {
                    return $this->errorResponse('Impossible d\'annuler une commande livrée', 422);
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

        return $this->successResponse(
            ['order' => $order->fresh()],
            'Statut mis à jour'
        );
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
            return $this->notFoundResponse('PIN invalide');
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
            return $this->errorResponse('QR code invalide ou expiré', 404);
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
            return $this->notFoundResponse('QR code');
        }

        $qrCode->markAsUsed();

        return $this->successResponse(
            ['qr_code' => $qrCode->fresh()],
            'QR code utilisé'
        );
    }

    /**
     * Lister les commandes d'une boutique (propriétaire boutique)
     */
    public function byShop(Request $request)
    {
        $user = $request->user();
        
        if (!$user->shop) {
            return $this->notFoundResponse('Boutique');
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
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
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
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
        }

        if ($error = $this->validateRequestData($request->all(), [
            'shop_id' => 'required|exists:shops,id',
        ])) {
            return $error;
        }

        $order = Order::findOrFail($id);
        $order->shop_id = $request->shop_id;
        $order->status = 'pending'; // Commande envoyée à la boutique
        $order->save();

        return $this->successResponse(
            ['order' => $order->load(['items.productVariant.product', 'user', 'shop'])],
            'Commande assignée à la boutique'
        );
    }

    /**
     * Envoyer une commande à la boutique concernée (admin uniquement)
     */
    public function sendToShop(Request $request, $id)
    {
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
        }

        $order = Order::with('shop')->findOrFail($id);
        
        if ($order->status !== 'pending_admin') {
            return $this->errorResponse('Cette commande n\'est pas en attente', 400);
        }

        $order->status = 'pending';
        $order->save();

        return $this->successResponse(
            ['order' => $order->load(['items.productVariant.product', 'user', 'shop'])],
            'Commande envoyée à la boutique'
        );
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
