<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserInterest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'category_id',
        'priority_level',
        'is_active',
        'selected_at',
        'metadata',
    ];

    protected $casts = [
        'priority_level' => 'integer',
        'is_active' => 'boolean',
        'selected_at' => 'datetime',
        'metadata' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function getPriorityLabelAttribute()
    {
        $labels = [
            1 => 'Peu intéressé',
            2 => 'Moyennement intéressé',
            3 => 'Intéressé',
            4 => 'Très intéressé',
            5 => 'Passionné',
        ];

        return $labels[$this->priority_level] ?? $this->priority_level;
    }

    public function updatePriority($level)
    {
        if ($level >= 1 && $level <= 5) {
            $this->update([
                'priority_level' => $level,
                'is_active' => true,
                'selected_at' => now(),
            ]);
        }
    }

    public function deactivate()
    {
        $this->update(['is_active' => false]);
    }

    public function activate()
    {
        $this->update(['is_active' => true, 'selected_at' => now()]);
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeByPriority($query, $order = 'desc')
    {
        return $query->orderBy('priority_level', $order);
    }

    public function scopeByCategory($query, $categoryId)
    {
        return $query->where('category_id', $categoryId);
    }

    public function scopeHighPriority($query)
    {
        return $query->where('priority_level', '>=', 4);
    }

    public function scopeMediumPriority($query)
    {
        return $query->whereBetween('priority_level', [2, 3]);
    }

    public function scopeLowPriority($query)
    {
        return $query->where('priority_level', '<=', 2);
    }

    // Méthodes statiques pour la gestion des intérêts
    public static function addInterest($userId, $categoryId, $priorityLevel = 1)
    {
        return self::updateOrCreate(
            ['user_id' => $userId, 'category_id' => $categoryId],
            [
                'priority_level' => $priorityLevel,
                'is_active' => true,
                'selected_at' => now(),
            ]
        );
    }

    public static function removeInterest($userId, $categoryId)
    {
        return self::where('user_id', $userId)
                   ->where('category_id', $categoryId)
                   ->delete();
    }

    public static function getUserInterests($userId)
    {
        return self::where('user_id', $userId)
                   ->active()
                   ->with('category')
                   ->byPriority()
                   ->get();
    }

    public static function getTopInterests($userId, $limit = 5)
    {
        return self::where('user_id', $userId)
                   ->active()
                   ->highPriority()
                   ->with('category')
                   ->byPriority()
                   ->limit($limit)
                   ->get();
    }

    public static function getRecommendedCategories($userId, $limit = 10)
    {
        // Basé sur les catégories similaires à celles que l'utilisateur aime
        $userInterests = self::where('user_id', $userId)
                           ->active()
                           ->highPriority()
                           ->pluck('category_id');

        if ($userInterests->isEmpty()) {
            // Si l'utilisateur n'a pas d'intérêts, retourner les catégories les plus populaires
            return Category::withCount('userInterests')
                           ->orderBy('user_interests_count', 'desc')
                           ->limit($limit)
                           ->get();
        }

        // Trouver des catégories similaires basées sur les utilisateurs avec les mêmes intérêts
        $similarUsers = self::whereIn('category_id', $userInterests)
                          ->where('user_id', '!=', $userId)
                          ->distinct('user_id')
                          ->pluck('user_id');

        $recommendedCategories = self::whereIn('user_id', $similarUsers)
                                   ->whereNotIn('category_id', $userInterests)
                                   ->active()
                                   ->groupBy('category_id')
                                   ->selectRaw('category_id, COUNT(*) as score')
                                   ->orderBy('score', 'desc')
                                   ->limit($limit)
                                   ->pluck('category_id');

        return Category::whereIn('id', $recommendedCategories)
                       ->get();
    }
}
