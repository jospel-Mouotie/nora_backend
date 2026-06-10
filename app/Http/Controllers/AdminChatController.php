<?php

namespace App\Http\Controllers;

use App\Models\AdminChat;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class AdminChatController extends Controller
{
    /**
     * Obtenir les conversations de chat admin
     */
    public function index(Request $request): JsonResponse
    {
        $query = AdminChat::with(['user', 'admin']);

        // Filtres
        if ($request->user_id) {
            $query->forUser($request->user_id);
        }

        if ($request->admin_id) {
            $query->forAdmin($request->admin_id);
        }

        if ($request->unread_only) {
            $query->unread();
        }

        if ($request->sender_type) {
            if ($request->sender_type === 'user') {
                $query->fromUser();
            } else {
                $query->fromAdmin();
            }
        }

        $messages = $query->orderBy('created_at', 'desc')
            ->paginate($request->limit ?? 50);

        return response()->json(['messages' => $messages]);
    }

    /**
     * Obtenir la conversation avec un utilisateur spécifique
     */
    public function getConversation($userId, Request $request): JsonResponse
    {
        $user = User::findOrFail($userId);
        
        $query = AdminChat::where('user_id', $userId)
            ->with(['user', 'admin']);

        $messages = $query->orderBy('created_at', 'desc')
            ->paginate($request->limit ?? 50);

        // Marquer les messages non lus comme lus
        if (auth()->user()->isAdmin()) {
            AdminChat::where('user_id', $userId)
                ->fromUser()
                ->unread()
                ->update([
                    'is_read' => true,
                    'read_at' => now(),
                    'admin_id' => auth()->id(),
                ]);
        }

        return response()->json([
            'messages' => $messages,
            'user' => $user,
        ]);
    }

    /**
     * Envoyer un message
     */
    public function sendMessage(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required_without:conversation_id|exists:users,id',
            'content' => 'required_without:attachment|string|max:2000',
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,gif,pdf,doc,docx|max:5120', // 5MB
            'type' => 'nullable|in:text,image,file',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $data = [
                'user_id' => $request->user_id,
                'content' => $request->content ?? '',
                'type' => $request->type ?? 'text',
                'sender_type' => auth()->user()->isAdmin() ? 'admin' : 'user',
                'is_read' => false,
            ];

            // Déterminer l'admin_id si c'est un message d'admin
            if (auth()->user()->isAdmin()) {
                $data['admin_id'] = auth()->id();
            }

            // Upload de l'attachment
            if ($request->hasFile('attachment')) {
                $attachment = $request->file('attachment');
                $path = $attachment->store('admin-chat-attachments', 'public');
                $data['attachment_path'] = $path;
                $data['type'] = $this->getFileType($attachment->getClientOriginalExtension());
            }

            $message = AdminChat::create($data);

            // Créer une notification système si nécessaire
            if (auth()->user()->isAdmin()) {
                // Notifier l'utilisateur
                $this->createSystemMessage(
                    $request->user_id,
                    "Nouveau message de l'administrateur",
                    'system'
                );
            }

            return response()->json([
                'message' => 'Message envoyé',
                'chat_message' => $message->load(['user', 'admin']),
            ], 201);

        } catch (\Exception $e) {
            \Log::error($e->getMessage(), ['exception' => $e]);
            return response()->json(['error' => 'Une erreur interne est survenue'], 500);
        }
    }

    /**
     * Marquer les messages comme lus
     */
    public function markAsRead(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'message_ids' => 'required|array',
            'message_ids.*' => 'exists:admin_chats,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $updated = AdminChat::whereIn('id', $request->message_ids)
                ->where('is_read', false)
                ->update([
                    'is_read' => true,
                    'read_at' => now(),
                    'admin_id' => auth()->id(),
                ]);

            return response()->json([
                'message' => 'Messages marqués comme lus',
                'updated_count' => $updated,
            ]);

        } catch (\Exception $e) {
            \Log::error($e->getMessage(), ['exception' => $e]);
            return response()->json(['error' => 'Une erreur interne est survenue'], 500);
        }
    }

    /**
     * Marquer tous les messages d'un utilisateur comme lus
     */
    public function markAllAsRead($userId): JsonResponse
    {
        try {
            $updated = AdminChat::where('user_id', $userId)
                ->fromUser()
                ->unread()
                ->update([
                    'is_read' => true,
                    'read_at' => now(),
                    'admin_id' => auth()->id(),
                ]);

            return response()->json([
                'message' => 'Tous les messages marqués comme lus',
                'updated_count' => $updated,
            ]);

        } catch (\Exception $e) {
            \Log::error($e->getMessage(), ['exception' => $e]);
            return response()->json(['error' => 'Une erreur interne est survenue'], 500);
        }
    }

    /**
     * Obtenir le nombre de messages non lus
     */
    public function getUnreadCount(Request $request): JsonResponse
    {
        $userId = $request->user_id ?? auth()->id();
        
        $count = AdminChat::where('user_id', $userId)
            ->unread()
            ->fromUser()
            ->count();

        return response()->json(['unread_count' => $count]);
    }

    /**
     * Obtenir les conversations récentes
     */
    public function getRecentConversations(Request $request): JsonResponse
    {
        $query = AdminChat::select('user_id')
            ->selectRaw('MAX(created_at) as last_message_at')
            ->selectRaw('COUNT(*) as message_count')
            ->selectRaw('SUM(CASE WHEN is_read = false AND sender_type = "user" THEN 1 ELSE 0 END) as unread_count')
            ->groupBy('user_id')
            ->orderBy('last_message_at', 'desc');

        if (auth()->user()->isAdmin()) {
            // Admin peut voir toutes les conversations
            $conversations = $query->limit($request->limit ?? 20)->get();
        } else {
            // Utilisateur ne voit que sa conversation
            $conversations = $query->where('user_id', auth()->id())->get();
        }

        // Charger les utilisateurs
        $userIds = $conversations->pluck('user_id');
        $users = User::whereIn('id', $userIds)->get()->keyBy('id');

        $result = $conversations->map(function ($conv) use ($users) {
            $user = $users->get($conv->user_id);
            return [
                'user' => $user,
                'last_message_at' => $conv->last_message_at,
                'message_count' => $conv->message_count,
                'unread_count' => $conv->unread_count,
            ];
        });

        return response()->json(['conversations' => $result]);
    }

    /**
     * Supprimer un message
     */
    public function deleteMessage($id): JsonResponse
    {
        $message = AdminChat::findOrFail($id);

        // Vérifier les permissions
        if (!auth()->user()->isAdmin() && $message->user_id !== auth()->id()) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        try {
            // Supprimer l'attachment si existe
            if ($message->attachment_path) {
                Storage::disk('public')->delete($message->attachment_path);
            }

            $message->delete();

            return response()->json(['message' => 'Message supprimé']);

        } catch (\Exception $e) {
            \Log::error($e->getMessage(), ['exception' => $e]);
            return response()->json(['error' => 'Une erreur interne est survenue'], 500);
        }
    }

    /**
     * Obtenir les statistiques du chat (admin)
     */
    public function getStats(): JsonResponse
    {
        $this->authorize('manage-admin-chat');

        $stats = [
            'total_messages' => AdminChat::count(),
            'total_users' => AdminChat::distinct('user_id')->count('user_id'),
            'unread_messages' => AdminChat::unread()->fromUser()->count(),
            'messages_today' => AdminChat::whereDate('created_at', today())->count(),
            'active_conversations' => AdminChat::where('created_at', '>=', now()->subDays(7))
                ->distinct('user_id')
                ->count('user_id'),
            'top_users' => User::withCount(['adminChats' => function ($q) {
                $q->where('created_at', '>=', now()->subDays(30));
            }])
            ->orderBy('admin_chats_count', 'desc')
            ->limit(10)
            ->get(),
        ];

        return response()->json(['stats' => $stats]);
    }

    /**
     * Créer un message système
     */
    private function createSystemMessage($userId, $content, $type = 'system')
    {
        AdminChat::create([
            'user_id' => $userId,
            'content' => $content,
            'type' => $type,
            'sender_type' => 'admin',
            'is_read' => true,
            'admin_id' => auth()->id(),
        ]);
    }

    /**
     * Déterminer le type de fichier
     */
    private function getFileType($extension)
    {
        $imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        $documentExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf'];

        $extension = strtolower($extension);

        if (in_array($extension, $imageExtensions)) {
            return 'image';
        } elseif (in_array($extension, $documentExtensions)) {
            return 'file';
        }

        return 'file';
    }

    /**
     * Transférer une conversation à un autre admin
     */
    public function transferConversation(Request $request, $userId): JsonResponse
    {
        $this->authorize('manage-admin-chat');

        $validator = Validator::make($request->all(), [
            'admin_id' => 'required|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $updated = AdminChat::where('user_id', $userId)
                ->whereNull('admin_id')
                ->update(['admin_id' => $request->admin_id]);

            // Créer un message système
            $this->createSystemMessage(
                $userId,
                "Conversation transférée à l'administrateur",
                'system'
            );

            return response()->json([
                'message' => 'Conversation transférée',
                'updated_count' => $updated,
            ]);

        } catch (\Exception $e) {
            \Log::error($e->getMessage(), ['exception' => $e]);
            return response()->json(['error' => 'Une erreur interne est survenue'], 500);
        }
    }

    /**
     * Obtenir les messages non lus pour l'admin
     */
    public function getAdminUnreadMessages(): JsonResponse
    {
        $this->authorize('manage-admin-chat');

        $messages = AdminChat::unread()
            ->fromUser()
            ->with(['user'])
            ->orderBy('created_at', 'desc')
            ->limit(50)
            ->get();

        return response()->json(['unread_messages' => $messages]);
    }
}
