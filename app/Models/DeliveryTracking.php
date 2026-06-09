<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DeliveryTracking extends Model
{
    use HasFactory;

    protected $fillable = [
        'delivery_id',
        'latitude',
        'longitude',
        'status',
        'notes',
        'tracked_at',
    ];

    protected $casts = [
        'latitude' => 'decimal:8',
        'longitude' => 'decimal:8',
        'tracked_at' => 'datetime',
    ];

    public function delivery()
    {
        return $this->belongsTo(Delivery::class);
    }

    public function scopeForDelivery($query, $deliveryId)
    {
        return $query->where('delivery_id', $deliveryId);
    }

    public function scopeLatest($query)
    {
        return $query->orderBy('tracked_at', 'desc');
    }
}
