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
        Schema::create('user_interests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('category_id')->constrained()->onDelete('cascade');
            $table->integer('priority_level')->default(1); // 1-5, niveau d'intérêt
            $table->boolean('is_active')->default(true);
            $table->timestamp('selected_at')->nullable(); // quand l'utilisateur a sélectionné cet intérêt
            $table->json('metadata')->nullable(); // préférences spécifiques
            $table->timestamps();
            
            $table->unique(['user_id', 'category_id']);
            $table->index(['user_id', 'priority_level']);
            $table->index(['category_id', 'is_active']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_interests');
    }
};
