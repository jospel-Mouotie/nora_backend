<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $users = [
            [
                'name' => 'Admin Nora',
                'email' => 'admin@nora.com',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'phone' => '+237123456789',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Jean Commerçant',
                'email' => 'jean@shop.com',
                'password' => Hash::make('password'),
                'role' => 'commercant',
                'phone' => '+237123456780',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Marie Cliente',
                'email' => 'marie@client.com',
                'password' => Hash::make('password'),
                'role' => 'client',
                'phone' => '+237123456781',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Paul Livreur',
                'email' => 'paul@delivery.com',
                'password' => Hash::make('password'),
                'role' => 'livreur',
                'phone' => '+237123456782',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Sophie Grossiste',
                'email' => 'sophie@grosiste.com',
                'password' => Hash::make('password'),
                'role' => 'grossiste',
                'phone' => '+237123456783',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($users as $userData) {
            // Générer une photo de profil
            $profilePhoto = $this->generateUserProfilePhoto($userData['name'], $userData['role']);
            $userData['profile_photo'] = $profilePhoto;
            
            User::create($userData);
        }

        $this->command->info('✅ Utilisateurs créés avec succès avec leurs photos de profil !');
    }

    /**
     * Générer une photo de profil pour un utilisateur
     */
    private function generateUserProfilePhoto(string $userName, string $role): ?string
    {
        // Créer le dossier s'il n'existe pas
        $directory = 'users/profiles';
        if (!Storage::disk('public')->exists($directory)) {
            Storage::disk('public')->makeDirectory($directory);
        }
        
        // Nettoyer le nom pour le fichier
        $cleanName = strtolower(preg_replace('/[^a-z0-9]+/i', '_', $userName));
        $fileName = $cleanName . '_' . time() . '_' . rand(1000, 9999) . '.jpg';
        $filePath = $directory . '/' . $fileName;
        
        // Mapping des IDs d'images par rôle
        $profileImageIds = [
            'admin' => [64, 65, 66],
            'commercant' => [67, 68, 69, 70],
            'client' => [71, 72, 73, 74, 75],
            'livreur' => [76, 77, 78],
            'grossiste' => [79, 80, 81],
        ];
        
        $ids = $profileImageIds[$role] ?? [1, 2, 3, 4, 5];
        $randomId = $ids[array_rand($ids)];
        
        try {
            // Utiliser des images de portraits depuis Lorem Picsum
            $imageUrl = "https://picsum.photos/id/{$randomId}/400/400.jpg";
            
            $response = Http::timeout(10)->get($imageUrl);
            
            if ($response->successful()) {
                Storage::disk('public')->put($filePath, $response->body());
                return '/storage/' . $filePath;
            }
        } catch (\Exception $e) {
            $this->command->warn("Impossible de télécharger la photo pour {$userName}: " . $e->getMessage());
        }
        
        return null;
    }
}
