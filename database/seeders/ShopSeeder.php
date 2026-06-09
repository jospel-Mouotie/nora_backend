<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Shop;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;

class ShopSeeder extends Seeder
{
    public function run(): void
    {
        $shops = [
            [
                'user_id' => 2, // Jean Commerçant
                'name' => 'Fashion Store',
                'description' => 'Boutique de mode tendance avec les dernières collections',
                'address' => 'Douala, Bonanjo',
                'phone' => '+237233456789',
                'email' => 'contact@fashionstore.com',
                'status' => 'active',
                'certifiee' => true,
                'certifiee_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 2,
                'name' => 'Tech Hub',
                'description' => 'Spécialiste en électronique et gadgets',
                'address' => 'Yaoundé, Centre Ville',
                'phone' => '+237233456790',
                'email' => 'contact@techhub.com',
                'status' => 'active',
                'certifiee' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 2,
                'name' => 'Beauty Corner',
                'description' => 'Produits de beauté et soins naturels',
                'address' => 'Bafoussam, Marché Central',
                'phone' => '+237233456791',
                'email' => 'contact@beautycorner.com',
                'status' => 'active',
                'certifiee' => true,
                'certifiee_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 4, // Sophie Grossiste
                'name' => 'Grossiste Pro',
                'description' => 'Fournisseur en gros pour tous types de produits',
                'address' => 'Douala, Akwa',
                'phone' => '+237233456792',
                'email' => 'contact@grossistepro.com',
                'status' => 'active',
                'certifiee' => true,
                'certifiee_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 2,
                'name' => 'Sport Zone',
                'description' => 'Équipements sportifs et vêtements de performance',
                'address' => 'Douala, Bonapriso',
                'phone' => '+237233456793',
                'email' => 'contact@sportzone.com',
                'status' => 'active',
                'certifiee' => true,
                'certifiee_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 2,
                'name' => 'Home Décor',
                'description' => 'Décoration intérieure et mobilier moderne',
                'address' => 'Yaoundé, Bastos',
                'phone' => '+237233456794',
                'email' => 'contact@homedecor.com',
                'status' => 'active',
                'certifiee' => false,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 4,
                'name' => 'Alimentaire Plus',
                'description' => 'Produits alimentaires frais et épicerie',
                'address' => 'Douala, Marché Central',
                'phone' => '+237233456795',
                'email' => 'contact@alimentaireplus.com',
                'status' => 'active',
                'certifiee' => true,
                'certifiee_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 2,
                'name' => 'Book World',
                'description' => 'Librairie avec livres pour tous les goûts',
                'address' => 'Douala, Akwa',
                'phone' => '+237233456796',
                'email' => 'contact@bookworld.com',
                'status' => 'active',
                'certifiee' => true,
                'certifiee_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($shops as $shopData) {
            // Générer une image pour la boutique
            $photoPath = $this->generateShopImage($shopData['name']);
            
            // Ajouter le chemin de la photo aux données
            $shopData['photo'] = $photoPath;
            
            Shop::create($shopData);
        }

        $this->command->info('✅ Boutiques créées avec succès avec leurs images !');
    }
    
    /**
     * Générer une image pour une boutique
     */
    private function generateShopImage(string $shopName): ?string
    {
        // Créer le dossier s'il n'existe pas
        $directory = 'shops';
        if (!Storage::disk('public')->exists($directory)) {
            Storage::disk('public')->makeDirectory($directory);
        }
        
        // Nettoyer le nom de la boutique pour le fichier
        $cleanName = strtolower(preg_replace('/[^a-z0-9]+/i', '_', $shopName));
        $fileName = $cleanName . '_' . time() . '_' . rand(1000, 9999) . '.jpg';
        $filePath = $directory . '/' . $fileName;
        
        // Mapping des mots-clés par boutique
        $keywords = [
            'Fashion Store' => 'fashion,clothing,store',
            'Tech Hub' => 'technology,electronics,store',
            'Beauty Corner' => 'beauty,cosmetics,store',
            'Grossiste Pro' => 'wholesale,warehouse,store',
            'Sport Zone' => 'sports,fitness,store',
            'Home Décor' => 'home,decoration,furniture',
            'Alimentaire Plus' => 'food,grocery,market',
            'Book World' => 'books,library,reading'
        ];
        
        $keyword = $keywords[$shopName] ?? 'shop,store';
        
        try {
            // Option 1: Utiliser Lorem Picsum avec des images spécifiques par boutique
            $imageIds = [
                'Fashion Store' => [100, 101, 102, 103], // IDs pour images de mode
                'Tech Hub' => [26, 27, 28, 29], // IDs pour images tech
                'Beauty Corner' => [30, 31, 32, 33], // IDs pour images beauté
                'Grossiste Pro' => [34, 35, 36, 37], // IDs pour images grossiste
                'Sport Zone' => [33, 34, 35, 36], // IDs pour images sport
                'Home Décor' => [36, 37, 38, 39], // IDs pour images décoration
                'Alimentaire Plus' => [39, 40, 41, 42], // IDs pour images alimentaire
                'Book World' => [42, 43, 44, 45] // IDs pour images livres
            ];
            
            $ids = $imageIds[$shopName] ?? [1, 2, 3, 4];
            $randomId = $ids[array_rand($ids)];
            
            // Images de qualité depuis Lorem Picsum
            $imageUrl = "https://picsum.photos/id/{$randomId}/800/600.jpg";
            
            // Option 2: Utiliser Unsplash avec des mots-clés (décommentez si besoin)
            // $imageUrl = "https://source.unsplash.com/800x600/?" . urlencode($keyword);
            
            // Option 3: Utiliser Placekitten (toujours disponible)
            // $imageUrl = "https://placekitten.com/800/600";
            
            $response = Http::timeout(10)->get($imageUrl);
            
            if ($response->successful()) {
                Storage::disk('public')->put($filePath, $response->body());
                return '/storage/' . $filePath;
            }
        } catch (\Exception $e) {
            $this->command->warn("Impossible de télécharger l'image pour {$shopName}: " . $e->getMessage());
        }
        
        return null;
    }
}