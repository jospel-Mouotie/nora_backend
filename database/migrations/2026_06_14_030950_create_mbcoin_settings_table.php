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
        Schema::create('mbcoin_settings', function (Blueprint $table) {
            $table->id();
            $table->decimal('value_in_cfa', 10, 2)->default(0); // Valeur d'1 MBcoin en FCFA
            $table->decimal('convertible_percentage', 5, 2)->default(100.00); // Pourcentage convertible (ex: 60.00)
            $table->boolean('is_active')->default(false); // Si la valeur est définie et active
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mbcoin_settings');
    }
};
