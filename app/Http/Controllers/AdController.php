<?php

namespace App\Http\Controllers;

use App\Models\Ad;
use App\Models\AdCampaign;
use App\Models\Shop;
use App\Models\MBCoin;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

class AdController extends Controller
{
    /**
     * Obtenir toutes les publicités
     */
    public function index(Request $request): JsonResponse
    {
        $query = Ad::with(['shop', 'adCampaign']);

        // Filtres
        if ($request->shop_id) {
            $query->where('shop_id', $request->shop_id);
        }

        if ($request->campaign_id) {
            $query->where('ad_campaign_id', $request->campaign_id);
        }

        if ($request->type) {
            $query->byType($request->type);
        }

        if ($request->position) {
            $query->byPosition($request->position);
        }

        if ($request->status) {
            switch ($request->status) {
                case 'active':
                    $query->active();
                    break;
                case 'paused':
                    $query->paused();
                    break;
                case 'expired':
                    $query->expired();
                    break;
            }
        }

        $ads = $query->orderBy('created_at', 'desc')
            ->paginate($request->limit ?? 20);

        return response()->json(['ads' => $ads]);
    }

    /**
     * Obtenir les détails d'une publicité
     */
    public function show($id): JsonResponse
    {
        $ad = Ad::with(['shop', 'adCampaign'])->findOrFail($id);
        return response()->json(['ad' => $ad]);
    }

