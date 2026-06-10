<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\OrderChat;
use Illuminate\Support\Facades\Auth;
use App\Traits\ApiResponse;

class AdminOrderChatController extends Controller
{
    use ApiResponse;

    /**
     * Obtenir tous les messages de chat pour une commande entre admin et client
     */
    public function getClientMessages($orderId)
    {
        $user = Auth::user();
        $order = Order::with('user')->findOrFail($orderId);
        
        if ($user->role !== 'admin' && $order->user_id !== $user->id) {
            return $this->unauthorizedResponse();
        }

        $messages = OrderChat::where('order_id', $orderId)
            ->where('chat_type', 'admin_client')
            ->with('sender')
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json(['messages' => $messages]);
    }

    /**
     * Envoyer un message entre admin et client
     */
    public function sendClientMessage(Request $request, $orderId)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'message' => 'required|string',
        ])) {
            return $error;
        }

        $user = Auth::user();
        $order = Order::findOrFail($orderId);

        if ($user->role !== 'admin' && $order->user_id !== $user->id) {
            return $this->unauthorizedResponse();
        }

        $message = OrderChat::create([
            'order_id' => $orderId,
            'sender_id' => $user->id,
            'sender_type' => $user->role === 'admin' ? 'admin' : 'client',
            'message' => $request->message,
            'chat_type' => 'admin_client',
        ]);

        return response()->json(['message' => $message, 'success' => true]);
    }

    /**
     * Obtenir tous les messages de chat pour une commande entre admin et boutique
     */
    public function getShopMessages($orderId)
    {
        $user = Auth::user();
        $order = Order::with(['user', 'shop'])->findOrFail($orderId);
        
        if ($user->role !== 'admin' && (!$order->shop || $order->shop->user_id !== $user->id)) {
            return $this->unauthorizedResponse();
        }

        $messages = OrderChat::where('order_id', $orderId)
            ->where('chat_type', 'admin_shop')
            ->with('sender')
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json(['messages' => $messages]);
    }

    /**
     * Envoyer un message entre admin et boutique
     */
    public function sendShopMessage(Request $request, $orderId)
    {
        if ($error = $this->validateRequestData($request->all(), [
            'message' => 'required|string',
        ])) {
            return $error;
        }

        $user = Auth::user();
        $order = Order::with('shop')->findOrFail($orderId);

        if ($user->role !== 'admin' && (!$order->shop || $order->shop->user_id !== $user->id)) {
            return $this->unauthorizedResponse();
        }

        $message = OrderChat::create([
            'order_id' => $orderId,
            'sender_id' => $user->id,
            'sender_type' => $user->role === 'admin' ? 'admin' : 'shop',
            'message' => $request->message,
            'chat_type' => 'admin_shop',
        ]);

        return response()->json(['message' => $message, 'success' => true]);
    }

    /**
     * Marquer les messages comme lus
     */
    public function markAsRead(Request $request, $orderId)
    {
        $user = Auth::user();
        $chatType = $request->chat_type;

        $order = Order::findOrFail($orderId);

        if ($chatType === 'admin_client') {
            if ($user->role !== 'admin' && $order->user_id !== $user->id) {
                return $this->unauthorizedResponse();
            }
        } else if ($chatType === 'admin_shop') {
            if ($user->role !== 'admin' && (!$order->shop || $order->shop->user_id !== $user->id)) {
                return $this->unauthorizedResponse();
            }
        }

        OrderChat::where('order_id', $orderId)
            ->where('chat_type', $chatType)
            ->where('sender_id', '!=', $user->id)
            ->update(['is_read' => true]);

        return response()->json(['success' => true]);
    }

    /**
     * Obtenir le nombre de messages non lus
     */
    public function getUnreadCount(Request $request)
    {
        $user = Auth::user();
        $chatType = $request->chat_type;

        if ($user->role === 'admin') {
            $count = OrderChat::where('chat_type', $chatType)
                ->where('sender_type', '!=', 'admin')
                ->where('is_read', false)
                ->count();
        } else if ($user->role === 'client') {
            $count = OrderChat::where('chat_type', 'admin_client')
                ->where('sender_type', 'admin')
                ->where('is_read', false)
                ->whereHas('order', function($query) use ($user) {
                    $query->where('user_id', $user->id);
                })
                ->count();
        } else {
            $count = OrderChat::where('chat_type', 'admin_shop')
                ->where('sender_type', 'admin')
                ->where('is_read', false)
                ->whereHas('order', function($query) use ($user) {
                    $query->whereHas('shop', function($shopQuery) use ($user) {
                        $shopQuery->where('user_id', $user->id);
                    });
                })
                ->count();
        }

        return response()->json(['unread_count' => $count]);
    }

    /**
     * Obtenir la liste des conversations récentes
     */
    public function getRecentConversations(Request $request)
    {
        $user = Auth::user();
        $chatType = $request->chat_type;

        if ($user->role !== 'admin') {
            return $this->unauthorizedResponse();
        }

        $conversations = OrderChat::where('chat_type', $chatType)
            ->with(['order', 'order.user', 'order.shop'])
            ->orderBy('created_at', 'desc')
            ->get()
            ->groupBy('order_id')
            ->map(function ($group) {
                $latestMessage = $group->first();
                return [
                    'order_id' => $latestMessage->order_id,
                    'order' => $latestMessage->order,
                    'latest_message' => $latestMessage,
                    'unread_count' => $group->where('is_read', false)->count(),
                ];
            })
            ->values();

        return response()->json(['conversations' => $conversations]);
    }
}
