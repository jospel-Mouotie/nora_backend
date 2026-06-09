<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class OrderQrCode extends Model
{
    use HasFactory;

    protected $fillable = [
        'qr_code',
        'is_used',
        'used_at',
        'expires_at',
        'order_id',
    ];

    protected $casts = [
        'is_used' => 'boolean',
        'used_at' => 'datetime',
        'expires_at' => 'datetime',
    ];

    // Relations
    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    // Scopes
    public function scopeUsed($query)
    {
        return $query->where('is_used', true);
    }

    public function scopeUnused($query)
    {
        return $query->where('is_used', false);
    }

    public function scopeExpired($query)
    {
        return $query->where('expires_at', '<', now());
    }

    public function scopeValid($query)
    {
        return $query->where('is_used', false)
                    ->where('expires_at', '>', now());
    }

    // Méthodes utilitaires
    public function isUsed()
    {
        return $this->is_used;
    }

    public function isExpired()
    {
        return $this->expires_at && $this->expires_at->isPast();
    }

    public function isValid()
    {
        return !$this->is_used && !$this->isExpired();
    }

    public function markAsUsed()
    {
        $this->update([
            'is_used' => true,
            'used_at' => now()
        ]);
    }

    // Nettoyer les QR codes expirés (méthode statique)
    public static function cleanupExpired()
    {
        self::where('expires_at', '<', now())
            ->where('is_used', false)
            ->delete();
    }

    // Scope pour les QR codes sur le point d'expirer
    public function scopeExpiringSoon($query, $hours = 24)
    {
        return $query->unused()
                    ->where('expires_at', '<=', now()->addHours($hours));
    }

    // Générer un QR code unique
    public static function generateUniqueCode()
    {
        do {
            $code = 'QR-' . strtoupper(uniqid()) . '-' . time();
        } while (self::where('qr_code', $code)->exists());
        
        return $code;
    }
}
