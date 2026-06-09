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
        Schema::create('video_comments', function (Blueprint $table) {
            $table->id();
            $table->text('content');
            $table->foreignId('video_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('parent_id')->nullable()->constrained('video_comments')->onDelete('cascade');
            $table->boolean('is_approved')->default(true);
            $table->integer('likes_count')->default(0);
            $table->integer('replies_count')->default(0);
            $table->timestamp('edited_at')->nullable();
            $table->timestamps();
            
            $table->index(['video_id', 'is_approved', 'created_at']);
            $table->index(['user_id', 'created_at']);
            $table->index(['parent_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('video_comments');
    }
};
