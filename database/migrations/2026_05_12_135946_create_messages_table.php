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
        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->text('content');
            $table->enum('type', ['text', 'image', 'location', 'system'])->default('text');
            $table->foreignId('delivery_id')->constrained()->onDelete('cascade');
            $table->foreignId('sender_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('receiver_id')->nullable()->constrained('users')->onDelete('cascade');
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->string('attachment_path')->nullable();
            $table->decimal('sender_latitude', 10, 8)->nullable();
            $table->decimal('sender_longitude', 11, 8)->nullable();
            $table->timestamps();
            
            $table->index(['delivery_id', 'created_at']);
            $table->index(['sender_id', 'receiver_id']);
            $table->index(['delivery_id', 'is_read']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('messages');
    }
};
