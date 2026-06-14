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
        Schema::create('mbcoin_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->decimal('amount', 10, 2); // Montant (positif pour gain, négatif pour dépense)
            $table->string('type'); // 'video_view', 'like', 'comment', 'daily_login', 'conversion', 'admin_adjustment'
            $table->text('description')->nullable(); // Description de la transaction
            $table->json('metadata')->nullable(); // Données supplémentaires (video_id, etc.)
            $table->decimal('balance_after', 10, 2); // Solde après la transaction
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mbcoin_transactions');
    }
};
