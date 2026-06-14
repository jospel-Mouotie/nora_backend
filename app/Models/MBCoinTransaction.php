<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MbcoinTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'amount',
        'type',
        'description',
        'metadata',
        'balance_after',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'balance_after' => 'decimal:2',
        'metadata' => 'array',
    ];

    /**
     * Relation avec l'utilisateur
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relation avec les MBcoins de l'utilisateur
     */
    public function userMbcoin()
    {
        return $this->belongsTo(UserMbcoin::class, 'user_id', 'user_id');
    }

    /**
     * Obtenir le montant formaté
     */
    public function getFormattedAmountAttribute()
    {
        $prefix = $this->amount >= 0 ? '+' : '-';
        return $prefix . ' ' . abs($this->amount) . ' MB';
    }

    /**
     * Vérifier si c'est un gain
     */
    public function getIsCreditAttribute()
    {
        return $this->amount > 0;
    }

    /**
     * Vérifier si c'est une dépense
     */
    public function getIsDebitAttribute()
    {
        return $this->amount < 0;
    }

    /**
     * Scope pour les gains
     */
    public function scopeCredits($query)
    {
        return $query->where('amount', '>', 0);
    }

    /**
     * Scope pour les dépenses
     */
    public function scopeDebits($query)
    {
        return $query->where('amount', '<', 0);
    }

    /**
     * Scope pour un type spécifique
     */
    public function scopeOfType($query, $type)
    {
        return $query->where('type', $type);
    }

    /**
     * Scope pour une période
     */
    public function scopeInPeriod($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }
}
