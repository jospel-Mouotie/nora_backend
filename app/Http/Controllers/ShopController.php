<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use App\Models\Shop;
use App\Models\User;
use App\Models\Category;
use App\Services\NotificationService;

class ShopController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Créer une nouvelle boutique (réservé aux commerçants/grossistes)
     */
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'address' => 'required|string',
            'phone' => 'required|string|max:20',
            'email' => 'required|email',
            'photo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'banner' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:4096',
            'category_ids' => 'nullable|array',
            'category_ids.*' => 'exists:categories,id',
            // Nouveaux champs
            'delivery_cities' => 'nullable|array',
            'delivery_cities.*' => 'string|max:100',
            'delivery_price' => 'nullable|numeric|min:0',
            'free_delivery_min_amount' => 'nullable|numeric|min:0',
            'delivery_type' => 'nullable|in:standard,express,both',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'opening_hours' => 'nullable|array',
            'facebook_url' => 'nullable|url|max:255',
            'instagram_url' => 'nullable|url|max:255',
            'whatsapp_number' => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = $request->user();
        if (!in_array($user->role, ['commercant', 'grossiste', 'admin'])) {
            return response()->json(['message' => 'Seuls les commerçants et grossistes peuvent créer des boutiques'], 403);
        }

        $existingShops = Shop::where('user_id', $user->id)
            ->whereIn('status', ['active', 'en_attente'])
            ->count();

        if ($existingShops >= 3) {
            return response()->json(['message' => 'Vous avez atteint la limite de 3 boutiques actives'], 403);
        }

        $data = $request->except(['photo', 'banner', 'category_ids']);
        $data['user_id'] = $user->id;
        $data['status'] = 'en_attente';

        // Gérer l'upload de la photo (logo)
        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('shops/logos', 'public');
            $data['photo'] = $path;
        }

        // Gérer l'upload de la bannière
        if ($request->hasFile('banner')) {
            $path = $request->file('banner')->store('shops/banners', 'public');
            $data['banner'] = $path;
        }

        // Gérer les villes de livraison
        if ($request->has('delivery_cities')) {
            $data['delivery_cities'] = json_encode($request->delivery_cities);
        }

        // Gérer les horaires d'ouverture
        if ($request->has('opening_hours')) {
            $data['opening_hours'] = json_encode($request->opening_hours);
        }

        // Gérer les autres champs
        if ($request->has('delivery_price')) $data['delivery_price'] = $request->delivery_price;
        if ($request->has('free_delivery_min_amount')) $data['free_delivery_min_amount'] = $request->free_delivery_min_amount;
        if ($request->has('delivery_type')) $data['delivery_type'] = $request->delivery_type;
        if ($request->has('latitude')) $data['latitude'] = $request->latitude;
        if ($request->has('longitude')) $data['longitude'] = $request->longitude;
        if ($request->has('facebook_url')) $data['facebook_url'] = $request->facebook_url;
        if ($request->has('instagram_url')) $data['instagram_url'] = $request->instagram_url;
        if ($request->has('whatsapp_number')) $data['whatsapp_number'] = $request->whatsapp_number;

        $shop = Shop::create($data);

        // Synchroniser les catégories
        if ($request->has('category_ids') && is_array($request->category_ids)) {
            $shop->syncCategories($request->category_ids);
        }

        // Notifier les admins de la création de la boutique
        $this->notificationService->notifyShopCreated($shop->id, $shop->name);

        return response()->json([
            'message' => 'Boutique créée avec succès. En attente de validation par l\'administrateur.',
            'shop' => $shop->load('categories')
        ], 201);
    }

    /**
     * Lister les boutiques (uniquement les boutiques actives)
     */
    public function index(Request $request)
    {
        $query = Shop::where('status', 'active')
            ->with(['user', 'categories'])
            ->orderBy('created_at', 'desc');

        // Filtre par catégorie
        if ($request->has('category_id')) {
            $query->whereHas('categories', function ($q) use ($request) {
                $q->where('category_id', $request->category_id);
            });
        }

        // Filtre par recherche
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%");
            });
        }

        // Filtre par ville
        if ($request->has('city')) {
            $query->where('address', 'like', '%' . $request->city . '%');
        }

        $shops = $query->get();

        // Ajouter les URLs des images
        foreach ($shops as $shop) {
            $shop->photo_url = $shop->photo ? Storage::url($shop->photo) : null;
            $shop->banner_url = $shop->banner ? Storage::url($shop->banner) : null;
        }

        return response()->json($shops);
    }

    /**
     * Afficher une boutique spécifique
     */
    public function show($id)
    {
        $shop = Shop::with(['user', 'products', 'categories', 'followers'])
            ->withCount(['followers', 'products'])
            ->find($id);

        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        // Ajouter les URLs complètes des images
        $shop->photo_url = $shop->photo ? Storage::url($shop->photo) : null;
        $shop->banner_url = $shop->banner ? Storage::url($shop->banner) : null;
        
        // Décoder les JSON
        if ($shop->delivery_cities && is_string($shop->delivery_cities)) {
            $shop->delivery_cities = json_decode($shop->delivery_cities, true);
        }
        if ($shop->opening_hours && is_string($shop->opening_hours)) {
            $shop->opening_hours = json_decode($shop->opening_hours, true);
        }

        return response()->json($shop);
    }

    /**
     * Mettre à jour une boutique (propriétaire uniquement)
     */
    public function update(Request $request, $id)
    {
        $shop = Shop::find($id);

        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        if ($shop->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'description' => 'sometimes|required|string',
            'address' => 'sometimes|required|string',
            'phone' => 'sometimes|required|string|max:20',
            'email' => 'sometimes|required|email',
            'photo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'banner' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:4096',
            'category_ids' => 'nullable|array',
            'category_ids.*' => 'exists:categories,id',
            'delivery_cities' => 'nullable|array',
            'delivery_cities.*' => 'string|max:100',
            'delivery_price' => 'nullable|numeric|min:0',
            'free_delivery_min_amount' => 'nullable|numeric|min:0',
            'delivery_type' => 'nullable|in:standard,express,both',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'opening_hours' => 'nullable|array',
            'facebook_url' => 'nullable|url|max:255',
            'instagram_url' => 'nullable|url|max:255',
            'whatsapp_number' => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->except(['photo', 'banner', 'category_ids', 'delivery_cities', 'opening_hours']);

        // Gérer l'upload de la photo (logo)
        if ($request->hasFile('photo')) {
            try {
                if ($shop->photo) {
                    Storage::disk('public')->delete($shop->photo);
                }
                $path = $request->file('photo')->store('shops/logos', 'public');
                if ($path === false) {
                    return response()->json(['message' => 'Erreur lors de l\'upload de la photo'], 500);
                }
                $data['photo'] = $path;
            } catch (\Exception $e) {
                \Log::error('Error uploading shop photo: ' . $e->getMessage(), ['shop_id' => $id, 'trace' => $e->getTraceAsString()]);
                return response()->json(['message' => 'Erreur lors de l\'upload de la photo'], 500);
            }
        }

        // Gérer l'upload de la bannière
        if ($request->hasFile('banner')) {
            if ($shop->banner) {
                Storage::disk('public')->delete($shop->banner);
            }
            $path = $request->file('banner')->store('shops/banners', 'public');
            $data['banner'] = $path;
        }

        // Gérer les villes de livraison
        if ($request->has('delivery_cities')) {
            $data['delivery_cities'] = json_encode($request->delivery_cities);
        }

        // Gérer les horaires d'ouverture
        if ($request->has('opening_hours')) {
            $data['opening_hours'] = json_encode($request->opening_hours);
        }

        // Gérer les autres champs
        if ($request->has('delivery_price')) $data['delivery_price'] = $request->delivery_price;
        if ($request->has('free_delivery_min_amount')) $data['free_delivery_min_amount'] = $request->free_delivery_min_amount;
        if ($request->has('delivery_type')) $data['delivery_type'] = $request->delivery_type;
        if ($request->has('latitude')) $data['latitude'] = $request->latitude;
        if ($request->has('longitude')) $data['longitude'] = $request->longitude;
        if ($request->has('facebook_url')) $data['facebook_url'] = $request->facebook_url;
        if ($request->has('instagram_url')) $data['instagram_url'] = $request->instagram_url;
        if ($request->has('whatsapp_number')) $data['whatsapp_number'] = $request->whatsapp_number;

        $shop->update($data);

        // Synchroniser les catégories
        if ($request->has('category_ids')) {
            $shop->syncCategories($request->category_ids ?? []);
        }

        return response()->json([
            'message' => 'Boutique mise à jour avec succès',
            'shop' => $shop->load('categories')
        ]);
    }

    /**
     * Supprimer une boutique (propriétaire ou admin uniquement)
     */
    public function destroy(Request $request, $id)
    {
        $shop = Shop::find($id);

        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        if ($shop->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        // Supprimer les fichiers
        if ($shop->photo) {
            try {
                Storage::disk('public')->delete($shop->photo);
            } catch (\Exception $e) {
                \Log::warning('Failed to delete shop photo during shop deletion: ' . $e->getMessage(), ['shop_id' => $id]);
            }
        }
        if ($shop->banner) {
            Storage::disk('public')->delete($shop->banner);
        }

        $shop->delete();

        return response()->json(['message' => 'Boutique supprimée avec succès']);
    }

    /**
     * Lister les boutiques en attente de validation (admin uniquement)
     */
    public function enAttente(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $shops = Shop::where('status', 'en_attente')
            ->with(['user', 'categories'])
            ->orderBy('created_at', 'asc')
            ->get();

        return response()->json($shops);
    }

    /**
     * Valider une boutique (admin uniquement)
     */
    public function valider(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $shop = Shop::find($id);

        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        $shop->update(['status' => 'active']);

        // Notifier le propriétaire de la boutique
        $this->notificationService->notifyShopApproved($shop->user_id, $shop->name);

        return response()->json([
            'message' => 'Boutique validée avec succès',
            'shop' => $shop->load('categories')
        ]);
    }

    /**
     * Refuser une boutique (admin uniquement)
     */
    public function refuser(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $shop = Shop::find($id);

        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
        }

        $shop->update(['status' => 'refusee']);

        // Notifier le propriétaire du refus
        $this->notificationService->notifyShopRejected($shop->user_id, $shop->name);

        return response()->json([
            'message' => 'Boutique refusée',
            'shop' => $shop
        ]);
    }

    /**
     * Afficher mes boutiques (propriétaire uniquement)
     */
    public function mesBoutiques(Request $request)
    {
        $shops = $request->user()->shops()->with('categories')->get();

        // Ajouter les URLs des images
        foreach ($shops as $shop) {
            $shop->photo_url = $shop->photo ? Storage::url($shop->photo) : null;
            $shop->banner_url = $shop->banner ? Storage::url($shop->banner) : null;
            if ($shop->delivery_cities && is_string($shop->delivery_cities)) {
                $shop->delivery_cities = json_decode($shop->delivery_cities, true);
            }
            if ($shop->opening_hours && is_string($shop->opening_hours)) {
                $shop->opening_hours = json_decode($shop->opening_hours, true);
            }
        }

        return response()->json(['success' => true, 'shops' => $shops]);
    }
}