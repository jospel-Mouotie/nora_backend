<?php

namespace App\Http\Controllers;

use App\Models\InternalNotification;
use Illuminate\Http\Request;

class InternalNotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = InternalNotification::where('user_id', auth()->id())
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json(['notifications' => $notifications]);
    }

    public function unreadCount()
    {
        $count = InternalNotification::where('user_id', auth()->id())
            ->whereNull('read_at')
            ->count();

        return response()->json(['count' => $count]);
    }

    public function markAsRead($id)
    {
        $notification = InternalNotification::where('user_id', auth()->id())->findOrFail($id);
        $notification->update(['read_at' => now()]);

        return response()->json(['message' => 'Marked as read']);
    }

    public function markAllAsRead()
    {
        InternalNotification::where('user_id', auth()->id())
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['message' => 'All marked as read']);
    }
}
