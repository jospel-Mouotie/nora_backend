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
        Schema::create('m_b_rewards', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('mb_coin_id')->nullable()->constrained('m_b_coins')->onDelete('cascade');
            $table->string('title');
            $table->text('description')->nullable();
            $table->enum('type', ['daily_bonus', 'video_view', 'video_like', 'comment', 'referral', 'achievement', 'special']);
            $table->decimal('amount', 10, 2);
            $table->string('source_type')->nullable(); // video, shop, etc.
            $table->string('source_id')->nullable();
            $table->json('metadata')->nullable(); // données supplémentaires
            $table->boolean('is_claimed')->default(false);
            $table->timestamp('claimed_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'type', 'is_claimed']);
            $table->index(['type', 'expires_at']);
            $table->index(['source_type', 'source_id']);
            $table->index('mb_coin_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('m_b_rewards');
    }
};
