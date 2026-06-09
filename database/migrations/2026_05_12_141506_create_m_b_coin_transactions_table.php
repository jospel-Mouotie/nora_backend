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
        Schema::create('m_b_coin_transactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('mb_coin_id')->nullable();
            $table->decimal('amount', 15, 2);
            $table->enum('type', ['credit', 'debit', 'withdrawal', 'refund']);
            $table->string('description')->nullable();
            $table->string('source')->nullable(); // video_like, video_view, purchase, reward, etc.
            $table->string('source_id')->nullable();
            $table->decimal('balance_after', 15, 2);
            $table->string('method')->nullable(); // pour les retraits
            $table->json('details')->nullable(); // informations supplémentaires
            $table->string('reference')->nullable(); // référence externe
            $table->boolean('is_verified')->default(true);
            $table->timestamp('verified_at')->nullable();
            $table->timestamps();
            
            $table->index(['mb_coin_id', 'type', 'created_at']);
            $table->index(['source', 'source_id']);
            $table->index(['type', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('m_b_coin_transactions');
    }
};
