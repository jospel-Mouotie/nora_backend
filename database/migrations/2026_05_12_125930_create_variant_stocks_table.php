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
        Schema::create('variant_stocks', function (Blueprint $table) {
            $table->id();
            $table->integer('quantity')->default(0); // Quantité en stock
            $table->integer('reserved_quantity')->default(0); // Quantité réservée (panier)
            $table->integer('low_stock_threshold')->default(5); // Seuil stock bas
            $table->boolean('low_stock_alert')->default(false); // Alerte stock bas
            $table->foreignId('product_variant_id')->constrained()->onDelete('cascade');
            $table->timestamps();
            
            $table->index(['product_variant_id', 'quantity']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('variant_stocks');
    }
};
