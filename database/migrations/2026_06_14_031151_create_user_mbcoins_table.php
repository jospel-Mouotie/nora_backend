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
        Schema::create('user_mbcoins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->decimal('balance', 10, 2)->default(0); // Solde actuel de MBcoins
            $table->decimal('total_earned', 10, 2)->default(0); // Total gagné depuis le début
            $table->date('last_daily_login_at')->nullable(); // Dernière connexion journalière
            $table->integer('daily_login_streak')->default(0); // Série de connexions journalières
            $table->timestamps();

            $table->unique('user_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_mbcoins');
    }
};
