<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Shop;
use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\VariantStock;
use App\Models\Video;
use App\Models\UserInterest;
use App\Models\UserHabitTracker;
use App\Models\MBReward;
use App\Models\MBShop;
use App\Models\MBShopItem;
use App\Models\MBCoin;
use App\Models\MBCoinTransaction;
use App\Models\MBShopPurchase;
use App\Models\ShopFollower;
use App\Models\ShopLike;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Delivery;
use App\Models\Message;
use App\Models\AdminChat;
use App\Models\Ad;
use App\Models\AdCampaign;
use Database\Seeders\VideoSeeder;
use Database\Seeders\VideoInteractionSeeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Désactiver les contraintes de clés étrangères
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        // Vider les tables
        $this->truncateTables();

        // Créer les données de base en utilisant les seeders individuels
        $this->call([
            UserSeeder::class,
            CategorySeeder::class,
            ShopSeeder::class,
            ProductSeeder::class,
            VideoSeeder::class,
            VideoInteractionSeeder::class,
        ]);

        // Données supplémentaires
        $this->seedUserInterests();
        $this->seedUserHabits();
        // $this->seedMBSystem(); // Commenté car les tables MB n'existent pas encore
        // $this->seedMBCoins(); // Commenté car les tables MB n'existent pas encore
        $this->seedShopInteractions();
        $this->seedOrders();
        $this->seedDeliveries();
        $this->seedChats();
        $this->seedAds();

        // Réactiver les contraintes de clés étrangères
        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        $this->command->info('Base de données remplie avec succès !');
    }

    private function truncateTables(): void
    {
        $existingTables = [
            'messages', 'deliveries',
            'order_items', 'orders',
            'shop_likes', 'shop_followers',
            'm_b_shop_items', 'm_b_shops', 'mb_rewards', 'm_b_coin_transactions', 'm_b_coins',
            'videos', 'video_views', 'video_likes', 'video_comments',
            'variant_stocks', 'product_variants', 'products',
            'shops', 'categories', 'users',
            'admin_chats', 'ad_campaigns', 'ads',
            'user_interests', 'user_habit_trackers'
        ];

        foreach ($existingTables as $table) {
            try {
                DB::table($table)->truncate();
            } catch (\Exception $e) {
                $this->command->warn("Table $table does not exist or could not be truncated");
            }
        }
    }

    private function seedUsers(): void
    {
        // Utilisateurs de test
        $users = [
            [
                'name' => 'Admin Nora',
                'email' => 'admin@nora.com',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Jean Commerçant',
                'email' => 'jean@shop.com',
                'password' => Hash::make('password'),
                'role' => 'commercant',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Marie Cliente',
                'email' => 'marie@client.com',
                'password' => Hash::make('password'),
                'role' => 'client',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'name' => 'Paul Livreur',
                'email' => 'paul@delivery.com',
                'password' => Hash::make('password'),
                'role' => 'livreur',
                'email_verified_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($users as $user) {
            User::create($user);
        }

        $this->command->info('✅ Utilisateurs créés');
    }

    private function seedCategories(): void
    {
        $categories = [
            ['name' => 'Mode', 'icon' => 'fas fa-tshirt', 'description' => 'Vêtements et accessoires de mode'],
            ['name' => 'Électronique', 'icon' => 'fas fa-laptop', 'description' => 'Appareils électroniques et gadgets'],
            ['name' => 'Beauté', 'icon' => 'fas fa-spa', 'description' => 'Produits de beauté et soins'],
            ['name' => 'Sports', 'icon' => 'fas fa-football-ball', 'description' => 'Équipements et vêtements de sport'],
            ['name' => 'Maison', 'icon' => 'fas fa-home', 'description' => 'Articles pour la maison et décoration'],
            ['name' => 'Alimentation', 'icon' => 'fas fa-utensils', 'description' => 'Produits alimentaires et boissons'],
            ['name' => 'Livres', 'icon' => 'fas fa-book', 'description' => 'Livres et matériel éducatif'],
            ['name' => 'Jeux', 'icon' => 'fas fa-gamepad', 'description' => 'Jeux vidéo et consoles'],
            ['name' => 'Santé', 'icon' => 'fas fa-heartbeat', 'description' => 'Produits de santé et bien-être'],
            ['name' => 'Automobile', 'icon' => 'fas fa-car', 'description' => 'Accessoires et pièces automobiles'],
            ['name' => 'Art', 'icon' => 'fas fa-palette', 'description' => 'Oeuvres d\'art et matériel artistique'],
        ];

        foreach ($categories as $category) {
            Category::create(array_merge($category, [
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]));
        }

        $this->command->info('✅ Catégories créées');
    }

    private function seedShops(): void
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
        ];

        foreach ($shops as $shop) {
            Shop::create($shop);
        }

        $this->command->info('✅ Boutiques créées');
    }

    private function seedProducts(): void
    {
        $products = [
            [
                'shop_id' => 1, // Fashion Store
                'category_id' => 1, // Mode
                'name' => 'T-shirt Premium',
                'description' => 'T-shirt en coton de haute qualité, coupe moderne',
                'price' => 15000,
                'promotion_price' => 20000,
                'promotion_percentage' => 25,
                'in_promotion' => true,
                'sku' => 'TSHIRT-PREM-001',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'shop_id' => 1,
                'category_id' => 1,
                'name' => 'Jean Fashion',
                'description' => 'Jean denim slim fit, idéal pour toutes occasions',
                'price' => 25000,
                'promotion_price' => 30000,
                'promotion_percentage' => 17,
                'in_promotion' => true,
                'sku' => 'JEAN-FASH-002',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'shop_id' => 2, // Tech Hub
                'category_id' => 2, // Électronique
                'name' => 'Smartphone Pro',
                'description' => 'Smartphone dernière génération, écran 6.5 pouces',
                'price' => 150000,
                'promotion_price' => 180000,
                'promotion_percentage' => 17,
                'in_promotion' => true,
                'sku' => 'SMART-PRO-003',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'shop_id' => 2,
                'category_id' => 2,
                'name' => 'Écouteurs Bluetooth',
                'description' => 'Écouteurs sans fil avec réduction de bruit',
                'price' => 25000,
                'promotion_price' => 35000,
                'promotion_percentage' => 29,
                'in_promotion' => true,
                'sku' => 'ECOUT-BLU-004',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'shop_id' => 3, // Beauty Corner
                'category_id' => 3, // Beauté
                'name' => 'Crème Hydratante',
                'description' => 'Crème visage hydratante naturelle, 50ml',
                'price' => 12000,
                'promotion_price' => 15000,
                'promotion_percentage' => 20,
                'in_promotion' => true,
                'sku' => 'CREAM-HYD-005',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($products as $product) {
            Product::create($product);
        }

        $this->command->info('✅ Produits créés');
    }

    private function seedVideos(): void
    {
        $this->call(VideoSeeder::class);
    }

    private function seedVideoInteractions(): void
    {
        $this->call(VideoInteractionSeeder::class);
    }

    private function seedUserInterests(): void
    {
        $interests = [
            [
                'user_id' => 3, // Marie Cliente
                'category_id' => 1, // Mode
                'priority_level' => 5, // Passionné
                'is_active' => true,
                'selected_at' => now(),
                'metadata' => ['preferences' => ['casual', 'formal']],
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 3,
                'category_id' => 3, // Beauté
                'priority_level' => 4, // Très intéressé
                'is_active' => true,
                'selected_at' => now(),
                'metadata' => ['preferences' => ['naturel', 'bio']],
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 3,
                'category_id' => 2, // Électronique
                'priority_level' => 3, // Intéressé
                'is_active' => true,
                'selected_at' => now(),
                'metadata' => ['preferences' => ['smartphone', 'accessoires']],
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($interests as $interest) {
            UserInterest::create($interest);
        }

        $this->command->info('✅ Centres d\'intérêt créés');
    }

    private function seedUserHabits(): void
    {
        $habits = [
            [
                'user_id' => 3, // Marie Cliente
                'action_type' => 'view',
                'entity_type' => 'product',
                'entity_id' => 1, // T-shirt Premium
                'metadata' => ['source' => 'recommended_products', 'position' => 1],
                'action_time' => now()->subMinutes(30),
                'session_id' => 'session_123',
                'ip_address' => '192.168.1.1',
                'user_agent' => 'Mozilla/5.0...',
                'context' => ['page' => 'home', 'section' => 'personalized_feed'],
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 3,
                'action_type' => 'search',
                'entity_type' => 'product',
                'entity_id' => 'robe soirée',
                'metadata' => ['query' => 'robe soirée', 'results_count' => 15],
                'action_time' => now()->subHours(2),
                'session_id' => 'session_123',
                'ip_address' => '192.168.1.1',
                'user_agent' => 'Mozilla/5.0...',
                'context' => ['page' => 'search'],
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 3,
                'action_type' => 'purchase',
                'entity_type' => 'product',
                'entity_id' => 1, // T-shirt Premium
                'metadata' => ['order_id' => 'ORDER_001', 'amount' => 15000],
                'action_time' => now()->subDays(1),
                'session_id' => 'session_123',
                'ip_address' => '192.168.1.1',
                'user_agent' => 'Mozilla/5.0...',
                'context' => ['page' => 'checkout'],
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($habits as $habit) {
            UserHabitTracker::create($habit);
        }

        $this->command->info('✅ Habitudes utilisateur créées');
    }

    private function seedMBSystem(): void
    {
        // MB Rewards
        $rewards = [
            [
                'user_id' => 3, // Marie Cliente
                'title' => 'Bonus Inscription',
                'description' => 'Bonus offert lors de l\'inscription',
                'type' => 'special',
                'amount' => 1000,
                'is_claimed' => true,
                'claimed_at' => now(),
                'expires_at' => now()->addMonths(6),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 3,
                'title' => 'Bonus Vidéo',
                'description' => 'Bonus pour avoir regardé une vidéo',
                'type' => 'video_view',
                'amount' => 500,
                'is_claimed' => true,
                'claimed_at' => now(),
                'expires_at' => now()->addMonths(3),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($rewards as $reward) {
            MBReward::create($reward);
        }

        // MB Shop
        $mbShop = [
            'name' => 'MB Boutique Exclusive',
            'description' => 'Boutique avec produits exclusifs payables en MB Coins',
            'status' => 'active',
            'is_featured' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ];

        MBShop::create($mbShop);

        // MB Shop Items
        $shopItems = [
            [
                'mb_shop_id' => 1,
                'name' => 'Bon de Réduction 10%',
                'description' => 'Bon de réduction de 10% valable sur tous les produits',
                'type' => 'voucher',
                'price_mb_coins' => 5000,
                'is_active' => true,
                'stock' => 100,
                'metadata' => ['discount_percentage' => 10, 'max_discount' => 5000],
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'mb_shop_id' => 1,
                'name' => 'Livraison Gratuite',
                'description' => 'Livraison gratuite pour votre prochaine commande',
                'type' => 'subscription',
                'price_mb_coins' => 3000,
                'is_active' => true,
                'stock' => 50,
                'metadata' => ['max_shipping_cost' => 2000],
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($shopItems as $item) {
            MBShopItem::create($item);
        }

        $this->command->info('✅ Système MB Coins créé');
    }

    private function seedShopInteractions(): void
    {
        // Shop Followers
        $followers = [
            [
                'user_id' => 3, // Marie Cliente
                'shop_id' => 1, // Fashion Store
                'created_at' => now()->subDays(5),
                'updated_at' => now()->subDays(5),
            ],
            [
                'user_id' => 3,
                'shop_id' => 3, // Beauty Corner
                'created_at' => now()->subDays(3),
                'updated_at' => now()->subDays(3),
            ],
        ];

        foreach ($followers as $follower) {
            ShopFollower::create($follower);
        }

        // Shop Likes
        $likes = [
            [
                'user_id' => 3,
                'shop_id' => 2, // Tech Hub
                'created_at' => now()->subDays(2),
                'updated_at' => now()->subDays(2),
            ],
        ];

        foreach ($likes as $like) {
            ShopLike::create($like);
        }

        $this->command->info('✅ Interactions boutiques créées');
    }

    private function seedOrders(): void
    {
        $orders = [
            [
                'order_number' => 'ORD-001',
                'user_id' => 3, // Marie Cliente
                'shop_id' => 1, // Fashion Store
                'total_amount' => 15000,
                'promotion_discount' => 0,
                'delivery_fee' => 0,
                'final_amount' => 15000,
                'pin' => '123456',
                'qr_code' => 'QR_ORDER_001',
                'status' => 'delivered',
                'payment_status' => 'paid',
                'delivery_address' => 'Douala, Bonanjo, Rue 123',
                'created_at' => now()->subDays(1),
                'updated_at' => now(),
            ],
        ];

        foreach ($orders as $order) {
            Order::create($order);
        }

        // Order Items
        $orderItems = [
            [
                'order_id' => 1,
                'product_variant_id' => 1, // Premier variant du produit 1
                'quantity' => 1,
                'unit_price' => 15000,
                'total_price' => 15000,
                'promotion_discount' => 0,
                'created_at' => now()->subDays(1),
                'updated_at' => now(),
            ],
        ];

        foreach ($orderItems as $item) {
            OrderItem::create($item);
        }

        $this->command->info('✅ Commandes créées');
    }

    private function seedDeliveries(): void
    {
        $deliveries = [
            [
                'order_id' => 1,
                'delivery_user_id' => 4, // Paul Livreur
                'status' => 'delivered',
                'pickup_address' => 'Douala, Bonanjo, Fashion Store',
                'delivery_address' => 'Douala, Bonanjo, Rue 123',
                'pickup_time' => now()->subDays(1)->subHours(2),
                'delivery_time' => now()->subDays(1)->addHours(1),
                'created_at' => now()->subDays(1),
                'updated_at' => now(),
            ],
        ];

        foreach ($deliveries as $delivery) {
            Delivery::create($delivery);
        }

        $this->command->info('✅ Livraisons créées');
    }

    private function seedChats(): void
    {
        // Admin Chat
        $adminChats = [
            [
                'user_id' => 3, // Marie Cliente
                'title' => 'Question sur ma commande',
                'status' => 'closed',
                'created_at' => now()->subHours(6),
                'updated_at' => now()->subHours(4),
            ],
        ];

        foreach ($adminChats as $chat) {
            AdminChat::create($chat);
        }

        // Admin Messages
        $adminMessages = [
            [
                'admin_chat_id' => 1,
                'sender_type' => 'user',
                'sender_id' => 3,
                'message' => 'Bonjour, je voudrais savoir où en est ma commande',
                'is_read' => true,
                'created_at' => now()->subHours(6),
                'updated_at' => now()->subHours(6),
            ],
            [
                'admin_chat_id' => 1,
                'sender_type' => 'admin',
                'sender_id' => 1,
                'message' => 'Bonjour Marie, votre commande a été livrée hier. Tout s\'est bien passé !',
                'is_read' => true,
                'created_at' => now()->subHours(5),
                'updated_at' => now()->subHours(5),
            ],
        ];

        foreach ($adminMessages as $message) {
            Message::create($message);
        }

        $this->command->info('✅ Chats créés');
    }

    private function seedAds(): void
    {
        // Ad Campaigns
        $campaigns = [
            [
                'name' => 'Campagne Printemps',
                'description' => 'Campagne publicitaire pour le printemps',
                'start_date' => now()->subDays(7),
                'end_date' => now()->addDays(7),
                'budget' => 100000,
                'is_active' => true,
                'created_at' => now()->subDays(7),
                'updated_at' => now(),
            ],
        ];

        foreach ($campaigns as $campaign) {
            AdCampaign::create($campaign);
        }

        // Ads
        $ads = [
            [
                'shop_id' => 1, // Fashion Store
                'campaign_id' => 1,
                'title' => 'Collection Printemps -30%',
                'description' => 'Découvrez notre nouvelle collection avec -30% de réduction',
                'image_url' => 'https://example.com/ad1.jpg',
                'target_url' => 'https://nora.com/shop/fashion-store',
                'type' => 'banner',
                'position' => 'top',
                'is_active' => true,
                'start_date' => now()->subDays(7),
                'end_date' => now()->addDays(7),
                'created_at' => now()->subDays(7),
                'updated_at' => now(),
            ],
        ];

        foreach ($ads as $ad) {
            Ad::create($ad);
        }

        $this->command->info('✅ Publicités créées');
    }

    private function seedMBCoins(): void
    {
        // Créer les comptes MB Coins pour chaque utilisateur
        $mbCoins = [
            [
                'user_id' => 1, // Admin Nora
                'balance' => 10000,
                'total_earned' => 15000,
                'total_spent' => 5000,
                'total_withdrawn' => 0,
                'is_active' => true,
                'last_earned_at' => now()->subHours(2),
                'last_spent_at' => now()->subDays(1),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 2, // Jean Commerçant
                'balance' => 7500,
                'total_earned' => 10000,
                'total_spent' => 2500,
                'total_withdrawn' => 0,
                'is_active' => true,
                'last_earned_at' => now()->subHours(5),
                'last_spent_at' => now()->subDays(2),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 3, // Marie Cliente
                'balance' => 5200,
                'total_earned' => 8000,
                'total_spent' => 2800,
                'total_withdrawn' => 0,
                'is_active' => true,
                'last_earned_at' => now()->subMinutes(30),
                'last_spent_at' => now()->subHours(6),
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'user_id' => 4, // Paul Livreur
                'balance' => 3000,
                'total_earned' => 5000,
                'total_spent' => 2000,
                'total_withdrawn' => 0,
                'is_active' => true,
                'last_earned_at' => now()->subHours(8),
                'last_spent_at' => now()->subDays(3),
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ];

        foreach ($mbCoins as $mbCoin) {
            MBCoin::create($mbCoin);
        }

        // Créer quelques transactions d'exemple
        $transactions = [
            [
                'mb_coin_id' => 1, // Admin
                'amount' => 1000,
                'type' => 'credit',
                'description' => 'Bonus inscription',
                'source' => 'signup',
                'balance_after' => 10000,
                'is_verified' => true,
                'verified_at' => now(),
                'created_at' => now()->subDays(7),
                'updated_at' => now()->subDays(7),
            ],
            [
                'mb_coin_id' => 3, // Marie
                'amount' => 500,
                'type' => 'credit',
                'description' => 'Like sur vidéo',
                'source' => 'video_like',
                'source_id' => '1',
                'balance_after' => 5200,
                'is_verified' => true,
                'verified_at' => now(),
                'created_at' => now()->subMinutes(30),
                'updated_at' => now()->subMinutes(30),
            ],
            [
                'mb_coin_id' => 3, // Marie
                'amount' => 3000,
                'type' => 'debit',
                'description' => 'Achat Bon de Réduction 10%',
                'source' => 'purchase',
                'source_id' => '1',
                'balance_after' => 2200,
                'is_verified' => true,
                'verified_at' => now(),
                'created_at' => now()->subHours(6),
                'updated_at' => now()->subHours(6),
            ],
        ];

        foreach ($transactions as $transaction) {
            MBCoinTransaction::create($transaction);
        }

        // Créer quelques achats MB Shop d'exemple
        $purchases = [
            [
                'user_id' => 3, // Marie
                'mb_shop_item_id' => 1, // Bon de Réduction 10%
                'price_mb_coins' => 3000,
                'status' => 'completed',
                'metadata' => [
                    'item_name' => 'Bon de Réduction 10%',
                    'item_type' => 'discount',
                    'discount_code' => 'SAVE10',
                ],
                'delivered_at' => now()->subHours(5),
                'created_at' => now()->subHours(6),
                'updated_at' => now()->subHours(5),
            ],
        ];

        foreach ($purchases as $purchase) {
            MBShopPurchase::create($purchase);
        }

        $this->command->info('✅ Comptes MB Coins créés');
    }
}
