<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MbcoinSetting extends Model
{
    use HasFactory;

    protected $fillable = [
        'value_in_cfa',
        'convertible_percentage',
        'is_active',
    ];

    protected $casts = [
        'value_in_cfa' => 'decimal:2',
        'convertible_percentage' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    /**
     * Obtenir les paramètres actifs
     */
    public static function getActiveSettings()
    {
        return self::where('is_active', true)->first();
    }

    /**
     * Vérifier si la conversion est activée
     */
    public static function isConversionEnabled()
    {
        $settings = self::getActiveSettings();
        return $settings && $settings->value_in_cfa > 0;
    }
}
