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
        Schema::create('ad_campaigns', function (Blueprint $table) {
            $table->id();
            $table->foreignId('shop_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('status', ['active', 'paused', 'completed', 'cancelled'])->default('active');
            $table->decimal('total_budget', 12, 2); // budget total de la campagne
            $table->decimal('daily_budget', 10, 2)->nullable(); // budget quotidien
            $table->decimal('spent_amount', 12, 2)->default(0); // montant dépensé
            $table->timestamp('starts_at');
            $table->timestamp('ends_at')->nullable();
            $table->json('targeting')->nullable(); // ciblage démographique, géographique, intérêts
            $table->json('settings')->nullable(); // paramètres spécifiques
            $table->timestamps();
            
            $table->index(['shop_id', 'status', 'starts_at']);
            $table->index(['status', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ad_campaigns');
    }
};
