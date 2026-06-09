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
        Schema::create('order_qr_codes', function (Blueprint $table) {
            $table->id();
            $table->string('qr_code')->unique();
            $table->boolean('is_used')->default(false);
            $table->timestamp('used_at')->nullable();
            $table->timestamp('expires_at')->useCurrent();
            $table->foreignId('order_id')->constrained()->onDelete('cascade');
            $table->timestamps();
            
            $table->index(['order_id', 'is_used']);
            $table->index(['qr_code', 'expires_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('order_qr_codes');
    }
};
