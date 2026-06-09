<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VideoView extends Model
{
    use HasFactory;

    protected $fillable = [
        'video_id',
        'user_id',
        'watch_duration_seconds',
        'counted_as_view',
        'ip_address',
        'user_agent',
        'country_code',
        'city',
        'started_at',
        'ended_at',
    ];

    protected $casts = [
        'watch_duration_seconds' => 'decimal:2',
        'counted_as_view' => 'boolean',
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    public function video()
    {
        return $this->belongsTo(Video::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function markAsViewed()
    {
        if ($this->watch_duration_seconds >= 1.4 && !$this->counted_as_view) {
            $this->update(['counted_as_view' => true]);
            $this->video->increment('view_count');
            return true;
        }
        return false;
    }

    public function getCompletionPercentageAttribute()
    {
        if (!$this->video || !$this->video->duration_seconds) {
            return 0;
        }

        return min(100, ($this->watch_duration_seconds / $this->video->duration_seconds) * 100);
    }

    public function scopeCountedAsView($query)
    {
        return $query->where('counted_as_view', true);
    }

    public function scopeFromUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeFromCountry($query, $countryCode)
    {
        return $query->where('country_code', $countryCode);
    }

    public function scopeInPeriod($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }
}
