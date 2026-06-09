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
        Schema::create('m_b_coins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->decimal('balance', 15, 2)->default(0); // solde actuel
            $table->decimal('total_earned', 15, 2)->default(0); // total gagné
            $table->decimal('total_spent', 15, 2)->default(0); // total dépensé
            $table->decimal('total_withdrawn', 15, 2)->default(0); // total retiré
            $table->boolean('is_active')->default(true);
            $table->timestamp('last_earned_at')->nullable();
            $table->timestamp('last_spent_at')->nullable();
            $table->timestamps();
            
            $table->unique('user_id');
            $table->index(['user_id', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('m_b_coins');
    }
};
