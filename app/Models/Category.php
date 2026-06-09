<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Category extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'description',
        'image',
        'is_active',
        'sort_order',
        'parent_id',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($category) {
            if (empty($category->slug)) {
                $category->slug = Str::slug($category->name);
            }
        });

        static::updating(function ($category) {
            if ($category->isDirty('name') && empty($category->slug)) {
                $category->slug = Str::slug($category->name);
            }
        });
    }

    // Relation avec la catégorie parente
    public function parent()
    {
        return $this->belongsTo(Category::class, 'parent_id');
    }

    // Relation avec les sous-catégories (enfants)
    public function children()
    {
        return $this->hasMany(Category::class, 'parent_id');
    }

    // Relation avec tous les descendants (récursif)
    public function descendants()
    {
        return $this->children()->with('descendants');
    }

    // Relation avec les produits
    public function products()
    {
        return $this->hasMany(Product::class);
    }

    // Relation avec les intérêts des utilisateurs
    public function userInterests()
    {
        return $this->hasMany(UserInterest::class);
    }

    public function interestedUsers()
    {
        return $this->belongsToMany(User::class, 'user_interests')
                    ->withPivot(['priority_level', 'is_active', 'selected_at'])
                    ->withTimestamps();
    }

    // Scope pour les catégories actives
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeEnAttente($query)
    {
        return $query->where('status', 'en_attente');
    }

    public function getInterestCountAttribute()
    {
        return $this->userInterests()->active()->count();
    }

    public function getHighInterestCountAttribute()
    {
        return $this->userInterests()->active()->highPriority()->count();
    }

    public function isPopular()
    {
        return $this->getInterestCountAttribute() >= 10;
    }

    public function getPopularityScoreAttribute()
    {
        $totalInterests = $this->getInterestCountAttribute();
        $highInterests = $this->getHighInterestCountAttribute();
        
        // Score basé sur le nombre total et le niveau d'intérêt
        return ($totalInterests * 1) + ($highInterests * 3);
    }

    // Scope pour les catégories racines (sans parent)
    public function scopeRoot($query)
    {
        return $query->whereNull('parent_id');
    }

    // Scope pour les catégories enfants
    public function scopeChildren($query, $parentId)
    {
        return $query->where('parent_id', $parentId);
    }

    // Vérifier si c'est une catégorie racine
    public function isRoot()
    {
        return is_null($this->parent_id);
    }

    // Vérifier si c'est une feuille (pas d'enfants)
    public function isLeaf()
    {
        return $this->children()->count() === 0;
    }

    // Obtenir le chemin complet de la catégorie (ex: Vêtements > Hommes > T-shirts)
    public function getFullPath()
    {
        $path = [];
        $current = $this;
        
        while ($current) {
            array_unshift($path, $current->name);
            $current = $current->parent;
        }
        
        return implode(' > ', $path);
    }

    // Obtenir tous les IDs des descendants (pour les requêtes de produits)
    public function getDescendantIds()
    {
        $ids = [$this->id];
        
        foreach ($this->children as $child) {
            $ids = array_merge($ids, $child->getDescendantIds());
        }
        
        return $ids;
    }

    // Obtenir l'arborescence complète
    public static function getTree()
    {
        return static::with(['children' => function($query) {
            $query->active()->orderBy('sort_order');
        }])
        ->root()
        ->active()
        ->orderBy('sort_order')
        ->get();
    }

    // Obtenir les options pour un select (format hiérarchique)
    public static function getSelectOptions($prefix = '')
    {
        $options = [];
        
        foreach (static::root()->active()->orderBy('sort_order')->get() as $category) {
            $options[$category->id] = $prefix . $category->name;
            $options = array_merge($options, $category->getChildOptions($prefix . '── '));
        }
        
        return $options;
    }

    // Méthode récursive pour les options enfants
    private function getChildOptions($prefix = '')
    {
        $options = [];
        
        foreach ($this->children()->active()->orderBy('sort_order')->get() as $child) {
            $options[$child->id] = $prefix . $child->name;
            $options = array_merge($options, $child->getChildOptions($prefix . '── '));
        }
        
        return $options;
    }
}
