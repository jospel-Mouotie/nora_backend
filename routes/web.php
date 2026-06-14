<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

Route::get('/reel/{id}', function ($id) {
    return view('reel', ['id' => $id]);
});

Route::get('/product/{id}', function ($id) {
    return view('product', ['id' => $id]);
});

use Illuminate\Support\Facades\Storage;

Route::get('/storage/{path}', function ($path) {
    // Nettoyer le chemin des doubles préfixes éventuels
    $cleanPath = preg_replace('/^\/?storage\//', '', $path);

    if (!Storage::disk('public')->exists($cleanPath)) {
        abort(404);
    }

    $filePath = Storage::disk('public')->path($cleanPath);

    return response()->file($filePath, [
        'Cache-Control' => 'public, max-age=31536000'
    ]);
})->where('path', '.*');

