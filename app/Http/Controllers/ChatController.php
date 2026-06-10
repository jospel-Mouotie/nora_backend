<?php

namespace App\Http\Controllers;

use App\Models\Message;
use App\Models\Delivery;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class ChatController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Envoyer un message dans le chat de livraison
     */
    public function sendMessage(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'delivery_id' => 'required|exists:deliveries,id',
            'content' => 'required_without:attachment|string|max:1000',
            'type' => 'nullable|in:text,image,location,system',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,gif,mp4,mov,avi|max:10240', // 10MB max
            'sender_latitude' => 'nullable|numeric|between:-90,90',
            'sender_longitude' => 'nullable|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $delivery = Delivery::findOrFail($request->delivery_id);
        $sender = auth()->user();

        // Vérifier que l'utilisateur est autorisé à participer à ce chat
        if (!$this->canAccessChat($sender, $delivery)) {
            return response()->json(['error' => 'Accès non autorisé à ce chat'], 403);
        }

        // Déterminer le destinataire
        $receiver = $this->determineReceiver($sender, $delivery);

        // Gérer l'upload de fichier si présent
        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('chat-attachments', 'public');
        }

        $message = Message::create([
            'content' => $request->content,
            'type' => $request->type ?? 'text',
            'delivery_id' => $request->delivery_id,
            'sender_id' => $sender->id,
            'receiver_id' => $receiver->id,
            'attachment_path' => $attachmentPath,
            'sender_latitude' => $request->sender_latitude,
            'sender_longitude' => $request->sender_longitude,
        ]);

        // Créer une notification système si c'est un message de location
        if ($request->type === 'location' && $request->sender_latitude && $request->sender_longitude) {
            $this->createLocationSystemMessage($delivery, $sender, $request->sender_latitude, $request->sender_longitude);
        }

        return response()->json([
            'message' => 'Message envoyé avec succès',
            'data' => $message->load(['sender', 'receiver'])
        ], 201);
    }

    /**
     * Obtenir les messages d'une livraison
     */
    public function getMessages(Request $request, $deliveryId): JsonResponse
    {
        $delivery = Delivery::findOrFail($deliveryId);
        $user = auth()->user();

        // Vérifier l'accès au chat
        if (!$this->canAccessChat($user, $delivery)) {
            return response()->json(['error' => 'Accès non autorisé à ce chat'], 403);
        }

        $messages = Message::forDelivery($deliveryId)
            ->with(['sender', 'receiver'])
            ->orderBy('created_at', 'asc')
            ->paginate(50);

        // Marquer les messages comme lus pour l'utilisateur
        $this->markMessagesAsRead($user, $deliveryId);

        return response()->json([
            'messages' => $messages,
            'unread_count' => $this->getDeliveryUnreadCount($user, $deliveryId)
        ]);
    }

    /**
     * Marquer un message comme lu
     */
    public function markAsRead(Request $request, $messageId): JsonResponse
    {
        $message = Message::findOrFail($messageId);
        $user = auth()->user();

        // Vérifier que l'utilisateur est le destinataire
        if ($message->receiver_id !== $user->id) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $message->markAsRead();

        return response()->json([
            'message' => 'Message marqué comme lu',
            'data' => $message
        ]);
    }

    /**
     * Marquer tous les messages d'une livraison comme lus
     */
    public function markAllAsRead(Request $request, $deliveryId): JsonResponse
    {
        $delivery = Delivery::findOrFail($deliveryId);
        $user = auth()->user();

        if (!$this->canAccessChat($user, $delivery)) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $unreadMessages = Message::forDelivery($deliveryId)
            ->where('receiver_id', $user->id)
            ->unread()
            ->get();

        foreach ($unreadMessages as $message) {
            $message->markAsRead();
        }

        return response()->json([
            'message' => 'Tous les messages marqués comme lus',
            'count' => $unreadMessages->count()
        ]);
    }

    /**
     * Obtenir le nombre de messages non lus
     */
    public function getUnreadCount(Request $request): JsonResponse
    {
        $user = auth()->user();
        $unreadCount = Message::where('receiver_id', $user->id)
            ->unread()
            ->count();

        return response()->json(['unread_count' => $unreadCount]);
    }

    /**
     * Obtenir les chats récents de l'utilisateur
     */
    public function getRecentChats(Request $request): JsonResponse
    {
        $user = auth()->user();

        $chats = Message::where(function ($query) use ($user) {
            $query->where('sender_id', $user->id)
                  ->orWhere('receiver_id', $user->id);
        })
        ->with(['delivery', 'sender', 'receiver'])
        ->orderBy('created_at', 'desc')
        ->get()
        ->groupBy('delivery_id')
        ->map(function ($messages) {
            $latestMessage = $messages->first();
            $unreadCount = $messages->where('receiver_id', auth()->id())
                                   ->where('is_read', false)
                                   ->count();

            return [
                'delivery' => $latestMessage->delivery,
                'latest_message' => $latestMessage,
                'unread_count' => $unreadCount,
                'total_messages' => $messages->count(),
            ];
        })
        ->values()
        ->take(20);

        return response()->json(['chats' => $chats]);
    }

    /**
     * Supprimer un message
     */
    public function deleteMessage(Request $request, $messageId): JsonResponse
    {
        $message = Message::findOrFail($messageId);
        $user = auth()->user();

        // Seul l'expéditeur peut supprimer son message
        if ($message->sender_id !== $user->id) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        // Supprimer le fichier attaché s'il existe
        if ($message->attachment_path) {
            Storage::disk('public')->delete($message->attachment_path);
        }

        $message->delete();

        return response()->json(['message' => 'Message supprimé avec succès']);
    }

    /**
     * Envoyer un message de localisation
     */
    public function sendLocation(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'delivery_id' => 'required|exists:deliveries,id',
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'address' => 'nullable|string|max:500',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $delivery = Delivery::findOrFail($request->delivery_id);
        $sender = auth()->user();

        if (!$this->canAccessChat($sender, $delivery)) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $receiver = $this->determineReceiver($sender, $delivery);

        $message = Message::create([
            'content' => $request->address ?? "Position partagée",
            'type' => 'location',
            'delivery_id' => $request->delivery_id,
            'sender_id' => $sender->id,
            'receiver_id' => $receiver->id,
            'sender_latitude' => $request->latitude,
            'sender_longitude' => $request->longitude,
        ]);

        return response()->json([
            'message' => 'Position partagée avec succès',
            'data' => $message->load(['sender', 'receiver'])
        ], 201);
    }

    /**
     * Vérifier si un utilisateur peut accéder au chat d'une livraison
     */
    private function canAccessChat($user, $delivery): bool
    {
        // Le client de la commande
        if ($delivery->order && $delivery->order->user_id === $user->id) {
            return true;
        }

        // Le livreur assigné
        if ($delivery->delivery_person_id === $user->id) {
            return true;
        }

        // Admin
        if ($user->role === 'admin') {
            return true;
        }

        return false;
    }

    /**
     * Déterminer le destinataire du message
     */
    private function determineReceiver($sender, $delivery): User
    {
        // Si l'expéditeur est le client, le destinataire est le livreur
        if ($delivery->order && $delivery->order->user_id === $sender->id) {
            return User::findOrFail($delivery->delivery_person_id);
        }

        // Si l'expéditeur est le livreur, le destinataire est le client
        if ($delivery->delivery_person_id === $sender->id) {
            return User::findOrFail($delivery->order->user_id);
        }

        // Par défaut, retourner le client
        return $delivery->order->user;
    }

    /**
     * Marquer les messages comme lus pour un utilisateur
     */
    private function markMessagesAsRead($user, $deliveryId): void
    {
        Message::forDelivery($deliveryId)
            ->where('receiver_id', $user->id)
            ->unread()
            ->update([
                'is_read' => true,
                'read_at' => now(),
            ]);
    }

    /**
     * Obtenir le nombre de messages non lus pour une livraison
     */
    private function getDeliveryUnreadCount($user, $deliveryId): int
    {
        return Message::forDelivery($deliveryId)
            ->where('receiver_id', $user->id)
            ->unread()
            ->count();
    }

    /**
     * Créer un message système pour la localisation
     */
    private function createLocationSystemMessage($delivery, $sender, $latitude, $longitude): void
    {
        Message::create([
            'content' => "{$sender->name} a partagé sa position",
            'type' => 'system',
            'delivery_id' => $delivery->id,
            'sender_id' => null, // Message système
            'receiver_id' => null,
        ]);
    }
}
