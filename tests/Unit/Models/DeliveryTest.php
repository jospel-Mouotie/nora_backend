<?php

namespace Tests\Unit\Models;

use App\Models\Delivery;
use Carbon\Carbon;
use PHPUnit\Framework\TestCase;

class DeliveryTest extends TestCase
{
    private function makeDelivery(array $attributes = []): Delivery
    {
        $delivery = new Delivery;
        $delivery->setRawAttributes($attributes);

        return $delivery;
    }

    public function test_get_distance_to_delivery_returns_null_without_current_coords(): void
    {
        $delivery = $this->makeDelivery([
            'current_latitude' => null,
            'current_longitude' => null,
            'delivery_latitude' => 48.8566,
            'delivery_longitude' => 2.3522,
        ]);

        $this->assertNull($delivery->getDistanceToDelivery());
    }

    public function test_get_distance_to_delivery_returns_null_without_destination_coords(): void
    {
        $delivery = $this->makeDelivery([
            'current_latitude' => 48.8566,
            'current_longitude' => 2.3522,
            'delivery_latitude' => null,
            'delivery_longitude' => null,
        ]);

        $this->assertNull($delivery->getDistanceToDelivery());
    }

    public function test_get_distance_to_delivery_calculates_distance(): void
    {
        $delivery = $this->makeDelivery([
            'current_latitude' => 48.8566,
            'current_longitude' => 2.3522,
            'delivery_latitude' => 48.8700,
            'delivery_longitude' => 2.3600,
        ]);

        $distance = $delivery->getDistanceToDelivery();

        $this->assertNotNull($distance);
        $this->assertIsFloat($distance);
        $this->assertGreaterThan(0, $distance);
        // These coordinates are close, distance should be < 5 km
        $this->assertLessThan(5, $distance);
    }

    public function test_get_distance_to_delivery_same_location_returns_zero(): void
    {
        $delivery = $this->makeDelivery([
            'current_latitude' => 48.8566,
            'current_longitude' => 2.3522,
            'delivery_latitude' => 48.8566,
            'delivery_longitude' => 2.3522,
        ]);

        $distance = $delivery->getDistanceToDelivery();

        $this->assertEqualsWithDelta(0, $distance, 0.001);
    }

    public function test_get_estimated_time_remaining_returns_null_without_coords(): void
    {
        $delivery = $this->makeDelivery([
            'current_latitude' => null,
            'current_longitude' => null,
            'delivery_latitude' => null,
            'delivery_longitude' => null,
        ]);

        $this->assertNull($delivery->getEstimatedTimeRemaining());
    }

    public function test_get_estimated_time_remaining_returns_carbon_instance(): void
    {
        // Use distant coordinates (~343km apart) for a meaningful ETA
        $delivery = $this->makeDelivery([
            'current_latitude' => 48.8566,
            'current_longitude' => 2.3522,
            'delivery_latitude' => 51.5074,
            'delivery_longitude' => -0.1278,
        ]);

        $eta = $delivery->getEstimatedTimeRemaining();

        $this->assertNotNull($eta);
        $this->assertInstanceOf(Carbon::class, $eta);
        $this->assertTrue($eta->isFuture());
    }

    public function test_fillable_contains_expected_fields(): void
    {
        $delivery = new Delivery;

        $this->assertContains('status', $delivery->getFillable());
        $this->assertContains('delivery_fee', $delivery->getFillable());
        $this->assertContains('order_id', $delivery->getFillable());
        $this->assertContains('delivery_person_id', $delivery->getFillable());
        $this->assertContains('pickup_latitude', $delivery->getFillable());
        $this->assertContains('delivery_latitude', $delivery->getFillable());
    }

    public function test_casts_coordinate_fields(): void
    {
        $delivery = new Delivery;
        $casts = $delivery->getCasts();

        $this->assertEquals('decimal:8', $casts['pickup_latitude']);
        $this->assertEquals('decimal:8', $casts['pickup_longitude']);
        $this->assertEquals('decimal:8', $casts['delivery_latitude']);
        $this->assertEquals('decimal:8', $casts['delivery_longitude']);
    }

    public function test_casts_datetime_fields(): void
    {
        $delivery = new Delivery;
        $casts = $delivery->getCasts();

        $this->assertEquals('datetime', $casts['picked_up_at']);
        $this->assertEquals('datetime', $casts['delivered_at']);
        $this->assertEquals('datetime', $casts['estimated_delivery_at']);
    }
}
