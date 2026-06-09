<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use App\Services\GeolocationService;

class Delivery extends Model
{
    use HasFactory;

    protected $fillable = [
        'status',
        'delivery_fee',
        'delivery_address',
        'notes',
        'picked_up_at',
        'delivered_at',
        'estimated_delivery_at',
        'pickup_latitude',
        'pickup_longitude',
        'delivery_latitude',
        'delivery_longitude',
        'current_latitude',
        'current_longitude',
        'last_location_update',
        'order_id',
        'delivery_person_id',
    ];

    protected $casts = [
        'delivery_fee' => 'decimal:2',
        'pickup_latitude' => 'decimal:8',
        'pickup_longitude' => 'decimal:8',
        'delivery_latitude' => 'decimal:8',
        'delivery_longitude' => 'decimal:8',
        'current_latitude' => 'decimal:8',
        'current_longitude' => 'decimal:8',
        'picked_up_at' => 'datetime',
        'delivered_at' => 'datetime',
        'estimated_delivery_at' => 'datetime',
        'last_location_update' => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function deliveryPerson()
    {
        return $this->belongsTo(User::class, 'delivery_person_id');
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function unreadMessages()
    {
        return $this->messages()->unread();
    }

    public function tracking()
    {
        return $this->hasMany(DeliveryTracking::class);
    }

    public function latestTracking()
    {
        return $this->tracking()->latest()->first();
    }

    public function updateCurrentLocation($latitude, $longitude)
    {
        $this->update([
            'current_latitude' => $latitude,
            'current_longitude' => $longitude,
            'last_location_update' => now(),
        ]);
    }

    public function getDistanceToDelivery()
    {
        if (!$this->current_latitude || !$this->current_longitude || 
            !$this->delivery_latitude || !$this->delivery_longitude) {
            return null;
        }

        return GeolocationService::calculateDistance(
            $this->current_latitude,
            $this->current_longitude,
            $this->delivery_latitude,
            $this->delivery_longitude
        );
    }

    public function getEstimatedTimeRemaining()
    {
        $distance = $this->getDistanceToDelivery();
        if ($distance === null) {
            return null;
        }

        // Estimation: 50 km/h en moyenne en ville
        $averageSpeed = 50; // km/h
        $hours = $distance / $averageSpeed;
        
        return now()->addHours($hours);
    }

    public function markAsPickedUp()
    {
        $this->update([
            'status' => 'picked_up',
            'picked_up_at' => now(),
        ]);
    }

    public function markAsDelivered()
    {
        $this->update([
            'status' => 'delivered',
            'delivered_at' => now(),
        ]);
    }

    public function scopeForDeliveryPerson($query, $deliveryPersonId)
    {
        return $query->where('delivery_person_id', $deliveryPersonId);
    }

    public function scopeWithStatus($query, $status)
    {
        return $query->where('status', $status);
    }
}
