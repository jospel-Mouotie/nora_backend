<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use App\Models\Shop;
use App\Models\User;

class ShopController extends Controller
{
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
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        // Vérifier le rôle de l'utilisateur
        $user = $request->user();
        if (!in_array($user->role, ['commercant', 'grossiste', 'admin'])) {
            return response()->json(['message' => 'Seuls les commerçants et grossistes peuvent créer des boutiques'], 403);
        }

        // Vérifier si l'utilisateur a déjà des boutiques actives
        $existingShops = Shop::where('user_id', $user->id)
            ->whereIn('status', ['active', 'en_attente'])
            ->count();

        if ($existingShops >= 3) {
            return response()->json(['message' => 'Vous avez atteint la limite de 3 boutiques actives'], 403);
        }

        $data = $request->all();
        $data['user_id'] = $user->id;
        $data['status'] = 'en_attente'; // En attente de validation admin

        // Gérer l'upload de la photo
        if ($request->hasFile('photo')) {
            $path = $request->file('photo')->store('shops', 'public');
            $data['photo'] = $path;
        }

        $shop = Shop::create($data);

        return response()->json([
            'message' => 'Boutique créée avec succès. En attente de validation par l\'administrateur.',
            'shop' => $shop
        ], 201);
    }

    /**
     * Lister les boutiques (uniquement les boutiques actives)
     */
    public function index(Request $request)
    {
        $shops = Shop::where('status', 'active')
            ->with('user')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($shops);
    }

    /**
     * Afficher une boutique spécifique
     */
    public function show($id)
    {
        $shop = Shop::with(['user', 'products'])->find($id);

        if (!$shop) {
            return response()->json(['message' => 'Boutique non trouvée'], 404);
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

        // Vérifier que l'utilisateur est le propriétaire ou admin
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
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->except('photo');

        // Gérer l'upload de la photo
        if ($request->hasFile('photo')) {
            // Supprimer l'ancienne photo si elle existe
            if ($shop->photo) {
                Storage::disk('public')->delete($shop->photo);
            }
            $path = $request->file('photo')->store('shops', 'public');
            $data['photo'] = $path;
        }

        $shop->update($data);

        return response()->json([
            'message' => 'Boutique mise à jour avec succès',
            'shop' => $shop
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

        // Vérifier que l'utilisateur est le propriétaire ou admin
        if ($shop->user_id !== $request->user()->id && $request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        // Supprimer la photo si elle existe
        if ($shop->photo) {
            Storage::disk('public')->delete($shop->photo);
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
            ->with('user')
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

        return response()->json([
            'message' => 'Boutique validée avec succès',
            'shop' => $shop
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
        $shops = $request->user()->shops;

        return response()->json(['success' => true, 'shops' => $shops]);
    }
}
