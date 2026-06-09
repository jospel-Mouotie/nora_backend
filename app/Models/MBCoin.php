<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class MBCoin extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'balance',
        'total_earned',
        'total_spent',
        'total_withdrawn',
        'is_active',
        'last_earned_at',
        'last_spent_at',
    ];

    protected $casts = [
        'balance' => 'decimal:2',
        'total_earned' => 'decimal:2',
        'total_spent' => 'decimal:2',
        'total_withdrawn' => 'decimal:2',
        'is_active' => 'boolean',
        'last_earned_at' => 'datetime',
        'last_spent_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function transactions()
    {
        return $this->hasMany(MBCoinTransaction::class);
    }

    public function rewards()
    {
        return $this->hasMany(MBReward::class);
    }

    public function earn($amount, $description = null, $source = null, $sourceId = null)
    {
        $todayEarned = $this->transactions()
            ->where('type', 'credit')
            ->whereDate('created_at', today())
            ->sum('amount');

        if ($todayEarned + $amount > 50000) {
            throw new \Exception('Limite journalière de 50 000 MB Coins atteinte');
        }

        return DB::transaction(function () use ($amount, $description, $source, $sourceId) {
            $this->increment('balance', $amount);
            $this->increment('total_earned', $amount);
            $this->update(['last_earned_at' => now()]);

            return $this->transactions()->create([
                'amount' => $amount,
                'type' => 'credit',
                'description' => $description,
                'source' => $source,
                'source_id' => $sourceId,
                'balance_after' => $this->fresh()->balance,
            ]);
        });
    }

    public function spend($amount, $description = null, $source = null, $sourceId = null)
    {
        if ($this->balance < $amount) {
            throw new \Exception('Solde insuffisant');
        }

        return DB::transaction(function () use ($amount, $description, $source, $sourceId) {
            $this->decrement('balance', $amount);
            $this->increment('total_spent', $amount);
            $this->update(['last_spent_at' => now()]);

            return $this->transactions()->create([
                'amount' => $amount,
                'type' => 'debit',
                'description' => $description,
                'source' => $source,
                'source_id' => $sourceId,
                'balance_after' => $this->fresh()->balance,
            ]);
        });
    }

    public function withdraw($amount, $method = null, $details = null)
    {
        if ($this->balance < $amount) {
            throw new \Exception('Solde insuffisant pour le retrait');
        }

        return DB::transaction(function () use ($amount, $method, $details) {
            $this->decrement('balance', $amount);
            $this->increment('total_withdrawn', $amount);

            return $this->transactions()->create([
                'amount' => $amount,
                'type' => 'withdrawal',
                'description' => 'Retrait MB Coins',
                'source' => 'withdrawal',
                'method' => $method,
                'details' => $details,
                'balance_after' => $this->fresh()->balance,
            ]);
        });
    }

    public function getFormattedBalanceAttribute()
    {
        return number_format($this->balance, 2, ',', ' ') . ' MB';
    }

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeWithBalance($query, $minAmount = 0)
    {
        return $query->where('balance', '>=', $minAmount);
    }

    public function getRecentTransactions($limit = 10)
    {
        return $this->transactions()
            ->orderBy('created_at', 'desc')
            ->limit($limit)
            ->get();
    }

    public function getTransactionHistory($startDate = null, $endDate = null, $type = null)
    {
        $query = $this->transactions();

        if ($startDate) {
            $query->where('created_at', '>=', $startDate);
        }

        if ($endDate) {
            $query->where('created_at', '<=', $endDate);
        }

        if ($type) {
            $query->where('type', $type);
        }

        return $query->orderBy('created_at', 'desc')->get();
    }

    public function getEarningsByPeriod($days = 30)
    {
        return $this->transactions()
            ->where('type', 'credit')
            ->where('created_at', '>=', now()->subDays($days))
            ->sum('amount');
    }

    public function getSpendingByPeriod($days = 30)
    {
        return $this->transactions()
            ->where('type', 'debit')
            ->where('created_at', '>=', now()->subDays($days))
            ->sum('amount');
    }
}
