<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Product;
use App\Models\Category;
use App\Models\Shop;
use App\Models\ProductVariant;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        // Récupérer les catégories et boutiques EXISTANTES
        $categories = Category::all()->keyBy('id');
        $shops = Shop::all()->keyBy('id');

        // Identifiants nécessaires
        $requiredCategoryIds = [1, 2, 3, 4, 5, 6, 7];
        $requiredShopIds = [1, 2, 3, 4, 5, 6, 7, 8];

        $missingCategories = array_diff($requiredCategoryIds, $categories->keys()->toArray());
        $missingShops = array_diff($requiredShopIds, $shops->keys()->toArray());

        if (!empty($missingCategories)) {
            $this->command->error('❌ Catégories manquantes : ' . implode(', ', $missingCategories));
            $this->command->error('Veuillez exécuter CategorySeeder d’abord.');
            return;
        }

        if (!empty($missingShops)) {
            $this->command->error('❌ Boutiques manquantes : ' . implode(', ', $missingShops));
            $this->command->error('Veuillez exécuter ShopSeeder d’abord.');
            return;
        }

        // Liste complète des produits (telle que fournie)
        $products = [
            [
                'shop_id' => 1,
                'category_id' => 1,
                'name' => 'T-shirt Premium',
                'description' => 'T-shirt en coton de haute qualité, coupe moderne',
                'price' => 15000,
                'promotion_price' => 12000,
                'promotion_percentage' => 20,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(30),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'TSH-001',
            ],
            [
                'shop_id' => 1,
                'category_id' => 1,
                'name' => 'Jean Fashion',
                'description' => 'Jean denim slim fit, idéal pour toutes occasions',
                'price' => 25000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'JN-002',
            ],
            [
                'shop_id' => 1,
                'category_id' => 1,
                'name' => 'Robe Élégante',
                'description' => 'Robe longue en soie, parfaite pour les occasions spéciales',
                'price' => 45000,
                'promotion_price' => 40000,
                'promotion_percentage' => 11,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(15),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'ROB-003',
            ],
            [
                'shop_id' => 1,
                'category_id' => 1,
                'name' => 'Veste en Cuir',
                'description' => 'Veste en cuir véritable, style intemporel',
                'price' => 85000,
                'promotion_price' => 75000,
                'promotion_percentage' => 12,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(20),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'VEC-004',
            ],
            [
                'shop_id' => 1,
                'category_id' => 1,
                'name' => 'Sac à Main Luxe',
                'description' => 'Sac à main en cuir, design élégant',
                'price' => 35000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'SAM-005',
            ],
            [
                'shop_id' => 2,
                'category_id' => 2,
                'name' => 'Smartphone Pro',
                'description' => 'Smartphone dernière génération, écran 6.5 pouces',
                'price' => 150000,
                'promotion_price' => 135000,
                'promotion_percentage' => 10,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(45),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'SPH-006',
            ],
            [
                'shop_id' => 2,
                'category_id' => 2,
                'name' => 'Écouteurs Bluetooth',
                'description' => 'Écouteurs sans fil avec réduction de bruit',
                'price' => 25000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'ECO-007',
            ],
            [
                'shop_id' => 2,
                'category_id' => 2,
                'name' => 'Laptop Ultra',
                'description' => 'Laptop ultra léger, processeur dernière génération',
                'price' => 350000,
                'promotion_price' => 320000,
                'promotion_percentage' => 9,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(20),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'LAP-008',
            ],
            [
                'shop_id' => 2,
                'category_id' => 2,
                'name' => 'Tablette Pro',
                'description' => 'Tablette 10 pouces, parfaite pour le travail et le divertissement',
                'price' => 120000,
                'promotion_price' => 105000,
                'promotion_percentage' => 13,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(30),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'TAB-009',
            ],
            [
                'shop_id' => 2,
                'category_id' => 2,
                'name' => 'Montre Connectée',
                'description' => 'Smartwatch avec suivi fitness et notifications',
                'price' => 45000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'MTC-010',
            ],
            [
                'shop_id' => 3,
                'category_id' => 3,
                'name' => 'Crème Hydratante',
                'description' => 'Crème visage hydratante naturelle, 50ml',
                'price' => 12000,
                'promotion_price' => 10000,
                'promotion_percentage' => 17,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(25),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'CRE-011',
            ],
            [
                'shop_id' => 3,
                'category_id' => 3,
                'name' => 'Sérum Anti-âge',
                'description' => 'Sérum visage anti-âge, 30ml',
                'price' => 25000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'SER-012',
            ],
            [
                'shop_id' => 3,
                'category_id' => 3,
                'name' => 'Masque Visage',
                'description' => 'Masque visage en tissu, réutilisable',
                'price' => 8000,
                'promotion_price' => 6500,
                'promotion_percentage' => 19,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(10),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'MAS-013',
            ],
            [
                'shop_id' => 3,
                'category_id' => 3,
                'name' => 'Rouge à Lèvres',
                'description' => 'Rouge à lèvres longue tenue, couleur vibrante',
                'price' => 6500,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'ROL-014',
            ],
            [
                'shop_id' => 3,
                'category_id' => 3,
                'name' => 'Parfum Luxe',
                'description' => 'Parfum premium, notes florales et boisées',
                'price' => 45000,
                'promotion_price' => 38000,
                'promotion_percentage' => 16,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(40),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'PRF-015',
            ],
            [
                'shop_id' => 4,
                'category_id' => 5,
                'name' => 'Riz Premium',
                'description' => 'Riz de haute qualité, sac 25kg',
                'price' => 15000,
                'promotion_price' => 14000,
                'promotion_percentage' => 7,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(60),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'RIZ-016',
            ],
            [
                'shop_id' => 4,
                'category_id' => 5,
                'name' => 'Huile de Palme',
                'description' => 'Huile de palme pure, bidon 5L',
                'price' => 8000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'HUI-017',
            ],
            [
                'shop_id' => 4,
                'category_id' => 5,
                'name' => 'Pâtes alimentaires',
                'description' => 'Pâtes de qualité premium, paquet 500g',
                'price' => 1500,
                'promotion_price' => 1200,
                'promotion_percentage' => 20,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(15),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'PAS-018',
            ],
            [
                'shop_id' => 5,
                'category_id' => 4,
                'name' => 'Haltères Réglables',
                'description' => 'Set d\'haltères réglables 2-10kg',
                'price' => 35000,
                'promotion_price' => 30000,
                'promotion_percentage' => 14,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(25),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'HAL-019',
            ],
            [
                'shop_id' => 5,
                'category_id' => 4,
                'name' => 'Tapis de Yoga',
                'description' => 'Tapis de yoga antidérapant, épaisseur 6mm',
                'price' => 12000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'TAP-020',
            ],
            [
                'shop_id' => 5,
                'category_id' => 4,
                'name' => 'Chaussures Running',
                'description' => 'Chaussures de running légères et amortissantes',
                'price' => 45000,
                'promotion_price' => 40000,
                'promotion_percentage' => 11,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(30),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'CHA-021',
            ],
            [
                'shop_id' => 6,
                'category_id' => 5,
                'name' => 'Vase Décoratif',
                'description' => 'Vase en céramique moderne, design unique',
                'price' => 18000,
                'promotion_price' => 15000,
                'promotion_percentage' => 17,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(20),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'VAS-022',
            ],
            [
                'shop_id' => 6,
                'category_id' => 5,
                'name' => 'Lampe de Table',
                'description' => 'Lampe de table design moderne, LED',
                'price' => 25000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'LAM-023',
            ],
            [
                'shop_id' => 6,
                'category_id' => 5,
                'name' => 'Coussin Décoratif',
                'description' => 'Coussin décoratif en velours, 40x40cm',
                'price' => 8500,
                'promotion_price' => 7000,
                'promotion_percentage' => 18,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(15),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'COU-024',
            ],
            [
                'shop_id' => 7,
                'category_id' => 5,
                'name' => 'Jus d\'Orange Naturel',
                'description' => 'Jus d\'orange 100% naturel, bouteille 1L',
                'price' => 2500,
                'promotion_price' => 2000,
                'promotion_percentage' => 20,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(10),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'JUS-025',
            ],
            [
                'shop_id' => 7,
                'category_id' => 5,
                'name' => 'Pain Complet',
                'description' => 'Pain complet frais, 500g',
                'price' => 1500,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'PAN-026',
            ],
            [
                'shop_id' => 8,
                'category_id' => 7,
                'name' => 'Roman Best-seller',
                'description' => 'Roman captivant, best-seller international',
                'price' => 12000,
                'promotion_price' => 10000,
                'promotion_percentage' => 17,
                'promotion_start' => now(),
                'promotion_end' => now()->addDays(30),
                'in_promotion' => true,
                'is_active' => true,
                'sku' => 'ROM-027',
            ],
            [
                'shop_id' => 8,
                'category_id' => 7,
                'name' => 'Livre de Cuisine',
                'description' => 'Livre de recettes gastronomiques',
                'price' => 18000,
                'promotion_price' => null,
                'promotion_percentage' => null,
                'promotion_start' => null,
                'promotion_end' => null,
                'in_promotion' => false,
                'is_active' => true,
                'sku' => 'LIV-028',
            ],
        ];

        foreach ($products as $productData) {
            // Vérification finale de l'existence de la boutique et catégorie
            if (!$shops->has($productData['shop_id'])) {
                $this->command->warn("Boutique id={$productData['shop_id']} manquante, produit ignoré : {$productData['name']}");
                continue;
            }
            if (!$categories->has($productData['category_id'])) {
                $this->command->warn("Catégorie id={$productData['category_id']} manquante, produit ignoré : {$productData['name']}");
                continue;
            }

            // Générer 1 à 3 images
            $images = [];
            $numImages = rand(1, 3);
            for ($i = 0; $i < $numImages; $i++) {
                $imagePath = $this->downloadProductImage($productData['name'], $i);
                if ($imagePath) {
                    $images[] = $imagePath;
                }
            }

            // Ajouter les images au produit
            $productData['images'] = json_encode($images);

            // Éviter les doublons par SKU
            Product::updateOrCreate(
                ['sku' => $productData['sku']],
                $productData
            );
        }

        // Créer les variantes pour certains produits
        $this->createProductVariants();

        $this->command->info('✅ Produits créés avec succès avec leurs images et variantes !');
    }

    /**
     * Télécharger et sauvegarder une image depuis picsum.photos
     */
    private function downloadProductImage(string $productName, int $index): ?string
    {
        $directory = 'products';
        if (!Storage::disk('public')->exists($directory)) {
            Storage::disk('public')->makeDirectory($directory);
        }

        $cleanName = Str::slug($productName, '_');
        $fileName = $cleanName . '_' . time() . '_' . $index . '_' . rand(1000, 9999) . '.jpg';
        $filePath = $directory . '/' . $fileName;

        // Mapping d'IDs d'images par type de produit
        $productImageIds = [
            't-shirt' => [100, 101, 102, 103],
            'jean' => [104, 105, 106, 107],
            'robe' => [108, 109, 110, 111],
            'veste' => [112, 113, 114, 115],
            'sac' => [116, 117, 118, 119],
            'smartphone' => [26, 27, 28, 29],
            'écouteurs' => [113, 114, 115, 116],
            'laptop' => [117, 118, 119, 120],
            'tablette' => [121, 122, 123, 124],
            'montre' => [125, 126, 127, 128],
            'crème' => [119, 120, 121, 122],
            'sérum' => [123, 124, 125, 126],
            'masque' => [127, 128, 129, 130],
            'rouge' => [131, 132, 133, 134],
            'parfum' => [135, 136, 137, 138],
            'riz' => [139, 140, 141, 142],
            'huile' => [143, 144, 145, 146],
            'pâtes' => [147, 148, 149, 150],
            'haltères' => [151, 152, 153, 154],
            'tapis' => [155, 156, 157, 158],
            'chaussures' => [159, 160, 161, 162],
            'vase' => [163, 164, 165, 166],
            'lampe' => [167, 168, 169, 170],
            'coussin' => [171, 172, 173, 174],
            'jus' => [175, 176, 177, 178],
            'pain' => [179, 180, 181, 182],
            'roman' => [183, 184, 185, 186],
            'livre' => [187, 188, 189, 190],
        ];

        // Déterminer le type de produit basé sur le nom
        $productType = 'default';
        foreach ($productImageIds as $key => $ids) {
            if (str_contains(Str::lower($productName), $key)) {
                $productType = $key;
                break;
            }
        }

        $ids = $productImageIds[$productType] ?? [1, 2, 3, 4, 5];
        $randomId = $ids[array_rand($ids)];
        $imageUrl = "https://picsum.photos/id/{$randomId}/800/600.jpg";

        try {
            $response = Http::timeout(10)->get($imageUrl);
            if ($response->successful()) {
                Storage::disk('public')->put($filePath, $response->body());
                return '/storage/' . $filePath;
            }
        } catch (\Exception $e) {
            $this->command->warn("Impossible de télécharger l'image pour {$productName}: " . $e->getMessage());
        }

        return null;
    }

    /**
     * Créer des variantes pour les produits (sans gestion de stock)
     */
    private function createProductVariants(): void
    {
        // Récupérer les produits
        $tshirt = Product::where('sku', 'TSH-001')->first();
        $jean = Product::where('sku', 'JN-002')->first();
        $smartphone = Product::where('sku', 'SPH-006')->first(); // SKU corrigé

        // Variantes pour le T-shirt
        if ($tshirt) {
            $variants = [
                ['size' => 'S', 'color' => 'Blanc', 'material' => 'Coton', 'sku' => 'TSH-001-S-BLANC', 'price_adjustment' => 0],
                ['size' => 'M', 'color' => 'Blanc', 'material' => 'Coton', 'sku' => 'TSH-001-M-BLANC', 'price_adjustment' => 0],
                ['size' => 'L', 'color' => 'Blanc', 'material' => 'Coton', 'sku' => 'TSH-001-L-BLANC', 'price_adjustment' => 0],
                ['size' => 'M', 'color' => 'Noir', 'material' => 'Coton', 'sku' => 'TSH-001-M-NOIR', 'price_adjustment' => 0],
                ['size' => 'L', 'color' => 'Noir', 'material' => 'Coton', 'sku' => 'TSH-001-L-NOIR', 'price_adjustment' => 0],
                ['size' => 'XL', 'color' => 'Noir', 'material' => 'Coton', 'sku' => 'TSH-001-XL-NOIR', 'price_adjustment' => 0],
            ];

            foreach ($variants as $variant) {
                $variant['product_id'] = $tshirt->id;
                ProductVariant::firstOrCreate(['sku' => $variant['sku']], $variant);
            }
        }

        // Variantes pour le Jean
        if ($jean) {
            $variants = [
                ['size' => '30', 'color' => 'Bleu', 'material' => 'Denim', 'sku' => 'JN-002-30-BLEU', 'price_adjustment' => 0],
                ['size' => '32', 'color' => 'Bleu', 'material' => 'Denim', 'sku' => 'JN-002-32-BLEU', 'price_adjustment' => 0],
                ['size' => '34', 'color' => 'Bleu', 'material' => 'Denim', 'sku' => 'JN-002-34-BLEU', 'price_adjustment' => 0],
                ['size' => '32', 'color' => 'Noir', 'material' => 'Denim', 'sku' => 'JN-002-32-NOIR', 'price_adjustment' => 0],
            ];

            foreach ($variants as $variant) {
                $variant['product_id'] = $jean->id;
                ProductVariant::firstOrCreate(['sku' => $variant['sku']], $variant);
            }
        }

        // Variantes pour le Smartphone
        if ($smartphone) {
            $variants = [
                ['color' => 'Noir', 'sku' => 'SPH-006-NOIR', 'price_adjustment' => 0],
                ['color' => 'Blanc', 'sku' => 'SPH-006-BLANC', 'price_adjustment' => 0],
                ['color' => 'Bleu', 'sku' => 'SPH-006-BLEU', 'price_adjustment' => 5000],
            ];

            foreach ($variants as $variant) {
                $variant['product_id'] = $smartphone->id;
                ProductVariant::firstOrCreate(['sku' => $variant['sku']], $variant);
            }
        }
    }
}