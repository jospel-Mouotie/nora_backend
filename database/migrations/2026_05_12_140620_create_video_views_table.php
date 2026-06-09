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
        Schema::create('video_views', function (Blueprint $table) {
            $table->id();
            $table->foreignId('video_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('cascade');
            $table->decimal('watch_duration_seconds', 8, 2)->default(0); // durée exacte regardée
            $table->boolean('counted_as_view')->default(false); // si >= 1.4s
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->string('country_code', 2)->nullable();
            $table->string('city')->nullable();
            $table->timestamp('started_at')->nullable(); // quand la vue a commencé
            $table->timestamp('ended_at')->nullable(); // quand la vue s'est terminée
            $table->timestamps();
            
            $table->index(['video_id', 'counted_as_view']);
            $table->index(['user_id', 'video_id']);
            $table->index(['video_id', 'created_at']);
            $table->unique(['video_id', 'user_id', 'ip_address'], 'unique_view_per_user_ip');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('video_views');
    }
};
