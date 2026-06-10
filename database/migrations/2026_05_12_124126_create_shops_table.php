<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('shops', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description');
            $table->string('address');
            $table->string('phone');
            $table->string('email');
            $table->string('photo')->nullable();
            $table->string('banner')->nullable(); // ✅ Bannière de la boutique
            $table->enum('status', ['en_attente', 'active', 'refusee'])->default('en_attente');
            $table->boolean('certifiee')->default(false);
            $table->timestamp('certifiee_at')->nullable();

            // ✅ Nouveaux champs pour la livraison
            $table->json('delivery_cities')->nullable(); // Liste des villes où on livre (stocké en JSON)
            $table->decimal('delivery_price', 10, 2)->default(0); // Prix de livraison standard
            $table->decimal('free_delivery_min_amount', 10, 2)->nullable(); // Montant minimum pour livraison gratuite
            $table->enum('delivery_type', ['standard', 'express', 'both'])->default('standard'); // Type de livraison

            // ✅ Coordonnées GPS (optionnel)
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();

            // ✅ Horaires d'ouverture (stocké en JSON)
            $table->json('opening_hours')->nullable();

            // ✅ Réseaux sociaux
            $table->string('facebook_url')->nullable();
            $table->string('instagram_url')->nullable();
            $table->string('whatsapp_number')->nullable();

            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('shops');
    }
};