    /**
     * Créer une nouvelle publicité
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'shop_id' => 'required|exists:shops,id',
            'ad_campaign_id' => 'nullable|exists:ad_campaigns,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'image' => 'required|file|mimes:jpg,jpeg,png,gif|max:2048', // 2MB
            'link_url' => 'required|url|max:500',
            'type' => 'required|in:banner,video,carousel,popup',
            'position' => 'required|in:top,sidebar,bottom,popup,in_feed',
            'budget' => 'nullable|numeric|min:0|max:100000',
            'daily_budget' => 'nullable|numeric|min:0|max:10000',
            'cost_per_click' => 'nullable|numeric|min:0|max:100',
            'cost_per_impression' => 'nullable|numeric|min:0|max:10',
            'max_impressions' => 'nullable|integer|min:1|max:1000000',
            'max_clicks' => 'nullable|integer|min:1|max:100000',
            'starts_at' => 'nullable|date',
            'ends_at' => 'nullable|date|after:starts_at',
            'targeting' => 'nullable|array',
            'metadata' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $shop = Shop::findOrFail($request->shop_id);
            if (!$shop->certifiee) {
                return response()->json(['error' => 'Seules les boutiques certifiées peuvent créer des publicités.'], 403);
            }

            $data = $request->only([
                'shop_id', 'ad_campaign_id', 'title', 'description', 
                'link_url', 'type', 'position', 'budget', 'daily_budget',
                'cost_per_click', 'cost_per_impression', 'max_impressions', 
                'max_clicks', 'starts_at', 'ends_at', 'targeting', 'metadata'
            ]);

            // Upload de l'image
            if ($request->hasFile('image')) {
                $data['image'] = $request->file('image')->store('ad-images', 'public');
            }

            $ad = Ad::create($data);

            return response()->json([
                'message' => 'Publicité créée avec succès',
                'ad' => $ad->load(['shop', 'adCampaign']),
            ], 201);

        } catch (\Exception $e) {
            \Log::error('Error creating ad: ' . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de la création de la publicité'], 500);
        }
    }

    /**
     * Mettre à jour une publicité
     */
    public function update(Request $request, $id): JsonResponse
    {
        $ad = Ad::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'description' => 'nullable|string|max:2000',
            'image' => 'nullable|file|mimes:jpg,jpeg,png,gif|max:2048',
            'link_url' => 'required|url|max:500',
            'type' => 'required|in:banner,video,carousel,popup',
            'position' => 'required|in:top,sidebar,bottom,popup,in_feed',
            'status' => 'required|in:active,paused,expired,rejected',
            'budget' => 'nullable|numeric|min:0|max:100000',
            'daily_budget' => 'nullable|numeric|min:0|max:10000',
            'cost_per_click' => 'nullable|numeric|min:0|max:100',
            'cost_per_impression' => 'nullable|numeric|min:0|max:10',
            'max_impressions' => 'nullable|integer|min:1|max:1000000',
            'max_clicks' => 'nullable|integer|min:1|max:100000',
            'starts_at' => 'nullable|date',
            'ends_at' => 'nullable|date|after:starts_at',
            'targeting' => 'nullable|array',
            'metadata' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $data = $request->only([
                'title', 'description', 'link_url', 'type', 'position', 'status',
                'budget', 'daily_budget', 'cost_per_click', 'cost_per_impression',
                'max_impressions', 'max_clicks', 'starts_at', 'ends_at',
                'targeting', 'metadata'
            ]);

            // Upload de l'image
            if ($request->hasFile('image')) {
                // Supprimer l'ancienne image
                if ($ad->image) {
                    Storage::disk('public')->delete($ad->image);
                }
                $data['image'] = $request->file('image')->store('ad-images', 'public');
            }

            $ad->update($data);

            return response()->json([
                'message' => 'Publicité mise à jour',
                'ad' => $ad->fresh()->load(['shop', 'adCampaign']),
            ]);

        } catch (\Exception $e) {
            \Log::error('Error updating ad: ' . $e->getMessage(), ['ad_id' => $id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de la mise à jour de la publicité'], 500);
        }
    }

    /**
     * Supprimer une publicité
     */
    public function destroy($id): JsonResponse
    {
        $ad = Ad::findOrFail($id);

        try {
            // Supprimer l'image
            if ($ad->image) {
                Storage::disk('public')->delete($ad->image);
            }

            $ad->delete();

            return response()->json(['message' => 'Publicité supprimée']);

        } catch (\Exception $e) {
            \Log::error('Error deleting ad: ' . $e->getMessage(), ['ad_id' => $id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de la suppression de la publicité'], 500);
        }
    }

    /**
     * Démarrer une publicité (activer)
     */
    public function start($id): JsonResponse
    {
        $ad = Ad::findOrFail($id);

        if ($ad->is_expired) {
            return response()->json(['error' => 'Publicité expirée'], 400);
        }

        try {
            $ad->update([
                'status' => 'active',
                'starts_at' => now(),
            ]);

            return response()->json([
                'message' => 'Publicité démarrée',
                'ad' => $ad->fresh(),
            ]);

        } catch (\Exception $e) {
            \Log::error('Error starting ad: ' . $e->getMessage(), ['ad_id' => $id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors du démarrage de la publicité'], 500);
        }
    }

    /**
     * Mettre en pause une publicité
     */
    public function pause($id): JsonResponse
    {
        $ad = Ad::findOrFail($id);

        try {
            $ad->update(['status' => 'paused']);

            return response()->json([
                'message' => 'Publicité mise en pause',
                'ad' => $ad->fresh(),
            ]);

        } catch (\Exception $e) {
            \Log::error('Error pausing ad: ' . $e->getMessage(), ['ad_id' => $id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de la mise en pause de la publicité'], 500);
        }
    }

    /**
     * Obtenir les publicités actives pour affichage
     */
    public function getActiveAds(Request $request): JsonResponse
    {
        $query = Ad::with(['shop'])
            ->whereHas('shop', function ($q) {
                $q->where('certifiee', true);
            })
            ->running()
            ->orderBy('created_at', 'desc');

        // Filtres par position
        if ($request->position) {
            $query->byPosition($request->position);
        }

        // Filtres par type
        if ($request->type) {
            $query->byType($request->type);
        }

        $ads = $query->get();

        return response()->json(['active_ads' => $ads]);
    }

    /**
     * Enregistrer une impression (tracking)
     */
    public function recordImpression(Request $request, $id): JsonResponse
    {
        $ad = Ad::findOrFail($id);

        if (!$ad->is_running) {
            return response()->json(['error' => 'Publicité non active'], 400);
        }

        try {
            $ad->recordImpression();

            return response()->json([
                'message' => 'Impression enregistrée',
                'impressions_count' => $ad->fresh()->impressions_count,
                'remaining_impressions' => $ad->fresh()->remaining_impressions,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error recording impression: ' . $e->getMessage(), ['ad_id' => $id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de l\'enregistrement de l\'impression'], 500);
        }
    }

    /**
     * Enregistrer un clic (tracking)
     */
    public function recordClick(Request $request, $id): JsonResponse
    {
        $ad = Ad::findOrFail($id);

        if (!$ad->is_running) {
            return response()->json(['error' => 'Publicité non active'], 400);
        }

        try {
            $ad->recordClick();

            return response()->json([
                'message' => 'Clic enregistré',
                'clicks_count' => $ad->fresh()->clicks_count,
                'remaining_clicks' => $ad->fresh()->remaining_clicks,
                'redirect_url' => $ad->link_url,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error recording click: ' . $e->getMessage(), ['ad_id' => $id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de l\'enregistrement du clic'], 500);
        }
    }

    /**
     * Enregistrer une conversion (tracking)
     */
    public function recordConversion(Request $request, $id): JsonResponse
    {
        $ad = Ad::findOrFail($id);

        if (!$ad->is_running) {
            return response()->json(['error' => 'Publicité non active'], 400);
        }

        $validator = Validator::make($request->all(), [
            'conversion_value' => 'nullable|numeric|min:0',
            'conversion_data' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $ad->recordConversion();

            // Mettre à jour les métadonnées si fournies
            if ($request->conversion_data) {
                $metadata = $ad->metadata ?? [];
                $metadata['conversions'][] = [
                    'value' => $request->conversion_value,
                    'data' => $request->conversion_data,
                    'timestamp' => now()->toISOString(),
                ];
                $ad->update(['metadata' => $metadata]);
            }

            return response()->json([
                'message' => 'Conversion enregistrée',
                'conversions_count' => $ad->fresh()->conversions_count,
            ]);

        } catch (\Exception $e) {
            \Log::error('Error recording conversion: ' . $e->getMessage(), ['ad_id' => $id, 'trace' => $e->getTraceAsString()]);
            return response()->json(['error' => 'Une erreur est survenue lors de l\'enregistrement de la conversion'], 500);
        }
    }

    /**
     * Obtenir les statistiques d'une publicité
     */
    public function getStats($id): JsonResponse
    {
        $ad = Ad::with(['shop', 'adCampaign'])->findOrFail($id);

        $stats = [
            'impressions_count' => $ad->impressions_count,
            'clicks_count' => $ad->clicks_count,
            'conversions_count' => $ad->conversions_count,
            'click_through_rate' => $ad->click_through_rate,
            'conversion_rate' => $ad->conversion_rate,
            'spent_amount' => $ad->spent_amount,
            'remaining_budget' => $ad->remaining_budget,
            'remaining_daily_budget' => $ad->remaining_daily_budget,
            'remaining_impressions' => $ad->remaining_impressions,
            'remaining_clicks' => $ad->remaining_clicks,
            'is_running' => $ad->is_running,
            'is_expired' => $ad->is_expired,
        ];

        return response()->json(['stats' => $stats]);
    }

    /**
     * Obtenir les publicités d'une boutique
     */
    public function getShopAds(Request $request, $shopId): JsonResponse
    {
        $shop = Shop::findOrFail($shopId);
        
        $query = Ad::where('shop_id', $shopId)
            ->with(['adCampaign']);

        // Filtres
        if ($request->status) {
            switch ($request->status) {
                case 'active':
                    $query->active();
                    break;
                case 'paused':
                    $query->paused();
                    break;
                case 'expired':
                    $query->expired();
                    break;
            }
        }

        if ($request->type) {
            $query->byType($request->type);
        }

        $ads = $query->orderBy('created_at', 'desc')
            ->paginate($request->limit ?? 20);

        return response()->json([
            'ads' => $ads,
            'shop' => $shop,
        ]);
    }

    /**
     * Obtenir les statistiques globales des publicités (admin)
     */
    public function getGlobalStats(): JsonResponse
    {
        $stats = [
            'total_ads' => Ad::count(),
            'active_ads' => Ad::active()->count(),
            'paused_ads' => Ad::paused()->count(),
            'expired_ads' => Ad::expired()->count(),
            'total_impressions' => Ad::sum('impressions_count'),
            'total_clicks' => Ad::sum('clicks_count'),
            'total_conversions' => Ad::sum('conversions_count'),
            'total_spent' => Ad::sum('spent_amount'),
            'average_ctr' => Ad::count() > 0 ? round((Ad::sum('clicks_count') / Ad::sum('impressions_count')) * 100, 2) : 0,
            'average_conversion_rate' => Ad::sum('clicks_count') > 0 ? round((Ad::sum('conversions_count') / Ad::sum('clicks_count')) * 100, 2) : 0,
            'top_performing_ads' => Ad::with(['shop'])
                ->orderBy('clicks_count', 'desc')
                ->limit(10)
                ->get(),
        ];

        return response()->json(['stats' => $stats]);
    }

    /**
     * Obtenir les publicités pour un utilisateur (ciblage)
     */
    public function getTargetedAds(Request $request): JsonResponse
    {
        $userId = auth()->id();
        
        $query = Ad::with(['shop'])
            ->active()
            ->running();

        // Logique de ciblage simplifiée
        // En pratique, cela utiliserait un système plus complexe
        // basé sur les préférences, localisation, démographie, etc.
        
        $ads = $query->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'targeted_ads' => $ads,
            'user_id' => $userId,
        ]);
    }
}
