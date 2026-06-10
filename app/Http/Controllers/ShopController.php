<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Shop;
use App\Models\User;
use App\Models\Category;
use App\Services\NotificationService;
use App\Traits\ApiResponse;
use App\Traits\HandlesFileUploads;
use App\Traits\AuthorizesRoles;

class ShopController extends Controller
{
    use ApiResponse, HandlesFileUploads, AuthorizesRoles;

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
        if ($error = $this->validateRequestData($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'required|string',
            'address' => 'required|string',
            'phone' => 'required|string|max:20',
            'email' => 'required|email',
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
        ])) {
            return $error;
        }

        $user = $request->user();
        if ($error = $this->authorizeRoles($request, ['commercant', 'grossiste', 'admin'])) {
            return $this->errorResponse('Seuls les commerçants et grossistes peuvent créer des boutiques', 403);
        }

        $existingShops = Shop::where('user_id', $user->id)
            ->whereIn('status', ['active', 'en_attente'])
            ->count();

        if ($existingShops >= 3) {
            return $this->errorResponse('Vous avez atteint la limite de 3 boutiques actives', 403);
        }

        $data = $request->except(['photo', 'banner', 'category_ids']);
        $data['user_id'] = $user->id;
        $data['status'] = 'en_attente';

        // Gérer l'upload de la photo (logo)
        if ($path = $this->uploadFile($request, 'photo', 'shops/logos')) {
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

        return $this->createdResponse(
            ['shop' => $shop->load('categories')],
            'Boutique créée avec succès. En attente de validation par l\'administrateur.'
        );
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
            return $this->notFoundResponse('Boutique');
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
            return $this->notFoundResponse('Boutique');
        }

        if ($error = $this->authorizeOwnerOrAdmin($request, $shop->user_id)) {
            return $error;
        }

        if ($error = $this->validateRequestData($request->all(), [
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
        ])) {
            return $error;
        }

        $data = $request->except(['photo', 'banner', 'category_ids', 'delivery_cities', 'opening_hours']);

        // Gérer l'upload de la photo (logo)
        if ($path = $this->replaceFile($request, 'photo', 'shops/logos', $shop->photo)) {
            $data['photo'] = $path;
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

        return $this->successResponse(
            ['shop' => $shop->load('categories')],
            'Boutique mise à jour avec succès'
        );
    }

    /**
     * Supprimer une boutique (propriétaire ou admin uniquement)
     */
    public function destroy(Request $request, $id)
    {
        $shop = Shop::find($id);

        if (!$shop) {
            return $this->notFoundResponse('Boutique');
        }

        if ($error = $this->authorizeOwnerOrAdmin($request, $shop->user_id)) {
            return $error;
        }

        $this->deleteStoredFile($shop->photo);
        $this->deleteStoredFile($shop->banner);

        $shop->delete();

        return $this->successResponse([], 'Boutique supprimée avec succès');
    }

    /**
     * Lister les boutiques en attente de validation (admin uniquement)
     */
    public function enAttente(Request $request)
    {
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
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
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
        }

        $shop = Shop::find($id);

        if (!$shop) {
            return $this->notFoundResponse('Boutique');
        }

        $shop->update(['status' => 'active']);

        // Notifier le propriétaire de la boutique
        $this->notificationService->notifyShopApproved($shop->user_id, $shop->name);

        return $this->successResponse(
            ['shop' => $shop->load('categories')],
            'Boutique validée avec succès'
        );
    }

    /**
     * Refuser une boutique (admin uniquement)
     */
    public function refuser(Request $request, $id)
    {
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
        }

        $shop = Shop::find($id);

        if (!$shop) {
            return $this->notFoundResponse('Boutique');
        }

        $shop->update(['status' => 'refusee']);

        // Notifier le propriétaire du refus
        $this->notificationService->notifyShopRejected($shop->user_id, $shop->name);

        return $this->successResponse(
            ['shop' => $shop],
            'Boutique refusée'
        );
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