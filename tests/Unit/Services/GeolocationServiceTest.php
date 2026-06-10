<?php

namespace Tests\Unit\Services;

use App\Services\GeolocationService;
use PHPUnit\Framework\TestCase;

class GeolocationServiceTest extends TestCase
{
    public function test_calculate_distance_same_point_returns_zero(): void
    {
        $distance = GeolocationService::calculateDistance(48.8566, 2.3522, 48.8566, 2.3522);

        $this->assertEqualsWithDelta(0, $distance, 0.001);
    }

    public function test_calculate_distance_paris_to_london(): void
    {
        // Paris (48.8566, 2.3522) to London (51.5074, -0.1278) ≈ 343 km
        $distance = GeolocationService::calculateDistance(48.8566, 2.3522, 51.5074, -0.1278);

        $this->assertEqualsWithDelta(343, $distance, 5);
    }

    public function test_calculate_distance_new_york_to_los_angeles(): void
    {
        // NYC (40.7128, -74.0060) to LA (34.0522, -118.2437) ≈ 3940 km
        $distance = GeolocationService::calculateDistance(40.7128, -74.0060, 34.0522, -118.2437);

        $this->assertEqualsWithDelta(3940, $distance, 50);
    }

    public function test_calculate_distance_is_symmetric(): void
    {
        $d1 = GeolocationService::calculateDistance(48.8566, 2.3522, 51.5074, -0.1278);
        $d2 = GeolocationService::calculateDistance(51.5074, -0.1278, 48.8566, 2.3522);

        $this->assertEqualsWithDelta($d1, $d2, 0.001);
    }

    public function test_calculate_distance_returns_positive(): void
    {
        $distance = GeolocationService::calculateDistance(0, 0, -10, -10);

        $this->assertGreaterThan(0, $distance);
    }

    public function test_is_valid_coordinates_with_valid_values(): void
    {
        $this->assertTrue(GeolocationService::isValidCoordinates(48.8566, 2.3522));
        $this->assertTrue(GeolocationService::isValidCoordinates(0, 0));
        $this->assertTrue(GeolocationService::isValidCoordinates(-90, -180));
        $this->assertTrue(GeolocationService::isValidCoordinates(90, 180));
    }

    public function test_is_valid_coordinates_with_invalid_latitude(): void
    {
        $this->assertFalse(GeolocationService::isValidCoordinates(91, 0));
        $this->assertFalse(GeolocationService::isValidCoordinates(-91, 0));
    }

    public function test_is_valid_coordinates_with_invalid_longitude(): void
    {
        $this->assertFalse(GeolocationService::isValidCoordinates(0, 181));
        $this->assertFalse(GeolocationService::isValidCoordinates(0, -181));
    }

    public function test_is_valid_coordinates_with_non_numeric(): void
    {
        $this->assertFalse(GeolocationService::isValidCoordinates('abc', 0));
        $this->assertFalse(GeolocationService::isValidCoordinates(0, 'xyz'));
    }

    public function test_format_coordinates(): void
    {
        $result = GeolocationService::formatCoordinates(48.856600, 2.352200);

        $this->assertArrayHasKey('latitude', $result);
        $this->assertArrayHasKey('longitude', $result);
        $this->assertArrayHasKey('display', $result);
        $this->assertEquals('48.856600', $result['latitude']);
        $this->assertEquals('2.352200', $result['longitude']);
        $this->assertStringContainsString('48.856600', $result['display']);
        $this->assertStringContainsString('2.352200', $result['display']);
    }

    public function test_format_coordinates_negative_values(): void
    {
        $result = GeolocationService::formatCoordinates(-33.868820, 151.209290);

        $this->assertEquals('-33.868820', $result['latitude']);
        $this->assertEquals('151.209290', $result['longitude']);
    }

    public function test_format_coordinates_zero(): void
    {
        $result = GeolocationService::formatCoordinates(0, 0);

        $this->assertEquals('0.000000', $result['latitude']);
        $this->assertEquals('0.000000', $result['longitude']);
    }
}
