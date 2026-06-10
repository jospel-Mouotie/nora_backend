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
        Schema::create('videos', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('video_path');
            $table->string('thumbnail_path')->nullable();
            $table->enum('status', ['processing', 'ready', 'failed', 'deleted'])->default('processing');
            $table->integer('duration_seconds')->nullable();
            $table->string('resolution')->nullable(); // ex: 1080x1920
            $table->decimal('file_size_mb', 10, 2)->nullable();
            $table->string('format')->default('mp4');
            $table->boolean('is_public')->default(true);
            $table->boolean('allow_comments')->default(true);
            $table->boolean('allow_downloads')->default(false);
            $table->timestamp('published_at')->nullable();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('shop_id')->nullable()->constrained()->onDelete('cascade');
            $table->json('metadata')->nullable(); // infos codec, bitrate, etc.
            $table->string('stream_url')->nullable(); // URL pour streaming HLS/DASH
            $table->string('processed_path')->nullable(); // vidéo optimisée pour streaming
            $table->integer('views_count')->default(0);
            $table->integer('likes_count')->default(0);
            $table->integer('comments_count')->default(0);
            $table->timestamps();
            
            $table->index(['user_id', 'status']);
            $table->index(['shop_id', 'status']);
            $table->index(['status', 'published_at']);
            $table->index(['is_public', 'published_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('videos');
    }
};
