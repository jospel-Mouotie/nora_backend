<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Ad extends Model
{
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'ad_campaign_id',
        'title',
        'description',
        'image',
        'link_url',
        'type',
        'position',
        'status',
        'budget',
        'daily_budget',
        'cost_per_click',
        'cost_per_impression',
        'max_impressions',
        'max_clicks',
        'starts_at',
        'ends_at',
        'targeting',
        'metadata',
        'impressions_count',
        'clicks_count',
        'conversions_count',
        'spent_amount',
    ];

    protected $casts = [
        'budget' => 'decimal:2',
        'daily_budget' => 'decimal:2',
        'cost_per_click' => 'decimal:2',
        'cost_per_impression' => 'decimal:2',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'targeting' => 'array',
        'metadata' => 'array',
        'spent_amount' => 'decimal:2',
    ];

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function adCampaign()
    {
        return $this->belongsTo(AdCampaign::class);
    }

    public function getImageUrlAttribute()
    {
        if ($this->image) {
            return asset('storage/' . $this->image);
        }
        return null;
    }

    public function getIsRunningAttribute()
    {
        return $this->status === 'active' 
            && (!$this->starts_at || $this->starts_at->isPast())
            && (!$this->ends_at || $this->ends_at->isFuture());
    }

    public function getIsExpiredAttribute()
    {
        return $this->ends_at && $this->ends_at->isPast();
    }

    public function getRemainingBudgetAttribute()
    {
        return max(0, $this->budget - $this->spent_amount);
    }

    public function getRemainingDailyBudgetAttribute()
    {
        $todaySpent = $this->getTodaySpent();
        return max(0, $this->daily_budget - $todaySpent);
    }

    public function getRemainingImpressionsAttribute()
    {
        return max(0, $this->max_impressions - $this->impressions_count);
    }

    public function getRemainingClicksAttribute()
    {
        return max(0, $this->max_clicks - $this->clicks_count);
    }

    public function getClickThroughRateAttribute()
    {
        if ($this->impressions_count === 0) {
            return 0;
        }
        return round(($this->clicks_count / $this->impressions_count) * 100, 2);
    }

    public function getConversionRateAttribute()
    {
        if ($this->clicks_count === 0) {
            return 0;
        }
        return round(($this->conversions_count / $this->clicks_count) * 100, 2);
    }

    public function getTypeLabelAttribute()
    {
        $types = [
            'banner' => 'Bannière',
            'video' => 'Vidéo',
            'carousel' => 'Carrousel',
            'popup' => 'Pop-up',
        ];

        return $types[$this->type] ?? $this->type;
    }

    public function getPositionLabelAttribute()
    {
        $positions = [
            'top' => 'En haut',
            'sidebar' => 'Barre latérale',
            'bottom' => 'En bas',
            'popup' => 'Pop-up',
            'in_feed' => 'Dans le fil',
        ];

        return $positions[$this->position] ?? $this->position;
    }

    public function getStatusLabelAttribute()
    {
        $statuses = [
            'active' => 'Active',
            'paused' => 'En pause',
            'expired' => 'Expirée',
            'rejected' => 'Rejetée',
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function recordImpression()
    {
        $this->increment('impressions_count');
        $this->increment('spent_amount', $this->cost_per_impression ?? 0);
        $this->checkLimits();
    }

    public function recordClick()
    {
        $this->increment('clicks_count');
        $this->increment('spent_amount', $this->cost_per_click ?? 0);
        $this->checkLimits();
    }

    public function recordConversion()
    {
        $this->increment('conversions_count');
    }

    public function checkLimits()
    {
        // Vérifier les limites et mettre à jour le statut si nécessaire
        if ($this->max_impressions && $this->impressions_count >= $this->max_impressions) {
            $this->update(['status' => 'expired']);
            return true;
        }

        if ($this->max_clicks && $this->clicks_count >= $this->max_clicks) {
            $this->update(['status' => 'expired']);
            return true;
        }

        if ($this->budget && $this->spent_amount >= $this->budget) {
            $this->update(['status' => 'expired']);
            return true;
        }

        return false;
    }

    public function getTodaySpent()
    {
        // Cette méthode devrait être implémentée avec une table de suivi journalier
        // Pour l'instant, retourne 0
        return 0;
    }

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopePaused($query)
    {
        return $query->where('status', 'paused');
    }

    public function scopeExpired($query)
    {
        return $query->where('status', 'expired');
    }

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
    }

    public function scopeByType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeByPosition($query, $position)
    {
        return $query->where('position', $position);
    }

    public function scopeRunning($query)
    {
        return $query->where('status', 'active')
                    ->where(function ($q) {
                        $q->whereNull('starts_at')
                          ->orWhere('starts_at', '<=', now());
                    })
                    ->where(function ($q) {
                        $q->whereNull('ends_at')
                          ->orWhere('ends_at', '>', now());
                    });
    }
}
