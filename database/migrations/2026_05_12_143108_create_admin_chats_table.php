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
        Schema::create('admin_chats', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->foreignId('admin_id')->nullable()->constrained('users')->onDelete('set null');
            $table->text('content');
            $table->enum('type', ['text', 'image', 'file', 'system']);
            $table->enum('sender_type', ['user', 'admin']);
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->string('attachment_path')->nullable();
            $table->json('metadata')->nullable(); // infos supplémentaires
            $table->timestamps();
            
            $table->index(['user_id', 'created_at']);
            $table->index(['admin_id', 'created_at']);
            $table->index(['sender_type', 'is_read', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('admin_chats');
    }
};
