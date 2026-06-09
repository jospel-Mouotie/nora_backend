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
        Schema::create('shop_stories', function (Blueprint $table) {
            $table->id();
            $table->string('type'); // image, video, product, annonce
            $table->string('content'); // URL de l'image/vidéo ou texte
            $table->text('caption')->nullable(); // Légende optionnelle
            $table->enum('status', ['en_attente', 'active'])->default('en_attente');
            $table->timestamp('expires_at'); // Expire après 24h
            $table->foreignId('shop_id')->constrained()->onDelete('cascade');
            $table->foreignId('product_id')->nullable();
            $table->timestamps();
            
            $table->index(['shop_id', 'status', 'expires_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('shop_stories');
    }
};
