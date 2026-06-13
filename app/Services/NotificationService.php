<?php

namespace App\Services;

use App\Models\InternalNotification;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    private const FCM_API_URL = 'https://fcm.googleapis.com/fcm/send';

    /**
     * Créer une notification interne et envoyer une notification push FCM
     */
    public function sendNotification(
        $userId,
        string $type,
        string $title,
        string $message,
        array $data = []
    ): ?InternalNotification {
        try {
            // Créer la notification interne en BDD
            $notification = InternalNotification::create([
                'user_id' => $userId,
                'type' => $type,
                'title' => $title,
                'message' => $message,
                'data' => $data,
            ]);

            // Envoyer la notification push si token FCM disponible
            $user = User::find($userId);
            if ($user && $user->fcm_token) {
                $this->sendFcmNotification($user->fcm_token, $title, $message, $data);
            }

            return $notification;
        } catch (\Exception $e) {
            Log::error('Erreur création notification: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Envoyer une notification push à plusieurs utilisateurs
     */
    public function sendToMultiple(
        array $userIds,
        string $type,
        string $title,
        string $message,
        array $data = []
    ): int {
        $count = 0;
        foreach ($userIds as $userId) {
            if ($this->sendNotification($userId, $type, $title, $message, $data)) {
                $count++;
            }
        }
        return $count;
    }

    /**
     * Envoyer une notification à tous les admins
     */
    public function sendToAdmins(
        string $type,
        string $title,
        string $message,
        array $data = []
    ): int {
        $adminIds = User::where('role', 'admin')->pluck('id')->toArray();
        return $this->sendToMultiple($adminIds, $type, $title, $message, $data);
    }

    /**
     * Envoyer une notification FCM via HTTP
     */
    private function sendFcmNotification(
        string $fcmToken,
        string $title,
        string $body,
        array $data = []
    ): bool {
        $serverKey = env('FCM_SERVER_KEY');
        if (!$serverKey) {
            Log::warning('FCM_SERVER_KEY non configuré');
            return false;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type' => 'application/json',
            ])->post(self::FCM_API_URL, [
                'to' => $fcmToken,
                'notification' => [
                    'title' => $title,
                    'body' => $body,
                    'sound' => 'default',
                    'badge' => '1',
                ],
                'data' => $data,
                'priority' => 'high',
            ]);

            return $response->successful();
        } catch (\Exception $e) {
            Log::error('Erreur envoi FCM: ' . $e->getMessage());
            return false;
        }
    }

    // ==========================================
    // NOTIFICATIONS MÉTIER SPÉCIFIQUES
    // ==========================================

    public function notifyShopCreated(int $shopId, string $shopName): void
    {
        $this->sendToAdmins(
            'shop_created',
            'Nouvelle boutique créée',
            "La boutique \"$shopName\" attend votre validation.",
            ['shop_id' => $shopId, 'action' => 'shop_pending']
        );
    }

    public function notifyShopApproved(int $userId, string $shopName): void
    {
        $this->sendNotification(
            $userId,
            'shop_approved',
            'Boutique approuvée',
            "Votre boutique \"$shopName\" a été approuvée et est maintenant active!",
            ['action' => 'shop_details']
        );
    }

    public function notifyShopRejected(int $userId, string $shopName): void
    {
        $this->sendNotification(
            $userId,
            'shop_rejected',
            'Boutique refusée',
            "Votre boutique \"$shopName\" a été refusée. Contactez l'administration pour plus d'informations.",
            ['action' => 'shop_details']
        );
    }

    public function notifyCertificationRequested(int $shopId, string $shopName): void
    {
        $this->sendToAdmins(
            'certification_requested',
            'Demande de certification',
            "La boutique \"$shopName\" demande une certification.",
            ['shop_id' => $shopId, 'action' => 'certification_pending']
        );
    }

    public function notifyCertificationApproved(int $userId, string $shopName): void
    {
        $this->sendNotification(
            $userId,
            'certification_approved',
            'Certification approuvée',
            "Félicitations! Votre boutique \"$shopName\" est maintenant certifiée!",
            ['action' => 'shop_details']
        );
    }

    public function notifyCertificationRejected(int $userId, string $shopName): void
    {
        $this->sendNotification(
            $userId,
            'certification_rejected',
            'Certification refusée',
            "La certification de votre boutique \"$shopName\" a été refusée.",
            ['action' => 'shop_details']
        );
    }

    public function notifyOrderCreated(int $shopUserId, string $orderId, float $amount): void
    {
        $this->sendNotification(
            $shopUserId,
            'order_created',
            'Nouvelle commande',
            "Nouvelle commande #$orderId d'un montant de $amount FCFA.",
            ['order_id' => $orderId, 'action' => 'order_details']
        );
    }

    public function notifyOrderStatusChanged(int $customerId, string $orderId, string $status): void
    {
        $messages = [
            'confirmed' => "Votre commande #$orderId a été confirmée.",
            'preparing' => "Votre commande #$orderId est en cours de préparation.",
            'ready' => "Votre commande #$orderId est prête pour la livraison!",
            'picked_up' => "Votre commande #$orderId a été récupérée par le livreur.",
            'delivered' => "Votre commande #$orderId a été livrée avec succès!",
            'cancelled' => "Votre commande #$orderId a été annulée.",
        ];

        $message = $messages[$status] ?? "Le statut de votre commande #$orderId a changé.";

        $this->sendNotification(
            $customerId,
            'order_status_changed',
            'Commande #' . $orderId,
            $message,
            ['order_id' => $orderId, 'status' => $status, 'action' => 'order_details']
        );
    }

    public function notifyNewProduct(array $followerIds, string $shopName, string $productName): void
    {
        $this->sendToMultiple(
            $followerIds,
            'product_created',
            'Nouveau produit',
            "La boutique \"$shopName\" a ajouté un nouveau produit: $productName",
            ['action' => 'product_details']
        );
    }

    public function notifyAdminNewProduct(string $shopName, string $productName, int $productId): void
    {
        $this->sendToAdmins(
            'new_product_added',
            'Nouveau produit ajouté',
            "La boutique \"$shopName\" a ajouté un nouveau produit: $productName",
            ['product_id' => $productId, 'action' => 'admin_product_review']
        );
    }

    public function notifyNewVideo(array $followerIds, string $shopName, string $videoTitle): void
    {
        $this->sendToMultiple(
            $followerIds,
            'video_created',
            'Nouvelle vidéo',
            "La boutique \"$shopName\" a publié une nouvelle vidéo: $videoTitle",
            ['action' => 'video_details']
        );
    }

    public function notifyNewMessage(int $recipientId, string $senderName, string $messagePreview): void
    {
        $this->sendNotification(
            $recipientId,
            'message_received',
            'Nouveau message',
            "$senderName: $messagePreview",
            ['action' => 'open_chat']
        );
    }

    public function notifyVideoLiked(int $creatorId, string $likerName, string $videoTitle): void
    {
        $this->sendNotification(
            $creatorId,
            'video_liked',
            'Nouveau like',
            "$likerName a aimé votre vidéo \"$videoTitle\"",
            ['action' => 'video_details']
        );
    }

    public function notifyVideoComment(int $creatorId, string $commenterName, string $videoTitle): void
    {
        $this->sendNotification(
            $creatorId,
            'video_comment',
            'Nouveau commentaire',
            "$commenterName a commenté votre vidéo \"$videoTitle\"",
            ['action' => 'video_details']
        );
    }

    public function notifyLowStock(int $shopOwnerId, string $productName, int $stock): void
    {
        $this->sendNotification(
            $shopOwnerId,
            'low_stock',
            'Stock faible',
            "Le produit \"$productName\" a un stock faible ($stock unités restantes).",
            ['action' => 'product_details']
        );
    }

    public function notifyDeliveryAssigned(int $customerId, string $orderId, string $driverName): void
    {
        $this->sendNotification(
            $customerId,
            'delivery_assigned',
            'Livreur assigné',
            "Votre commande #$orderId sera livrée par $driverName.",
            ['order_id' => $orderId, 'action' => 'track_delivery']
        );
    }
}
