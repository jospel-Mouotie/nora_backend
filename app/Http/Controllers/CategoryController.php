<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;
use App\Models\Category;

class CategoryController extends Controller
{
    /**
     * Lister toutes les catégories avec structure arborescente
     */
    public function index(Request $request)
    {
        $tree = Category::getTree();
        
        return response()->json($tree);
    }

    /**
     * Lister les catégories racines (sans parent)
     */
    public function root(Request $request)
    {
        $categories = Category::root()
                             ->active()
                             ->with(['children' => function($query) {
                                 $query->active()->orderBy('sort_order');
                             }])
                             ->orderBy('sort_order')
                             ->get();

        return response()->json($categories);
    }

    /**
     * Lister les sous-catégories d'une catégorie
     */
    public function children(Request $request, $parentId)
    {
        $parent = Category::find($parentId);

        if (!$parent) {
            return response()->json(['message' => 'Catégorie parente non trouvée'], 404);
        }

        $children = $parent->children()
                           ->active()
                           ->orderBy('sort_order')
                           ->get();

        return response()->json($children);
    }

    /**
     * Afficher une catégorie spécifique avec ses enfants
     */
    public function show($id)
    {
        $category = Category::with(['parent', 'children' => function($query) {
            $query->active()->orderBy('sort_order');
        }])
        ->find($id);

        if (!$category) {
            return response()->json(['message' => 'Catégorie non trouvée'], 404);
        }

        return response()->json($category);
    }

    /**
     * Créer une nouvelle catégorie (admin uniquement)
     */
    public function store(Request $request)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
            'parent_id' => 'nullable|exists:categories,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Gérer l'upload de l'image
        if ($request->hasFile('image')) {
            $path = $request->file('image')->store('categories', 'public');
            $data['image'] = $path;
        }

        // Vérifier qu'on ne crée pas de boucle dans l'arborescence
        if (!empty($data['parent_id'])) {
            if ($this->wouldCreateLoop($data['parent_id'])) {
                return response()->json(['message' => 'Création d\'une boucle dans l\'arborescence détectée'], 422);
            }
        }

        $category = Category::create($data);

        return response()->json([
            'message' => 'Catégorie créée avec succès',
            'category' => $category->load(['parent', 'children'])
        ], 201);
    }

    /**
     * Mettre à jour une catégorie (admin uniquement)
     */
    public function update(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $category = Category::find($id);
        
        if (!$category) {
            return response()->json(['message' => 'Catégorie non trouvée'], 404);
        }

        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
            'parent_id' => 'nullable|exists:categories,id',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $data = $request->all();

        // Gérer l'upload de l'image
        if ($request->hasFile('image')) {
            // Supprimer l'ancienne image si elle existe
            if ($category->image) {
                Storage::disk('public')->delete($category->image);
            }
            $path = $request->file('image')->store('categories', 'public');
            $data['image'] = $path;
        }

        // Vérifier qu'on ne crée pas de boucle dans l'arborescence
        if (isset($data['parent_id']) && $data['parent_id'] != $category->parent_id) {
            if ($this->wouldCreateLoop($data['parent_id'], $id)) {
                return response()->json(['message' => 'Création d\'une boucle dans l\'arborescence détectée'], 422);
            }
        }

        $category->update($data);

        return response()->json([
            'message' => 'Catégorie mise à jour avec succès',
            'category' => $category->load(['parent', 'children'])
        ]);
    }

    /**
     * Supprimer une catégorie (admin uniquement)
     */
    public function destroy(Request $request, $id)
    {
        if ($request->user()->role !== 'admin') {
            return response()->json(['message' => 'Non autorisé'], 403);
        }

        $category = Category::find($id);
        
        if (!$category) {
            return response()->json(['message' => 'Catégorie non trouvée'], 404);
        }

        // Vérifier qu'il n'y a pas de produits associés
        if ($category->products()->count() > 0) {
            return response()->json(['message' => 'Impossible de supprimer une catégorie contenant des produits'], 422);
        }

        // Supprimer l'image si elle existe
        if ($category->image) {
            Storage::disk('public')->delete($category->image);
        }

        $category->delete();

        return response()->json(['message' => 'Catégorie supprimée avec succès']);
    }

    /**
     * Obtenir les options pour un select (format hiérarchique)
     */
    public function selectOptions(Request $request)
    {
        $options = Category::getSelectOptions();
        
        return response()->json($options);
    }

    /**
     * Vérifier si la création/mise à jour créerait une boucle dans l'arborescence
     */
    private function wouldCreateLoop($parentId, $excludeId = null)
    {
        if (!$parentId) {
            return false;
        }

        $descendantIds = [];
        if ($excludeId) {
            $category = Category::find($excludeId);
            if ($category) {
                $descendantIds = $category->getDescendantIds();
            }
        }

        return in_array($parentId, $descendantIds);
    }

    /**
     * Obtenir le chemin complet d'une catégorie
     */
    public function path($id)
    {
        $category = Category::find($id);
        
        if (!$category) {
            return response()->json(['message' => 'Catégorie non trouvée'], 404);
        }

        return response()->json([
            'id' => $category->id,
            'full_path' => $category->getFullPath(),
            'slug' => $category->slug
        ]);
    }
}
