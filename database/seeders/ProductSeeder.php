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
        // 1. S'assurer que les catégories nécessaires existent
        $requiredCategories = [
            1 => ['name' => 'Mode', 'slug' => 'mode'],
            2 => ['name' => 'Électronique', 'slug' => 'electronique'],
            3 => ['name' => 'Beauté', 'slug' => 'beaute'],
            4 => ['name' => 'Sports', 'slug' => 'sports'],
            5 => ['name' => 'Alimentation', 'slug' => 'alimentation'],
            6 => ['name' => 'Maison', 'slug' => 'maison'],
            7 => ['name' => 'Livres', 'slug' => 'livres'],
        ];
        foreach ($requiredCategories as $id => $data) {
            Category::firstOrCreate(
                ['id' => $id],
                ['name' => $data['name'], 'slug' => $data['slug'], 'is_active' => true]
            );
        }

        // 2. S'assurer que les boutiques nécessaires existent
        // Remplacez les user_id par des IDs d'utilisateurs réels de votre système
        $requiredShops = [
            1 => ['name' => 'Fashion Store', 'description' => 'Vêtements tendance', 'user_id' => 1],
            2 => ['name' => 'Tech Hub', 'description' => 'High-tech & gadgets', 'user_id' => 2],
            3 => ['name' => 'Beauty Corner', 'description' => 'Cosmétiques naturels', 'user_id' => 3],
            4 => ['name' => 'Grossiste Pro', 'description' => 'Produits en gros', 'user_id' => 4],
            5 => ['name' => 'Sport Zone', 'description' => 'Équipements sportifs', 'user_id' => 5],
            6 => ['name' => 'Home Décor', 'description' => 'Décoration intérieure', 'user_id' => 6],
            7 => ['name' => 'Alimentaire Plus', 'description' => 'Épicerie fine', 'user_id' => 7],
            8 => ['name' => 'Book World', 'description' => 'Librairie en ligne', 'user_id' => 8],
        ];
        foreach ($requiredShops as $id => $data) {
            Shop::firstOrCreate(
                ['id' => $id],
                [
                    'name' => $data['name'],
                    'description' => $data['description'],
                    'user_id' => $data['user_id'],
                    'is_active' => true,
                    'is_verified' => true,
                ]
            );
        }

        // 3. Définition des produits (conservez votre tableau complet)
        $products = [
            // ... (tous vos produits, je ne les recopie pas pour la lisibilité)
            // Utilisez celui que vous avez déjà.
        ];

        // 4. Insertion des produits avec images
        foreach ($products as $productData) {
            $images = [];
            $numImages = rand(1, 3);
            for ($i = 0; $i < $numImages; $i++) {
                $imagePath = $this->downloadProductImage($productData['name'], $i);
                if ($imagePath) {
                    $images[] = $imagePath;
                } else {
                    $fallback = $this->getFallbackImage($i);
                    if ($fallback) $images[] = $fallback;
                }
            }
            $productData['images'] = json_encode($images);

            Product::updateOrCreate(
                ['sku' => $productData['sku']],
                $productData
            );
        }

        // 5. Création des variantes (sans stock)
        $this->createProductVariants();

        $this->command->info('✅ Produits créés avec succès avec leurs images et variantes !');
    }

    private function downloadProductImage(string $productName, int $index): ?string
    {
        $directory = 'products';
        if (!Storage::disk('public')->exists($directory)) {
            Storage::disk('public')->makeDirectory($directory);
        }

        $cleanName = Str::slug($productName, '_');
        $fileName = $cleanName . '_' . time() . '_' . $index . '_' . rand(1000, 9999) . '.jpg';
        $filePath = $directory . '/' . $fileName;

        $productImageIds = [
            't-shirt' => [100, 101, 102, 103],
            'jean' => [104, 105, 106, 107],
            'robe' => [108, 109, 110, 111],
            'veste' => [112, 113, 114, 115],
            'sac' => [116, 117, 118, 119],
            'smartphone' => [26, 27, 28, 29],
            'ecouteurs' => [113, 114, 115, 116],
            'laptop' => [117, 118, 119, 120],
            'tablette' => [121, 122, 123, 124],
            'montre' => [125, 126, 127, 128],
            'creme' => [119, 120, 121, 122],
            'serum' => [123, 124, 125, 126],
            'masque' => [127, 128, 129, 130],
            'rouge' => [131, 132, 133, 134],
            'parfum' => [135, 136, 137, 138],
            'riz' => [139, 140, 141, 142],
            'huile' => [143, 144, 145, 146],
            'pates' => [147, 148, 149, 150],
            'halteres' => [151, 152, 153, 154],
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

        for ($attempt = 1; $attempt <= 3; $attempt++) {
            try {
                $response = Http::timeout(15)->get($imageUrl);
                if ($response->successful()) {
                    Storage::disk('public')->put($filePath, $response->body());
                    return '/storage/' . $filePath;
                }
            } catch (\Exception $e) {
                $this->command->warn("Tentative $attempt échouée pour {$productName} : " . $e->getMessage());
                if ($attempt === 3) return null;
                sleep(1);
            }
        }
        return null;
    }

    private function getFallbackImage(int $index): ?string
    {
        $fallbackPath = 'products/fallback_' . $index . '.jpg';
        if (!Storage::disk('public')->exists($fallbackPath)) {
            $defaultImage = public_path('images/product-placeholder.jpg');
            if (file_exists($defaultImage)) {
                Storage::disk('public')->put($fallbackPath, file_get_contents($defaultImage));
                return '/storage/' . $fallbackPath;
            }
            return null;
        }
        return '/storage/' . $fallbackPath;
    }

    private function createProductVariants(): void
    {
        $tshirt = Product::where('sku', 'TSH-001')->first();
        $jean = Product::where('sku', 'JN-002')->first();
        $smartphone = Product::where('sku', 'SPH-006')->first(); // SKU corrigé

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