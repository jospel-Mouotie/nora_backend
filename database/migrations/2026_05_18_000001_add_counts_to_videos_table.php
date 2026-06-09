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
        Schema::table('videos', function (Blueprint $table) {
            $table->integer('view_count')->default(0)->after('processed_path');
            $table->integer('likes_count')->default(0)->after('view_count');
            $table->integer('comments_count')->default(0)->after('likes_count');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('videos', function (Blueprint $table) {
            $table->dropColumn(['view_count', 'likes_count', 'comments_count']);
        });
    }
};
