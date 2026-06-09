<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;

class MBReward extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'mb_coin_id',
        'title',
        'description',
        'type',
        'amount',
        'source_type',
        'source_id',
        'metadata',
        'is_claimed',
        'claimed_at',
        'expires_at',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'metadata' => 'array',
        'is_claimed' => 'boolean',
        'claimed_at' => 'datetime',
        'expires_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function mbCoin()
    {
        return $this->belongsTo(MBCoin::class);
    }

    public function claim()
    {
        if ($this->is_claimed) {
            throw new \Exception('Récompense déjà réclamée');
        }

        if ($this->expires_at && $this->expires_at->isPast()) {
            throw new \Exception('Récompense expirée');
        }

        return DB::transaction(function () {
            $this->mbCoin->earn($this->amount, $this->title, 'reward', $this->id);
            
            $this->update([
                'is_claimed' => true,
                'claimed_at' => now(),
            ]);

            return $this;
        });
    }

    public function getIsExpiredAttribute()
    {
        return $this->expires_at && $this->expires_at->isPast();
    }

    public function getIsAvailableAttribute()
    {
        return !$this->is_claimed && !$this->is_expired;
    }

    public function getFormattedAmountAttribute()
    {
        return number_format($this->amount, 2, ',', ' ') . ' MB';
    }

    public function getTypeLabelAttribute()
    {
        $types = [
            'daily_bonus' => 'Bonus Quotidien',
            'video_view' => 'Vue de Vidéo',
            'video_like' => 'Like sur Vidéo',
            'comment' => 'Commentaire',
            'referral' => 'Parrainage',
            'achievement' => 'Succès',
            'special' => 'Récompense Spéciale',
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function scopeClaimed($query)
    {
        return $query->where('is_claimed', true);
    }

    public function scopeUnclaimed($query)
    {
        return $query->where('is_claimed', false);
    }

    public function scopeExpired($query)
    {
        return $query->where('expires_at', '<', now());
    }

    public function scopeNotExpired($query)
    {
        return $query->where(function ($q) {
            $q->whereNull('expires_at')
              ->orWhere('expires_at', '>', now());
        });
    }

    public function scopeAvailable($query)
    {
        return $query->unclaimed()->notExpired();
    }

    public function scopeForUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeFromSource($query, $sourceType, $sourceId)
    {
        return $query->where('source_type', $sourceType)
                    ->where('source_id', $sourceId);
    }

    public function scopeInPeriod($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }

    // Méthodes statiques pour créer des récompenses
    public static function createDailyBonus($userId, $amount)
    {
        return self::create([
            'user_id' => $userId,
            'mb_coin_id' => MBCoin::where('user_id', $userId)->first()->id,
            'title' => 'Bonus Quotidien',
            'description' => 'Bonus quotidien pour votre activité',
            'type' => 'daily_bonus',
            'amount' => $amount,
            'expires_at' => now()->addDays(7),
        ]);
    }

    public static function createVideoViewReward($userId, $videoId, $amount)
    {
        return self::create([
            'user_id' => $userId,
            'mb_coin_id' => MBCoin::where('user_id', $userId)->first()->id,
            'title' => 'Vue de Vidéo',
            'description' => 'Récompense pour avoir regardé une vidéo',
            'type' => 'video_view',
            'amount' => $amount,
            'source_type' => 'video',
            'source_id' => $videoId,
            'expires_at' => now()->addDays(30),
        ]);
    }

    public static function createVideoLikeReward($userId, $videoId, $amount)
    {
        return self::create([
            'user_id' => $userId,
            'mb_coin_id' => MBCoin::where('user_id', $userId)->first()->id,
            'title' => 'Like sur Vidéo',
            'description' => 'Récompense pour avoir liké une vidéo',
            'type' => 'video_like',
            'amount' => $amount,
            'source_type' => 'video',
            'source_id' => $videoId,
            'expires_at' => now()->addDays(30),
        ]);
    }

    public static function createReferralReward($userId, $referredUserId, $amount)
    {
        return self::create([
            'user_id' => $userId,
            'mb_coin_id' => MBCoin::where('user_id', $userId)->first()->id,
            'title' => 'Bonus de Parrainage',
            'description' => 'Récompense pour avoir parrainé un nouvel utilisateur',
            'type' => 'referral',
            'amount' => $amount,
            'metadata' => ['referred_user_id' => $referredUserId],
        ]);
    }
}
