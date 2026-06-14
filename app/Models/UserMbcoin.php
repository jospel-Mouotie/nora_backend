<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserMbcoin extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'balance',
        'total_earned',
        'last_daily_login_at',
        'daily_login_streak',
    ];

    protected $casts = [
        'balance' => 'decimal:2',
        'total_earned' => 'decimal:2',
        'last_daily_login_at' => 'date',
        'daily_login_streak' => 'integer',
    ];

    /**
     * Relation avec l'utilisateur
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relation avec les transactions
     */
    public function transactions()
    {
        return $this->hasMany(MbcoinTransaction::class, 'user_id');
    }

    /**
     * Calculer le montant convertible
     */
    public function getConvertibleAmountAttribute()
    {
        $settings = MbcoinSetting::getActiveSettings();
        if (!$settings) {
            return 0;
        }
        return $this->balance * ($settings->convertible_percentage / 100);
    }

    /**
     * Calculer la valeur en FCFA des MBcoins convertibles
     */
    public function getConvertibleValueInCfaAttribute()
    {
        $settings = MbcoinSetting::getActiveSettings();
        if (!$settings) {
            return 0;
        }
        return $this->convertible_amount * $settings->value_in_cfa;
    }

    /**
     * Vérifier si l'utilisateur peut réclamer la récompense journalière
     */
    public function canClaimDailyReward()
    {
        if (!$this->last_daily_login_at) {
            return true;
        }
        return $this->last_daily_login_at->lt(now()->toDateString());
    }

    /**
     * Ajouter des MBcoins
     */
    public function addMbcoins($amount, $type, $description = null, $metadata = null)
    {
        $this->balance += $amount;
        $this->total_earned += $amount;
        $this->save();

        return MbcoinTransaction::create([
            'user_id' => $this->user_id,
            'amount' => $amount,
            'type' => $type,
            'description' => $description,
            'metadata' => $metadata,
            'balance_after' => $this->balance,
        ]);
    }

    /**
     * Déduire des MBcoins
     */
    public function deductMbcoins($amount, $type, $description = null, $metadata = null)
    {
        if ($this->balance < $amount) {
            return false;
        }

        $this->balance -= $amount;
        $this->save();

        return MbcoinTransaction::create([
            'user_id' => $this->user_id,
            'amount' => -$amount,
            'type' => $type,
            'description' => $description,
            'metadata' => $metadata,
            'balance_after' => $this->balance,
        ]);
    }
}
