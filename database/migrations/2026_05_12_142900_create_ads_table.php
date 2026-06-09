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
        Schema::create('ads', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained()->onDelete('cascade');
            $table->foreignId('ad_campaign_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('image');
            $table->string('link_url');
            $table->enum('type', ['banner', 'video', 'carousel', 'popup']);
            $table->enum('position', ['top', 'sidebar', 'bottom', 'popup', 'in_feed']);
            $table->enum('status', ['active', 'paused', 'expired', 'rejected'])->default('active');
            $table->decimal('budget', 10, 2)->nullable(); // budget en MB Coins
            $table->decimal('daily_budget', 8, 2)->nullable(); // budget quotidien
            $table->decimal('cost_per_click', 8, 2)->nullable(); // coût par clic
            $table->decimal('cost_per_impression', 8, 2)->nullable(); // coût par impression
            $table->integer('max_impressions')->nullable(); // max impressions
            $table->integer('max_clicks')->nullable(); // max clics
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->json('targeting')->nullable(); // ciblage démographique, géographique, etc.
            $table->json('metadata')->nullable(); // données supplémentaires
            $table->integer('impressions_count')->default(0);
            $table->integer('clicks_count')->default(0);
            $table->integer('conversions_count')->default(0);
            $table->decimal('spent_amount', 10, 2)->default(0);
            $table->timestamps();
            
            $table->index(['shop_id', 'status', 'starts_at', 'ends_at']);
            $table->index(['type', 'position', 'status']);
            $table->index(['status', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ads');
    }
};
