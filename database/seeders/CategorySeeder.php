<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            [
                'name' => 'Mode',
                'icon' => 'fas fa-tshirt',
                'description' => 'Vêtements et accessoires de mode',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Vêtements Hommes',
                        'icon' => 'fas fa-male',
                        'description' => 'T-shirts, chemises, pantalons, costumes pour hommes',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Vêtements Femmes',
                        'icon' => 'fas fa-female',
                        'description' => 'Robes, jupes, blouses, vestes pour femmes',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Chaussures',
                        'icon' => 'fas fa-shoe-prints',
                        'description' => 'Baskets, chaussures de ville, sandales, bottes',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Accessoires',
                        'icon' => 'fas fa-gem',
                        'description' => 'Sacs, ceintures, chapeaux, bijoux',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Enfants',
                        'icon' => 'fas fa-child',
                        'description' => 'Vêtements et accessoires pour enfants',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Électronique',
                'icon' => 'fas fa-laptop',
                'description' => 'Appareils électroniques et gadgets',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Smartphones',
                        'icon' => 'fas fa-mobile-alt',
                        'description' => 'Téléphones intelligents et accessoires',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Ordinateurs',
                        'icon' => 'fas fa-desktop',
                        'description' => 'Laptops, desktops et périphériques',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Audio',
                        'icon' => 'fas fa-headphones',
                        'description' => 'Écouteurs, casques, enceintes',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Accessoires Tech',
                        'icon' => 'fas fa-plug',
                        'description' => 'Chargeurs, câbles, batteries externes',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Gaming',
                        'icon' => 'fas fa-gamepad',
                        'description' => 'Consoles, jeux, accessoires gaming',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Beauté',
                'icon' => 'fas fa-spa',
                'description' => 'Produits de beauté et soins',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Maquillage',
                        'icon' => 'fas fa-paint-brush',
                        'description' => 'Fond de teint, rouge à lèvres, mascara',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Soin du Visage',
                        'icon' => 'fas fa-smile',
                        'description' => 'Crèmes, sérums, masques visage',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Soin des Cheveux',
                        'icon' => 'fas fa-cut',
                        'description' => 'Shampoings, après-shampoings, huiles',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Parfums',
                        'icon' => 'fas fa-leaf',
                        'description' => 'Parfums et eaux de toilette',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Hygiène',
                        'icon' => 'fas fa-hand-holding-heart',
                        'description' => 'Savons, gels douche, déodorants',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Sports',
                'icon' => 'fas fa-football-ball',
                'description' => 'Équipements et vêtements de sport',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Vêtements de Sport',
                        'icon' => 'fas fa-tshirt',
                        'description' => 'T-shirts, shorts, leggings de sport',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Chaussures de Sport',
                        'icon' => 'fas fa-running',
                        'description' => 'Running, fitness, basket',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Fitness',
                        'icon' => 'fas fa-dumbbell',
                        'description' => 'Accessoires de musculation, tapis',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Sports d\'Équipe',
                        'icon' => 'fas fa-futbol',
                        'description' => 'Ballons, protections, maillots',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Outdoor',
                        'icon' => 'fas fa-mountain',
                        'description' => 'Camping, randonnée, escalade',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Maison',
                'icon' => 'fas fa-home',
                'description' => 'Articles pour la maison et décoration',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Décoration',
                        'icon' => 'fas fa-palette',
                        'description' => 'Tableaux, vases, objets décoratifs',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Mobilier',
                        'icon' => 'fas fa-couch',
                        'description' => 'Canapés, tables, chaises, armoires',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Cuisine',
                        'icon' => 'fas fa-utensils',
                        'description' => 'Ustensiles, électroménager, vaisselle',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Literie',
                        'icon' => 'fas fa-bed',
                        'description' => 'Draps, couettes, oreillers',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Jardin',
                        'icon' => 'fas fa-seedling',
                        'description' => 'Outils de jardin, plantes, mobilier extérieur',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Alimentation',
                'icon' => 'fas fa-utensils',
                'description' => 'Produits alimentaires et boissons',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Épicerie Sucrée',
                        'icon' => 'fas fa-candy-cane',
                        'description' => 'Biscuits, chocolats, bonbons',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Épicerie Salée',
                        'icon' => 'fas fa-cheese',
                        'description' => 'Pâtes, riz, conserves, sauces',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Boissons',
                        'icon' => 'fas fa-wine-bottle',
                        'description' => 'Jus, sodas, eaux, boissons alcoolisées',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Produits Frais',
                        'icon' => 'fas fa-apple-alt',
                        'description' => 'Fruits, légumes, produits laitiers',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Bio',
                        'icon' => 'fas fa-seedling',
                        'description' => 'Produits biologiques et naturels',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Livres',
                'icon' => 'fas fa-book',
                'description' => 'Livres et matériel éducatif',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Romans',
                        'icon' => 'fas fa-book-open',
                        'description' => 'Romans, nouvelles, littérature',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Scolaire',
                        'icon' => 'fas fa-graduation-cap',
                        'description' => 'Manuels, cahiers, fournitures',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'BD et Mangas',
                        'icon' => 'fas fa-comic',
                        'description' => 'Bandes dessinées, mangas, comics',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Cuisine',
                        'icon' => 'fas fa-utensils',
                        'description' => 'Livres de recettes et gastronomie',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Développement Personnel',
                        'icon' => 'fas fa-brain',
                        'description' => 'Psychologie, bien-être, réussite',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Jeux',
                'icon' => 'fas fa-gamepad',
                'description' => 'Jeux vidéo et consoles',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Consoles',
                        'icon' => 'fas fa-gamepad',
                        'description' => 'PlayStation, Xbox, Nintendo Switch',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Jeux PC',
                        'icon' => 'fas fa-desktop',
                        'description' => 'Jeux sur PC, codes de téléchargement',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Jeux Console',
                        'icon' => 'fas fa-disc',
                        'description' => 'Jeux physiques pour consoles',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Accessoires Gaming',
                        'icon' => 'fas fa-mouse',
                        'description' => 'Manettes, casques, claviers gaming',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Jeux de Société',
                        'icon' => 'fas fa-chess-board',
                        'description' => 'Jeux de plateau, cartes, puzzles',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Santé',
                'icon' => 'fas fa-heartbeat',
                'description' => 'Produits de santé et bien-être',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Compléments Alimentaires',
                        'icon' => 'fas fa-capsules',
                        'description' => 'Vitamines, minéraux, protéines',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Bien-être',
                        'icon' => 'fas fa-spa',
                        'description' => 'Méditation, relaxation, aromathérapie',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Orthopédie',
                        'icon' => 'fas fa-bone',
                        'description' => 'Supports, attelles, orthèses',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Hygiène',
                        'icon' => 'fas fa-hand-holding-heart',
                        'description' => 'Produits d\'hygiène et soins corporels',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Médicaments',
                        'icon' => 'fas fa-tablets',
                        'description' => 'Médicaments en vente libre',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Automobile',
                'icon' => 'fas fa-car',
                'description' => 'Accessoires et pièces automobiles',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Pièces Auto',
                        'icon' => 'fas fa-cogs',
                        'description' => 'Moteur, freins, filtres, bougies',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Accessoires Intérieur',
                        'icon' => 'fas fa-chair',
                        'description' => 'Housses, tapis, volants, GPS',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Entretien',
                        'icon' => 'fas fa-oil-can',
                        'description' => 'Huiles, liquides, produits d\'entretien',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Pneus',
                        'icon' => 'fas fa-circle',
                        'description' => 'Pneus toutes saisons, jantes',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Outillage',
                        'icon' => 'fas fa-tools',
                        'description' => 'Outils mécaniques et de diagnostic',
                        'is_active' => true,
                    ],
                ],
            ],
            [
                'name' => 'Art',
                'icon' => 'fas fa-palette',
                'description' => 'Oeuvres d\'art et matériel artistique',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
                'subcategories' => [
                    [
                        'name' => 'Peinture',
                        'icon' => 'fas fa-paintbrush',
                        'description' => 'Peintures acryliques, huiles, aquarelles',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Dessin',
                        'icon' => 'fas fa-pencil-alt',
                        'description' => 'Crayons, fusains, pastels, carnets',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Sculpture',
                        'icon' => 'fas fa-cube',
                        'description' => 'Argile, outils de sculpture',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Toiles et Supports',
                        'icon' => 'fas fa-border-all',
                        'description' => 'Toiles, papiers, cartons',
                        'is_active' => true,
                    ],
                    [
                        'name' => 'Créativité',
                        'icon' => 'fas fa-star',
                        'description' => 'Scrapbooking, DIY, loisirs créatifs',
                        'is_active' => true,
                    ],
                ],
            ],
        ];

        foreach ($categories as $categoryData) {
            // Extraire les sous-catégories
            $subcategories = $categoryData['subcategories'] ?? [];
            unset($categoryData['subcategories']);
            
            // Générer une image pour la catégorie principale
            $imagePath = $this->generateCategoryImage($categoryData['name']);
            $categoryData['image'] = $imagePath;
            
            // Créer la catégorie principale
            $category = Category::create($categoryData);
            
            // Ajouter les sous-catégories
            foreach ($subcategories as $subData) {
                // Générer une image pour la sous-catégorie
                $subImagePath = $this->generateSubcategoryImage($category->name, $subData['name']);
                $subData['image'] = $subImagePath;
                $subData['parent_id'] = $category->id;
                
                // Générer un slug unique en incluant le parent
                $subData['slug'] = Str::slug($category->name . '-' . $subData['name']);
                
                Category::create($subData);
            }
            
            $this->command->info("✅ Catégorie '{$category->name}' et ses sous-catégories créées avec succès !");
        }

        $this->command->info('✅ Toutes les catégories et sous-catégories ont été créées avec leurs images !');
    }
    
    /**
     * Générer une image pour une catégorie
     */
    private function generateCategoryImage(string $categoryName): ?string
    {
        // Créer le dossier s'il n'existe pas
        $directory = 'categories';
        if (!Storage::disk('public')->exists($directory)) {
            Storage::disk('public')->makeDirectory($directory);
        }
        
        // Nettoyer le nom pour le fichier
        $cleanName = strtolower(preg_replace('/[^a-z0-9]+/i', '_', $categoryName));
        $fileName = $cleanName . '_' . time() . '_' . rand(1000, 9999) . '.jpg';
        $filePath = $directory . '/' . $fileName;
        
        // Mapping des IDs d'images par catégorie
        $imageIds = [
            'Mode' => [100, 101, 102],
            'Électronique' => [26, 27, 28],
            'Beauté' => [30, 31, 32],
            'Sports' => [33, 34, 35],
            'Maison' => [36, 37, 38],
            'Alimentation' => [39, 40, 41],
            'Livres' => [42, 43, 44],
            'Jeux' => [45, 46, 47],
            'Santé' => [48, 49, 50],
            'Automobile' => [51, 52, 53],
            'Art' => [54, 55, 56],
        ];
        
        $ids = $imageIds[$categoryName] ?? [1, 2, 3];
        $randomId = $ids[array_rand($ids)];
        
        try {
            $imageUrl = "https://picsum.photos/id/{$randomId}/800/600.jpg";
            
            $response = Http::timeout(10)->get($imageUrl);
            
            if ($response->successful()) {
                Storage::disk('public')->put($filePath, $response->body());
                return '/storage/' . $filePath;
            }
        } catch (\Exception $e) {
            $this->command->warn("Impossible de télécharger l'image pour {$categoryName}: " . $e->getMessage());
        }
        
        return null;
    }
    
    /**
     * Générer une image pour une sous-catégorie
     */
    private function generateSubcategoryImage(string $parentName, string $subName): ?string
    {
        // Créer le dossier s'il n'existe pas
        $directory = 'categories/subcategories';
        if (!Storage::disk('public')->exists($directory)) {
            Storage::disk('public')->makeDirectory($directory);
        }
        
        // Nettoyer les noms pour le fichier
        $cleanParent = strtolower(preg_replace('/[^a-z0-9]+/i', '_', $parentName));
        $cleanSub = strtolower(preg_replace('/[^a-z0-9]+/i', '_', $subName));
        $fileName = $cleanParent . '_' . $cleanSub . '_' . time() . '_' . rand(1000, 9999) . '.jpg';
        $filePath = $directory . '/' . $fileName;
        
        // Mapping des IDs d'images par sous-catégorie
        $subImageIds = [
            'Vêtements Hommes' => 100,
            'Vêtements Femmes' => 101,
            'Chaussures' => 102,
            'Smartphones' => 110,
            'Ordinateurs' => 116,
            'Audio' => 113,
            'Maquillage' => 119,
            'Soin du Visage' => 120,
            'Parfums' => 30,
        ];
        
        $imageId = $subImageIds[$subName] ?? rand(1, 100);
        
        try {
            $imageUrl = "https://picsum.photos/id/{$imageId}/800/600.jpg";
            
            $response = Http::timeout(10)->get($imageUrl);
            
            if ($response->successful()) {
                Storage::disk('public')->put($filePath, $response->body());
                return '/storage/' . $filePath;
            }
        } catch (\Exception $e) {
            $this->command->warn("Impossible de télécharger l'image pour {$subName}");
        }
        
        return null;
    }
}