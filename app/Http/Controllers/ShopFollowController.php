<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Shop;
use App\Models\ShopFollower;
use App\Models\ShopLike;

class ShopFollowController extends Controller
{
    /**
     * S'abonner à une boutique
     */
    public function follow(Request $request, $shopId)
    {
        $shop = Shop::active()->find($shopId);
        
        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        // Vérifier si l'utilisateur est déjà abonné
        $existingFollower = ShopFollower::where('user_id', $request->user()->id)
                                      ->where('shop_id', $shopId)
                                      ->first();

        if ($existingFollower) {
            return response()->json(['message' => 'Vous êtes déjà abonné à cette boutique'], 422);
        }

        // Créer l'abonnement
        ShopFollower::create([
            'user_id' => $request->user()->id,
            'shop_id' => $shopId,
        ]);

        // Mettre à jour le compteur d'abonnés de la boutique
        $shop->followers_count = ShopFollower::where('shop_id', $shopId)->count();
        $shop->save();

        return response()->json(['message' => 'Abonnement réussi', 'followers_count' => $shop->followers_count]);
    }

    /**
     * Se désabonner d'une boutique
     */
    public function unfollow(Request $request, $shopId)
    {
        $shop = Shop::active()->find($shopId);
        
        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        $follower = ShopFollower::where('user_id', $request->user()->id)
                              ->where('shop_id', $shopId)
                              ->first();

        if (!$follower) {
            return response()->json(['message' => 'Vous n\'êtes pas abonné à cette boutique'], 422);
        }

        $follower->delete();

        // Mettre à jour le compteur d'abonnés de la boutique
        $shop->followers_count = ShopFollower::where('shop_id', $shopId)->count();
        $shop->save();

        return response()->json(['message' => 'Désabonnement réussi', 'followers_count' => $shop->followers_count]);
    }

    /**
     * Liker une boutique
     */
    public function like(Request $request, $shopId)
    {
        $shop = Shop::active()->find($shopId);
        
        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        // Vérifier si l'utilisateur a déjà liké
        $existingLike = ShopLike::where('user_id', $request->user()->id)
                               ->where('shop_id', $shopId)
                               ->first();

        if ($existingLike) {
            return response()->json(['message' => 'Vous avez déjà liké cette boutique'], 422);
        }

        // Créer le like
        ShopLike::create([
            'user_id' => $request->user()->id,
            'shop_id' => $shopId,
        ]);

        return response()->json(['message' => 'Like ajouté']);
    }

    /**
     * Retirer son like d'une boutique
     */
    public function unlike(Request $request, $shopId)
    {
        $shop = Shop::active()->find($shopId);
        
        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        $like = ShopLike::where('user_id', $request->user()->id)
                       ->where('shop_id', $shopId)
                       ->first();

        if (!$like) {
            return response()->json(['message' => 'Vous n\'avez pas liké cette boutique'], 422);
        }

        $like->delete();

        return response()->json(['message' => 'Like retiré']);
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
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        // Vérifier que l'utilisateur est admin ou propriétaire de la boutique
        if ($request->user()->role !== 'admin' && $shop->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Non autorisé'], 403);
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
