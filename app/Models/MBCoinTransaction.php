<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MBCoinTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'mb_coin_id',
        'amount',
        'type',
        'description',
        'source',
        'source_id',
        'balance_after',
        'method',
        'details',
        'reference',
        'is_verified',
        'verified_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'balance_after' => 'decimal:2',
        'details' => 'array',
        'is_verified' => 'boolean',
        'verified_at' => 'datetime',
    ];

    public function mbCoin()
    {
        return $this->belongsTo(MBCoin::class);
    }

    public function getFormattedAmountAttribute()
    {
        $prefix = $this->type === 'credit' ? '+' : '-';
        return $prefix . ' ' . number_format($this->amount, 2, ',', ' ') . ' MB';
    }

    public function getIsCreditAttribute()
    {
        return $this->type === 'credit';
    }

    public function getIsDebitAttribute()
    {
        return $this->type === 'debit';
    }

    public function getIsWithdrawalAttribute()
    {
        return $this->type === 'withdrawal';
    }

    public function getFormattedTypeAttribute()
    {
        $types = [
            'credit' => 'Crédit',
            'debit' => 'Débit',
            'withdrawal' => 'Retrait',
            'refund' => 'Remboursement',
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function scopeCredits($query)
    {
        return $query->where('type', 'credit');
    }

    public function scopeDebits($query)
    {
        return $query->where('type', 'debit');
    }

    public function scopeWithdrawals($query)
    {
        return $query->where('type', 'withdrawal');
    }

    public function scopeRefunds($query)
    {
        return $query->where('type', 'refund');
    }

    public function scopeFromSource($query, $source)
    {
        return $query->where('source', $source);
    }

    public function scopeInPeriod($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }

    public function scopeVerified($query)
    {
        return $query->where('is_verified', true);
    }

    public function scopePending($query)
    {
        return $query->where('is_verified', false);
    }

    public function markAsVerified()
    {
        $this->update([
            'is_verified' => true,
            'verified_at' => now(),
        ]);
    }

    public function getSourceDescriptionAttribute()
    {
        $sources = [
            'video_like' => 'Like sur vidéo',
            'video_view' => 'Vue de vidéo',
            'purchase' => 'Achat boutique',
            'reward' => 'Récompense',
            'bonus' => 'Bonus quotidien',
            'referral' => 'Parrainage',
            'withdrawal' => 'Retrait',
            'refund' => 'Remboursement',
        ];

        return $sources[$this->source] ?? $this->source;
    }
}
