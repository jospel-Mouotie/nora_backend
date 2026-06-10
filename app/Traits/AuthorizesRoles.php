<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

trait AuthorizesRoles
{
    /**
     * Abort with 403 if the authenticated user does not have the admin role.
     * Returns null when authorized, or a JsonResponse to return early.
     */
    protected function authorizeAdmin(Request $request): ?JsonResponse
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        return null;
    }

    /**
     * Abort with 403 unless the authenticated user owns the resource or is admin.
     *
     * @param int $ownerId  The user_id that owns the resource.
     */
    protected function authorizeOwnerOrAdmin(Request $request, int $ownerId): ?JsonResponse
    {
        if ($ownerId !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        return null;
    }

    /**
     * Abort with 403 if the authenticated user does not have one of the given roles.
     *
     * @param string[] $roles
     */
    protected function authorizeRoles(Request $request, array $roles): ?JsonResponse
    {
        if (!in_array($request->user()->role, $roles)) {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        return null;
    }
}
