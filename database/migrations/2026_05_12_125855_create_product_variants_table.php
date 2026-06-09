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
        Schema::create('product_variants', function (Blueprint $table) {
            $table->id();
            $table->string('size')->nullable(); // Taille (S, M, L, XL, etc.)
            $table->string('color')->nullable(); // Couleur
            $table->string('material')->nullable(); // Matière
            $table->string('sku')->unique(); // SKU unique par variante
            $table->decimal('price_adjustment', 10, 2)->default(0); // Ajustement prix
            $table->string('image')->nullable(); // Image spécifique à la variante
            $table->boolean('is_active')->default(true);
            $table->foreignId('product_id')->constrained()->onDelete('cascade');
            $table->timestamps();
            
            $table->index(['product_id', 'is_active']);
            $table->index(['size', 'color']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('product_variants');
    }
};
