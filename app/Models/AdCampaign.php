<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AdCampaign extends Model
{
    use HasFactory;

    protected $fillable = [
        'shop_id',
        'name',
        'description',
        'status',
        'total_budget',
        'daily_budget',
        'spent_amount',
        'starts_at',
        'ends_at',
        'targeting',
        'settings',
    ];

    protected $casts = [
        'total_budget' => 'decimal:2',
        'daily_budget' => 'decimal:2',
        'spent_amount' => 'decimal:2',
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'targeting' => 'array',
        'settings' => 'array',
    ];

    public function shop()
    {
        return $this->belongsTo(Shop::class);
    }

    public function ads()
    {
        return $this->hasMany(Ad::class);
    }

    public function activeAds()
    {
        return $this->ads()->active();
    }

    public function getRemainingBudgetAttribute()
    {
        return max(0, $this->total_budget - $this->spent_amount);
    }

    public function getRemainingDailyBudgetAttribute()
    {
        $todaySpent = $this->getTodaySpent();
        return max(0, $this->daily_budget - $todaySpent);
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

    public function getStatusLabelAttribute()
    {
        $statuses = [
            'active' => 'Active',
            'paused' => 'En pause',
            'completed' => 'Terminée',
            'cancelled' => 'Annulée',
        ];

        return $statuses[$this->status] ?? $this->status;
    }

    public function getTotalAdsAttribute()
    {
        return $this->ads()->count();
    }

    public function getActiveAdsAttribute()
    {
        return $this->ads()->active()->count();
    }

    public function getTotalImpressionsAttribute()
    {
        return $this->ads()->sum('impressions_count');
    }

    public function getTotalClicksAttribute()
    {
        return $this->ads()->sum('clicks_count');
    }

    public function getTotalConversionsAttribute()
    {
        return $this->ads()->sum('conversions_count');
    }

    public function getAverageCTRAttribute()
    {
        $totalImpressions = $this->getTotalImpressionsAttribute();
        $totalClicks = $this->getTotalClicksAttribute();
        
        if ($totalImpressions === 0) {
            return 0;
        }
        
        return round(($totalClicks / $totalImpressions) * 100, 2);
    }

    public function getAverageConversionRateAttribute()
    {
        $totalClicks = $this->getTotalClicksAttribute();
        $totalConversions = $this->getTotalConversionsAttribute();
        
        if ($totalClicks === 0) {
            return 0;
        }
        
        return round(($totalConversions / $totalClicks) * 100, 2);
    }

    public function spendAmount($amount)
    {
        $this->increment('spent_amount', $amount);
    }

    public function pause()
    {
        $this->update(['status' => 'paused']);
    }

    public function resume()
    {
        $this->update(['status' => 'active']);
    }

    public function complete()
    {
        $this->update(['status' => 'completed']);
    }

    public function cancel()
    {
        $this->update(['status' => 'cancelled']);
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

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }

    public function scopeCancelled($query)
    {
        return $query->where('status', 'cancelled');
    }

    public function scopeForShop($query, $shopId)
    {
        return $query->where('shop_id', $shopId);
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
