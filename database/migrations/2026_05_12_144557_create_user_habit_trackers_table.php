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
        Schema::create('user_habit_trackers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('action_type', ['view', 'search', 'click', 'purchase', 'like', 'share', 'bookmark']);
            $table->string('entity_type'); // product, shop, category, video
            $table->string('entity_id'); // ID de l'entité
            $table->json('metadata')->nullable(); // détails supplémentaires
            $table->timestamp('action_time');
            $table->string('session_id')->nullable(); // pour suivre les sessions
            $table->string('ip_address')->nullable();
            $table->string('user_agent')->nullable();
            $table->json('context')->nullable(); // contexte de l'action
            $table->timestamps();
            
            $table->index(['user_id', 'action_type', 'action_time']);
            $table->index(['entity_type', 'entity_id']);
            $table->index(['action_time']);
            $table->index(['user_id', 'session_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_habit_trackers');
    }
};
