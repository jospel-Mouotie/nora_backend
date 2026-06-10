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
        Schema::create('products', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description');
            $table->decimal('price', 10, 2);
            $table->decimal('promotion_price', 10, 2)->nullable(); // Prix promotionnel
            $table->integer('promotion_percentage')->nullable(); // Pourcentage de réduction
            $table->timestamp('promotion_start')->nullable(); // Début promotion
            $table->timestamp('promotion_end')->nullable(); // Fin promotion
            $table->boolean('is_active')->default(true);
            $table->boolean('in_promotion')->default(false); // Statut promotion
            $table->string('sku')->unique(); // Référence produit
            $table->text('images')->nullable(); // JSON des images
            $table->foreignId('category_id')->constrained()->onDelete('cascade');
            $table->foreignId('shop_id')->constrained()->onDelete('cascade');
            $table->integer('view_count')->default(0);
            $table->integer('sales_count')->default(0);
            $table->timestamps();
            
            $table->index(['shop_id', 'is_active', 'in_promotion']);
            $table->index(['category_id', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('products');
    }
};
