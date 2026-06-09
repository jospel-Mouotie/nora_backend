<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Video;
use App\Models\User;
use App\Models\Shop;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class VideoSeeder extends Seeder
{
    public function run(): void
    {
        // Créer les dossiers
        if (!Storage::disk('public')->exists('videos')) {
            Storage::disk('public')->makeDirectory('videos');
        }
        if (!Storage::disk('public')->exists('videos/thumbnails')) {
            Storage::disk('public')->makeDirectory('videos/thumbnails');
        }

        // Seule URL fiable et fonctionnelle
        $videoSource = 'https://www.w3schools.com/html/mov_bbb.mp4';

        // Récupérer les utilisateurs
        $client = User::where('email', 'marie@client.com')->first();
        $merchant = User::where('email', 'jean@shop.com')->first();
        $wholesaler = User::where('email', 'sophie@grossiste.com')->first();

        $fashionShop = Shop::where('name', 'Fashion Store')->first();
        $techShop = Shop::where('name', 'Tech Hub')->first();
        $beautyShop = Shop::where('name', 'Beauty Corner')->first();
        $grossisteShop = Shop::where('name', 'Grossiste Pro')->first();

        $videos = [
            // Fashion Store - 4 vidéos
            [
                'user_id' => $merchant?->id,
                'shop_id' => $fashionShop?->id,
                'title' => 'Nouvelle Collection Printemps',
                'description' => 'Découvrez notre nouvelle collection de printemps avec des couleurs vibrantes.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $merchant?->id,
                'shop_id' => $fashionShop?->id,
                'title' => 'Comment porter un jean',
                'description' => 'Astuces pour choisir la bonne taille de jean.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $merchant?->id,
                'shop_id' => $fashionShop?->id,
                'title' => 'Tendances Mode 2024',
                'description' => 'Les tendances incontournables de l\'année.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $merchant?->id,
                'shop_id' => $fashionShop?->id,
                'title' => 'Accessoires indispensables',
                'description' => 'Les accessoires qui font la différence.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],

            // Tech Hub - 4 vidéos
            [
                'user_id' => $merchant?->id,
                'shop_id' => $techShop?->id,
                'title' => 'Unboxing Smartphone Pro',
                'description' => 'Découverte du nouveau Smartphone Pro.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $merchant?->id,
                'shop_id' => $techShop?->id,
                'title' => 'Test Écouteurs Bluetooth',
                'description' => 'Comparatif des meilleurs écouteurs.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $merchant?->id,
                'shop_id' => $techShop?->id,
                'title' => 'Présentation PC Gamer',
                'description' => 'Le PC ultime pour les gamers.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $merchant?->id,
                'shop_id' => $techShop?->id,
                'title' => 'Accessoires High-Tech',
                'description' => 'Les gadgets qui vont vous simplifier la vie.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],

            // Beauty Corner - 3 vidéos
            [
                'user_id' => $merchant?->id,
                'shop_id' => $beautyShop?->id,
                'title' => 'Routine Beauté Matin',
                'description' => 'Ma routine beauté simple et rapide.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $merchant?->id,
                'shop_id' => $beautyShop?->id,
                'title' => 'Tutoriel Maquillage Naturel',
                'description' => 'Un maquillage frais pour le quotidien.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $merchant?->id,
                'shop_id' => $beautyShop?->id,
                'title' => 'Soin du Visage Complet',
                'description' => 'Les étapes pour une peau parfaite.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],

            // Grossiste Pro - 2 vidéos
            [
                'user_id' => $wholesaler?->id,
                'shop_id' => $grossisteShop?->id,
                'title' => 'Produits Alimentaires Premium',
                'description' => 'Découvrez notre gamme de produits.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $wholesaler?->id,
                'shop_id' => $grossisteShop?->id,
                'title' => 'Offres Grossistes',
                'description' => 'Des prix imbattables pour les revendeurs.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],

            // Clients - 5 vidéos
            [
                'user_id' => $client?->id,
                'title' => 'Look du Jour',
                'description' => 'Ma tenue préférée de la collection.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $client?->id,
                'title' => 'Unboxing Fashion Store',
                'description' => 'Je reçois ma commande !',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $client?->id,
                'title' => 'Vlog Shopping Douala',
                'description' => 'Journée shopping dans les boutiques.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $client?->id,
                'title' => 'Beauty Corner Review',
                'description' => 'Mon avis sur les produits Beauty Corner.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
            [
                'user_id' => $client?->id,
                'title' => 'Tech Haul',
                'description' => 'Je présente mes nouveaux gadgets.',
                'resolution' => '1920x1080',
                'duration_seconds' => 32,
            ],
        ];

        $successCount = 0;

        foreach ($videos as $index => $videoData) {
            $this->command->info("📹 Vidéo " . ($index + 1) . "/" . count($videos) . " : " . $videoData['title']);

            // Générer des noms de fichiers
            $slug = Str::slug($videoData['title'], '_');
            $uniqueId = time() . '_' . $index . '_' . rand(1000, 9999);
            $videoFileName = $slug . '_' . $uniqueId . '.mp4';
            $videoFilePath = 'videos/' . $videoFileName;
            $fullVideoPath = storage_path('app/public/' . $videoFilePath);

            // Télécharger la vidéo
            try {
                $ch = curl_init();
                curl_setopt($ch, CURLOPT_URL, $videoSource);
                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
                curl_setopt($ch, CURLOPT_TIMEOUT, 30);
                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

                $content = curl_exec($ch);
                $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                curl_close($ch);

                if ($httpCode === 200 && $content && strlen($content) > 5000) {
                    file_put_contents($fullVideoPath, $content);
                    $fileSizeMB = round(filesize($fullVideoPath) / 1024 / 1024, 2);
                    $this->command->info("    ✅ Vidéo téléchargée ({$fileSizeMB} MB)");
                } else {
                    $this->command->warn("    ❌ Échec téléchargement (HTTP {$httpCode})");
                    continue;
                }
            } catch (\Exception $e) {
                $this->command->warn("    ❌ Erreur: " . $e->getMessage());
                continue;
            }

            // Générer une miniature
            $thumbnailFileName = $slug . '_thumb_' . $uniqueId . '.jpg';
            $thumbnailFilePath = 'videos/thumbnails/' . $thumbnailFileName;
            $fullThumbPath = storage_path('app/public/' . $thumbnailFilePath);
            $thumbnailPath = $this->generateThumbnail($fullThumbPath, $index);

            // Créer la vidéo en base
            try {
                $video = Video::create([
                    'title' => $videoData['title'],
                    'description' => $videoData['description'],
                    'video_path' => '/storage/' . $videoFilePath,
                    'thumbnail_path' => $thumbnailPath ? '/storage/' . $thumbnailFilePath : null,
                    'status' => 'ready',
                    'duration_seconds' => $videoData['duration_seconds'],
                    'resolution' => $videoData['resolution'],
                    'file_size_mb' => $fileSizeMB ?? 5.5,
                    'format' => 'mp4',
                    'is_public' => true,
                    'allow_comments' => true,
                    'allow_downloads' => false,
                    'published_at' => now()->subDays(rand(0, 30)),
                    'user_id' => $videoData['user_id'],
                    'shop_id' => $videoData['shop_id'] ?? null,
                    'metadata' => json_encode([
                        'source' => 'w3schools',
                        'codec' => 'h264',
                        'fps' => 30,
                    ]),
                ]);

                $this->command->info("    ✅ Vidéo créée (ID: {$video->id})");
                $successCount++;

            } catch (\Exception $e) {
                $this->command->error("    ❌ Erreur DB: " . $e->getMessage());
            }

            // Petit délai pour éviter la surcharge
            usleep(300000);
        }

        $this->command->newLine();
        $this->command->info("═══════════════════════════════════════════════════════════");
        $this->command->info("🎉 RÉSUMÉ: {$successCount}/" . count($videos) . " vidéos créées");
        $this->command->info("═══════════════════════════════════════════════════════════");
    }

    private function generateThumbnail(string $fullPath, int $index): ?string
    {
        $imageIds = [100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110];
        $randomId = $imageIds[$index % count($imageIds)];
        $imageUrl = "https://picsum.photos/id/{$randomId}/800/600.jpg";

        try {
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $imageUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 15);

            $content = curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($httpCode === 200 && $content) {
                file_put_contents($fullPath, $content);
                $this->command->info("    🖼️ Miniature générée");
                return $fullPath;
            }
        } catch (\Exception $e) {
            // Ignorer
        }

        return null;
    }
}
