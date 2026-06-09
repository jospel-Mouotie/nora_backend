<?php

namespace App\Http\Controllers;

use App\Models\UserInterest;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Validator;

class UserInterestController extends Controller
{
    /**
     * Obtenir les centres d'intérêt de l'utilisateur
     */
    public function index(Request $request): JsonResponse
    {
        $userId = auth()->id();
        
        $query = UserInterest::where('user_id', $userId)
                           ->with('category');

        // Filtres
        if ($request->is_active !== null) {
            $query->where('is_active', $request->is_active);
        }

        if ($request->priority_level) {
            $query->where('priority_level', $request->priority_level);
        }

        $interests = $query->orderBy('priority_level', 'desc')
                         ->orderBy('created_at', 'desc')
                         ->get();

        return response()->json(['interests' => $interests]);
    }

    /**
     * Ajouter un centre d'intérêt
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'category_id' => 'required|exists:categories,id',
            'priority_level' => 'required|integer|min:1|max:5',
            'metadata' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $userId = auth()->id();
            
            $interest = UserInterest::updateOrCreate(
                ['user_id' => $userId, 'category_id' => $request->category_id],
                [
                    'priority_level' => $request->priority_level,
                    'metadata' => $request->metadata,
                    'is_active' => true,
                    'selected_at' => now(),
                ]
            );

            return response()->json([
                'message' => 'Centre d\'intérêt ajouté avec succès',
                'interest' => $interest->load('category'),
            ], 201);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Mettre à jour un centre d'intérêt
     */
    public function update(Request $request, $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'priority_level' => 'required|integer|min:1|max:5',
            'is_active' => 'required|boolean',
            'metadata' => 'nullable|array',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $userId = auth()->id();
            
            $interest = UserInterest::where('user_id', $userId)
                                   ->where('id', $id)
                                   ->firstOrFail();

            $interest->update([
                'priority_level' => $request->priority_level,
                'is_active' => $request->is_active,
                'metadata' => $request->metadata,
            ]);

            return response()->json([
                'message' => 'Centre d\'intérêt mis à jour',
                'interest' => $interest->load('category'),
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Supprimer un centre d'intérêt
     */
    public function destroy($id): JsonResponse
    {
        try {
            $userId = auth()->id();
            
            $interest = UserInterest::where('user_id', $userId)
                                   ->where('id', $id)
                                   ->firstOrFail();

            $interest->delete();

            return response()->json(['message' => 'Centre d\'intérêt supprimé']);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Obtenir les catégories recommandées pour l'utilisateur
     */
    public function getRecommendedCategories(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $limit = $request->limit ?? 10;

        try {
            $recommendedCategories = UserInterest::getRecommendedCategories($userId, $limit);

            return response()->json([
                'recommended_categories' => $recommendedCategories,
                'limit' => $limit,
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Obtenir les catégories disponibles (non sélectionnées)
     */
    public function getAvailableCategories(Request $request): JsonResponse
    {
        $userId = auth()->id();
        
        try {
            // Obtenir les IDs des catégories déjà sélectionnées
            $selectedCategoryIds = UserInterest::where('user_id', $userId)
                                              ->active()
                                              ->pluck('category_id');

            // Obtenir les catégories disponibles
            $availableCategories = Category::active()
                                          ->whereNotIn('id', $selectedCategoryIds)
                                          ->withCount(['userInterests' => function ($query) {
                                              $query->active();
                                          }])
                                          ->orderBy('user_interests_count', 'desc')
                                          ->orderBy('name', 'asc')
                                          ->get();

            return response()->json([
                'available_categories' => $availableCategories,
                'selected_count' => $selectedCategoryIds->count(),
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Sélectionner plusieurs catégories à la fois (onboarding)
     */
    public function selectMultiple(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'categories' => 'required|array|min:1',
            'categories.*.category_id' => 'required|exists:categories,id',
            'categories.*.priority_level' => 'required|integer|min:1|max:5',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $userId = auth()->id();
            $selectedInterests = [];

            foreach ($request->categories as $categoryData) {
                $interest = UserInterest::addInterest(
                    $userId,
                    $categoryData['category_id'],
                    $categoryData['priority_level']
                );
                $selectedInterests[] = $interest;
            }

            return response()->json([
                'message' => 'Catégories sélectionnées avec succès',
                'interests' => UserInterest::where('user_id', $userId)
                                         ->with('category')
                                         ->whereIn('id', collect($selectedInterests)->pluck('id'))
                                         ->get(),
            ], 201);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Obtenir les catégories les plus populaires
     */
    public function getPopularCategories(Request $request): JsonResponse
    {
        $limit = $request->limit ?? 20;

        try {
            $popularCategories = Category::withCount(['userInterests' => function ($query) {
                                              $query->active()->highPriority();
                                          }])
                                          ->orderBy('user_interests_count', 'desc')
                                          ->limit($limit)
                                          ->get();

            return response()->json([
                'popular_categories' => $popularCategories,
                'limit' => $limit,
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Obtenir les centres d'intérêt par niveau de priorité
     */
    public function getByPriority(Request $request): JsonResponse
    {
        $userId = auth()->id();
        $priorityLevel = $request->priority_level;

        if (!$priorityLevel || $priorityLevel < 1 || $priorityLevel > 5) {
            return response()->json(['error' => 'Niveau de priorité invalide'], 400);
        }

        try {
            $interests = UserInterest::where('user_id', $userId)
                                   ->where('priority_level', $priorityLevel)
                                   ->active()
                                   ->with('category')
                                   ->orderBy('created_at', 'desc')
                                   ->get();

            return response()->json([
                'interests' => $interests,
                'priority_level' => $priorityLevel,
                'priority_label' => collect([
                    1 => 'Peu intéressé',
                    2 => 'Moyennement intéressé',
                    3 => 'Intéressé',
                    4 => 'Très intéressé',
                    5 => 'Passionné',
                ])[$priorityLevel],
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Mettre à jour les niveaux de priorité en masse
     */
    public function updatePriorities(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'priorities' => 'required|array',
            'priorities.*.interest_id' => 'required|exists:user_interests,id',
            'priorities.*.priority_level' => 'required|integer|min:1|max:5',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        try {
            $userId = auth()->id();
            $updatedInterests = [];

            foreach ($request->priorities as $priorityData) {
                $interest = UserInterest::where('user_id', $userId)
                                       ->where('id', $priorityData['interest_id'])
                                       ->first();

                if ($interest) {
                    $interest->updatePriority($priorityData['priority_level']);
                    $updatedInterests[] = $interest;
                }
            }

            return response()->json([
                'message' => 'Priorités mises à jour avec succès',
                'interests' => UserInterest::where('user_id', $userId)
                                         ->with('category')
                                         ->whereIn('id', collect($updatedInterests)->pluck('id'))
                                         ->get(),
            ]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Obtenir les statistiques des centres d'intérêt
     */
    public function getStats(): JsonResponse
    {
        $userId = auth()->id();

        try {
            $stats = [
                'total_interests' => UserInterest::where('user_id', $userId)->count(),
                'active_interests' => UserInterest::where('user_id', $userId)->active()->count(),
                'high_priority_interests' => UserInterest::where('user_id', $userId)->active()->highPriority()->count(),
                'medium_priority_interests' => UserInterest::where('user_id', $userId)->active()->mediumPriority()->count(),
                'low_priority_interests' => UserInterest::where('user_id', $userId)->active()->lowPriority()->count(),
                'top_interests' => UserInterest::getTopInterests($userId, 5),
                'recent_selections' => UserInterest::where('user_id', $userId)
                                                ->active()
                                                ->orderBy('selected_at', 'desc')
                                                ->limit(5)
                                                ->with('category')
                                                ->get(),
            ];

            return response()->json(['stats' => $stats]);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    /**
     * Réinitialiser les centres d'intérêt (pour le re-onboarding)
     */
    public function reset(): JsonResponse
    {
        try {
            $userId = auth()->id();
            
            UserInterest::where('user_id', $userId)->delete();

            return response()->json(['message' => 'Centres d\'intérêt réinitialisés']);

        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }
}
