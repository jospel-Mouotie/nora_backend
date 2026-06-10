<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Shop;
use App\Models\ShopFollower;
use App\Models\ShopLike;
use App\Traits\ApiResponse;
use App\Traits\AuthorizesRoles;

class ShopFollowController extends Controller
{
    use ApiResponse, AuthorizesRoles;

    /**
     * S'abonner à une boutique
     */
    public function follow(Request $request, $shopId)
    {
        $shop = Shop::active()->find($shopId);
        
        if (!$shop) {
            return $this->notFoundResponse('Boutique');
        }

        $existingFollower = ShopFollower::where('user_id', $request->user()->id)
                                      ->where('shop_id', $shopId)
                                      ->first();

        if ($existingFollower) {
            return $this->errorResponse('Vous êtes déjà abonné à cette boutique', 422);
        }

        ShopFollower::create([
            'user_id' => $request->user()->id,
            'shop_id' => $shopId,
        ]);

        $shop->followers_count = ShopFollower::where('shop_id', $shopId)->count();
        $shop->save();

        return $this->successResponse(
            ['followers_count' => $shop->followers_count],
            'Abonnement réussi'
        );
    }

    /**
     * Se désabonner d'une boutique
     */
    public function unfollow(Request $request, $shopId)
    {
        $shop = Shop::active()->find($shopId);
        
        if (!$shop) {
            return $this->notFoundResponse('Boutique');
        }

        $follower = ShopFollower::where('user_id', $request->user()->id)
                              ->where('shop_id', $shopId)
                              ->first();

        if (!$follower) {
            return $this->errorResponse('Vous n\'êtes pas abonné à cette boutique', 422);
        }

        $follower->delete();

        $shop->followers_count = ShopFollower::where('shop_id', $shopId)->count();
        $shop->save();

        return $this->successResponse(
            ['followers_count' => $shop->followers_count],
            'Désabonnement réussi'
        );
    }

    /**
     * Liker une boutique
     */
    public function like(Request $request, $shopId)
    {
        $shop = Shop::active()->find($shopId);
        
        if (!$shop) {
            return $this->notFoundResponse('Boutique');
        }

        $existingLike = ShopLike::where('user_id', $request->user()->id)
                               ->where('shop_id', $shopId)
                               ->first();

        if ($existingLike) {
            return $this->errorResponse('Vous avez déjà liké cette boutique', 422);
        }

        ShopLike::create([
            'user_id' => $request->user()->id,
            'shop_id' => $shopId,
        ]);

        return $this->successResponse([], 'Like ajouté');
    }

    /**
     * Retirer son like d'une boutique
     */
    public function unlike(Request $request, $shopId)
    {
        $shop = Shop::active()->find($shopId);
        
        if (!$shop) {
            return $this->notFoundResponse('Boutique');
        }

        $like = ShopLike::where('user_id', $request->user()->id)
                       ->where('shop_id', $shopId)
                       ->first();

        if (!$like) {
            return $this->errorResponse('Vous n\'avez pas liké cette boutique', 422);
        }

        $like->delete();

        return $this->successResponse([], 'Like retiré');
    }

    /**
     * Lister les boutiques suivies par l'utilisateur
     */
    public function myFollowedShops(Request $request)
    {
        $followedShops = $request->user()
            ->followedShops()
            ->with('shop')
            ->get()
            ->pluck('shop');

        return response()->json($followedShops);
    }

    /**
     * Lister les abonnés d'une boutique (admin ou propriétaire)
     */
    public function followers(Request $request, $shopId)
    {
        $shop = Shop::find($shopId);
        
        if (!$shop) {
            return $this->notFoundResponse('Boutique');
        }

        if ($error = $this->authorizeOwnerOrAdmin($request, $shop->user_id)) {
            return $error;
        }

        $followers = ShopFollower::where('shop_id', $shopId)
                               ->with('user')
                               ->get();

        return response()->json($followers);
    }

    /**
     * Vérifier si l'utilisateur est abonné à une boutique
     */
    public function isFollowing(Request $request, $shopId)
    {
        $isFollowing = ShopFollower::where('user_id', $request->user()->id)
                                 ->where('shop_id', $shopId)
                                 ->exists();

        return response()->json(['is_following' => $isFollowing]);
    }

    /**
     * Vérifier si l'utilisateur a liké une boutique
     */
    public function hasLiked(Request $request, $shopId)
    {
        $hasLiked = ShopLike::where('user_id', $request->user()->id)
                           ->where('shop_id', $shopId)
                           ->exists();

        return response()->json(['has_liked' => $hasLiked]);
    }
}
