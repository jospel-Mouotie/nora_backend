<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Video;
use App\Models\VideoLike;
use App\Models\VideoComment;
use App\Models\VideoView;
use App\Models\User;

class VideoInteractionSeeder extends Seeder
{
    public function run(): void
    {
        $videos = Video::all()->keyBy('id');
        $users = User::all()->keyBy('id');

        // Créer les likes pour les vidéos
        $likes = [
            [
                'user_id' => 3, // Marie Cliente
                'video_id' => 1, // Nouvelle Collection Printemps
                'created_at' => now()->subDays(2)->subHours(6),
                'updated_at' => now()->subDays(2)->subHours(6),
            ],
            [
                'user_id' => 3,
                'video_id' => 2, // Unboxing Smartphone Pro
                'created_at' => now()->subDays(1)->subHours(12),
                'updated_at' => now()->subDays(1)->subHours(12),
            ],
            [
                'user_id' => 3,
                'video_id' => 3, // Look du Jour
                'created_at' => now()->subDays(1)->subHours(3),
                'updated_at' => now()->subDays(1)->subHours(3),
            ],
            [
                'user_id' => 2, // Jean Commerçant
                'video_id' => 1,
                'created_at' => now()->subDays(3)->subHours(8),
                'updated_at' => now()->subDays(3)->subHours(8),
            ],
            [
                'user_id' => 2,
                'video_id' => 2,
                'created_at' => now()->subDays(2)->subHours(15),
                'updated_at' => now()->subDays(2)->subHours(15),
            ],
            [
                'user_id' => 2,
                'video_id' => 4, // Tutoriel Style Jean
                'created_at' => now()->subHours(20),
                'updated_at' => now()->subHours(20),
            ],
            [
                'user_id' => 2,
                'video_id' => 5, // Comparatif Écouteurs
                'created_at' => now()->subHours(10),
                'updated_at' => now()->subHours(10),
            ],
            [
                'user_id' => 2,
                'video_id' => 6, // Behind the Scenes
                'created_at' => now()->subHours(5),
                'updated_at' => now()->subHours(5),
            ],
            [
                'user_id' => 3,
                'video_id' => 7, // Routine Beauté Matin
                'created_at' => now()->subHours(8),
                'updated_at' => now()->subHours(8),
            ],
        ];

        foreach ($likes as $like) {
            VideoLike::create($like);
        }

        // Créer les commentaires pour les vidéos
        $comments = [
            [
                'user_id' => 3, // Marie Cliente
                'video_id' => 1, // Nouvelle Collection Printemps
                'content' => 'Superbe collection ! J\'adore les couleurs 🌸',
                'created_at' => now()->subDays(2)->subHours(5),
                'updated_at' => now()->subDays(2)->subHours(5),
            ],
            [
                'user_id' => 2, // Jean Commerçant
                'video_id' => 1,
                'content' => 'Merci pour le soutien ! La collection est magnifique ✨',
                'created_at' => now()->subDays(3)->subHours(7),
                'updated_at' => now()->subDays(3)->subHours(7),
            ],
            [
                'user_id' => 3,
                'video_id' => 2, // Unboxing Smartphone Pro
                'content' => 'J\'adore ce téléphone ! Est-ce que la batterie tient vraiment 5000mAh ? 🔋',
                'created_at' => now()->subDays(1)->subHours(10),
                'updated_at' => now()->subDays(1)->subHours(10),
            ],
            [
                'user_id' => 3,
                'video_id' => 3, // Look du Jour
                'content' => 'Très jolie tenue ! Où as-tu acheté le t-shirt ?',
                'created_at' => now()->subDays(1)->subHours(2),
                'updated_at' => now()->subDays(1)->subHours(2),
            ],
            [
                'user_id' => 2,
                'video_id' => 4, // Tutoriel Style Jean
                'content' => 'Excellent tutoriel ! J\'ai appris plein de choses 🙏',
                'created_at' => now()->subHours(18),
                'updated_at' => now()->subHours(18),
            ],
            [
                'user_id' => 3,
                'video_id' => 7, // Routine Beauté Matin
                'content' => 'Merci pour les astuces ! Je vais essayer cette routine 💕',
                'created_at' => now()->subHours(6),
                'updated_at' => now()->subHours(6),
            ],
            [
                'user_id' => 3,
                'video_id' => 1, // Nouvelle Collection Printemps
                'content' => 'Les tissus sont magnifiques ! Quelle est la composition ? 🧵',
                'created_at' => now()->subDays(2)->subHours(3),
                'updated_at' => now()->subDays(2)->subHours(3),
            ],
            [
                'user_id' => 2,
                'video_id' => 5, // Comparatif Écouteurs
                'content' => 'Très bon comparatif ! Les AirPods sont vraiment en tête 👂',
                'created_at' => now()->subHours(8),
                'updated_at' => now()->subHours(8),
            ],
            [
                'user_id' => 3,
                'video_id' => 3, // Look du Jour
                'content' => 'Le t-shirt est de Fashion Store, je l\'ai acheté hier !',
                'created_at' => now()->subDays(1)->subHours(1),
                'updated_at' => now()->subDays(1)->subHours(1),
            ],
        ];

        foreach ($comments as $comment) {
            VideoComment::create($comment);
        }

        // Créer les vues pour les vidéos (plusieurs vues par vidéo)
        $views = [];
        $userIds = $users->keys()->toArray();
        
        // Vidéo 1 : Nouvelle Collection Printemps (500 vues)
        for ($i = 0; $i < 500; $i++) {
            $views[] = [
                'video_id' => 1,
                'user_id' => $userIds[array_rand($userIds)], // Utilisateurs aléatoires
                'watch_duration_seconds' => rand(10, 30), // Durée de visionnage en secondes
                'counted_as_view' => true,
                'created_at' => now()->subDays(rand(1, 7))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
                'updated_at' => now()->subDays(rand(1, 7))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
            ];
        }

        // Vidéo 2 : Unboxing Smartphone Pro (350 vues)
        for ($i = 0; $i < 350; $i++) {
            $views[] = [
                'video_id' => 2,
                'user_id' => $userIds[array_rand($userIds)],
                'watch_duration_seconds' => rand(15, 45),
                'counted_as_view' => true,
                'created_at' => now()->subDays(rand(1, 6))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
                'updated_at' => now()->subDays(rand(1, 6))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
            ];
        }

        // Vidéo 3 : Look du Jour (150 vues)
        for ($i = 0; $i < 150; $i++) {
            $views[] = [
                'video_id' => 3,
                'user_id' => $userIds[array_rand($userIds)],
                'watch_duration_seconds' => rand(5, 25),
                'counted_as_view' => true,
                'created_at' => now()->subDays(rand(1, 5))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
                'updated_at' => now()->subDays(rand(1, 5))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
            ];
        }

        // Vidéo 4 : Tutoriel Style Jean (280 vues)
        for ($i = 0; $i < 280; $i++) {
            $views[] = [
                'video_id' => 4,
                'user_id' => $userIds[array_rand($userIds)],
                'watch_duration_seconds' => rand(20, 60),
                'counted_as_view' => true,
                'created_at' => now()->subDays(rand(1, 4))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
                'updated_at' => now()->subDays(rand(1, 4))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
            ];
        }

        // Vidéo 5 : Comparatif Écouteurs (420 vues)
        for ($i = 0; $i < 420; $i++) {
            $views[] = [
                'video_id' => 5,
                'user_id' => $userIds[array_rand($userIds)],
                'watch_duration_seconds' => rand(10, 40),
                'counted_as_view' => true,
                'created_at' => now()->subDays(rand(1, 3))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
                'updated_at' => now()->subDays(rand(1, 3))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
            ];
        }

        // Vidéo 6 : Behind the Scenes (95 vues)
        for ($i = 0; $i < 95; $i++) {
            $views[] = [
                'video_id' => 6,
                'user_id' => $userIds[array_rand($userIds)],
                'watch_duration_seconds' => rand(8, 30),
                'counted_as_view' => true,
                'created_at' => now()->subDays(rand(1, 2))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
                'updated_at' => now()->subDays(rand(1, 2))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
            ];
        }

        // Vidéo 7 : Routine Beauté Matin (180 vues)
        for ($i = 0; $i < 180; $i++) {
            $views[] = [
                'video_id' => 7,
                'user_id' => $userIds[array_rand($userIds)],
                'watch_duration_seconds' => rand(12, 35),
                'counted_as_view' => true,
                'created_at' => now()->subDays(rand(1, 2))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
                'updated_at' => now()->subDays(rand(1, 2))->subHours(rand(1, 23))->subMinutes(rand(1, 59)),
            ];
        }

        foreach ($views as $view) {
            VideoView::create($view);
        }

        $this->command->info('✅ Interactions vidéos créées avec succès !');
        $this->command->info('👍 Likes totaux : ' . count($likes));
        $this->command->info('💬 Commentaires totaux : ' . count($comments));
        $this->command->info('👀 Vues totales : ' . count($views));
    }
}
