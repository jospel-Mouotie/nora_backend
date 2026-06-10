<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use App\Models\Category;
use App\Traits\ApiResponse;
use App\Traits\HandlesFileUploads;
use App\Traits\AuthorizesRoles;

class CategoryController extends Controller
{
    use ApiResponse, HandlesFileUploads, AuthorizesRoles;

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
            return $this->notFoundResponse('Catégorie parente');
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
            return $this->notFoundResponse('Catégorie');
        }

        return response()->json($category);
    }

    /**
     * Créer une nouvelle catégorie (admin uniquement)
     */
    public function store(Request $request)
    {
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
        }

        if ($error = $this->validateRequestData($request->all(), [
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
            'parent_id' => 'nullable|exists:categories,id',
        ])) {
            return $error;
        }

        $data = $request->all();

        // Gérer l'upload de l'image
        if ($path = $this->uploadFile($request, 'image', 'categories')) {
            $data['image'] = $path;
        }

        // Vérifier qu'on ne crée pas de boucle dans l'arborescence
        if (!empty($data['parent_id'])) {
            if ($this->wouldCreateLoop($data['parent_id'])) {
                return $this->errorResponse('Création d\'une boucle dans l\'arborescence détectée', 422);
            }
        }

        $category = Category::create($data);

        return $this->createdResponse(
            ['category' => $category->load(['parent', 'children'])],
            'Catégorie créée avec succès'
        );
    }

    /**
     * Mettre à jour une catégorie (admin uniquement)
     */
    public function update(Request $request, $id)
    {
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
        }

        $category = Category::find($id);
        
        if (!$category) {
            return $this->notFoundResponse('Catégorie');
        }

        if ($error = $this->validateRequestData($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_active' => 'boolean',
            'sort_order' => 'integer|min:0',
            'parent_id' => 'nullable|exists:categories,id',
        ])) {
            return $error;
        }

        $data = $request->all();

        // Gérer l'upload de l'image
        if ($path = $this->replaceFile($request, 'image', 'categories', $category->image)) {
            $data['image'] = $path;
        }

        // Vérifier qu'on ne crée pas de boucle dans l'arborescence
        if (isset($data['parent_id']) && $data['parent_id'] != $category->parent_id) {
            if ($this->wouldCreateLoop($data['parent_id'], $id)) {
                return $this->errorResponse('Création d\'une boucle dans l\'arborescence détectée', 422);
            }
        }

        $category->update($data);

        return $this->successResponse(
            ['category' => $category->load(['parent', 'children'])],
            'Catégorie mise à jour avec succès'
        );
    }

    /**
     * Supprimer une catégorie (admin uniquement)
     */
    public function destroy(Request $request, $id)
    {
        if ($error = $this->authorizeAdmin($request)) {
            return $error;
        }

        $category = Category::find($id);
        
        if (!$category) {
            return $this->notFoundResponse('Catégorie');
        }

        // Vérifier qu'il n'y a pas de produits associés
        if ($category->products()->count() > 0) {
            return $this->errorResponse('Impossible de supprimer une catégorie contenant des produits', 422);
        }

        $this->deleteStoredFile($category->image);

        $category->delete();

        return $this->successResponse([], 'Catégorie supprimée avec succès');
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
            return $this->notFoundResponse('Catégorie');
        }

        return response()->json([
            'id' => $category->id,
            'full_path' => $category->getFullPath(),
            'slug' => $category->slug
        ]);
    }
}
