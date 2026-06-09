<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;

class GeolocationService
{
    /**
     * Calcule la distance entre deux points géographiques en utilisant la formule de Haversine
     */
    public static function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371; // Rayon de la Terre en kilomètres

        $latFrom = deg2rad($lat1);
        $lonFrom = deg2rad($lon1);
        $latTo = deg2rad($lat2);
        $lonTo = deg2rad($lon2);

        $latDelta = $latTo - $latFrom;
        $lonDelta = $lonTo - $lonFrom;

        $a = sin($latDelta / 2) * sin($latDelta / 2) +
             cos($latFrom) * cos($latTo) *
             sin($lonDelta / 2) * sin($lonDelta / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    /**
     * Géocodage d'une adresse en coordonnées GPS (utilise Nominatim - OpenStreetMap - gratuit)
     */
    public static function geocodeAddress($address)
    {
        $cacheKey = 'geocode_' . md5($address);
        
        return Cache::remember($cacheKey, 86400, function () use ($address) {
            try {
                $response = Http::timeout(10)
                    ->get('https://nominatim.openstreetmap.org/search', [
                        'q' => $address,
                        'format' => 'json',
                        'limit' => 1,
                        'addressdetails' => 1,
                    ]);

                if ($response->successful() && !empty($response->json())) {
                    $data = $response->json()[0];
                    
                    return [
                        'latitude' => (float) $data['lat'],
                        'longitude' => (float) $data['lon'],
                        'formatted_address' => $data['display_name'] ?? $address,
                    ];
                }
            } catch (\Exception $e) {
                \Log::error('Geocoding error: ' . $e->getMessage());
            }

            return null;
        });
    }

    /**
     * Géocodage inversé: coordonnées GPS vers adresse
     */
    public static function reverseGeocode($latitude, $longitude)
    {
        $cacheKey = 'reverse_geocode_' . md5($latitude . '_' . $longitude);
        
        return Cache::remember($cacheKey, 86400, function () use ($latitude, $longitude) {
            try {
                $response = Http::timeout(10)
                    ->get('https://nominatim.openstreetmap.org/reverse', [
                        'lat' => $latitude,
                        'lon' => $longitude,
                        'format' => 'json',
                        'addressdetails' => 1,
                    ]);

                if ($response->successful()) {
                    $data = $response->json();
                    
                    return [
                        'address' => $data['display_name'] ?? '',
                        'city' => $data['address']['city'] ?? $data['address']['town'] ?? $data['address']['village'] ?? '',
                        'country' => $data['address']['country'] ?? '',
                        'postcode' => $data['address']['postcode'] ?? '',
                    ];
                }
            } catch (\Exception $e) {
                \Log::error('Reverse geocoding error: ' . $e->getMessage());
            }

            return null;
        });
    }

    /**
     * Calcul d'itinéraire simple (utilise OSRM - Open Source Routing Machine - gratuit)
     */
    public static function calculateRoute($startLat, $startLon, $endLat, $endLon)
    {
        $cacheKey = 'route_' . md5($startLat . '_' . $startLon . '_' . $endLat . '_' . $endLon);
        
        return Cache::remember($cacheKey, 3600, function () use ($startLat, $startLon, $endLat, $endLon) {
            try {
                $response = Http::timeout(15)
                    ->get("https://router.project-osrm.org/route/v1/driving/{$startLon},{$startLat};{$endLon},{$endLat}", [
                        'overview' => 'simplified',
                        'geometries' => 'geojson',
                    ]);

                if ($response->successful() && !empty($response->json()['routes'])) {
                    $route = $response->json()['routes'][0];
                    
                    return [
                        'distance' => $route['distance'] / 1000, // Convert to km
                        'duration' => $route['duration'] / 60, // Convert to minutes
                        'geometry' => $route['geometry'] ?? null,
                    ];
                }
            } catch (\Exception $e) {
                \Log::error('Route calculation error: ' . $e->getMessage());
            }

            // Fallback: calcul simple de distance si l'API échoue
            $distance = self::calculateDistance($startLat, $startLon, $endLat, $endLon);
            $estimatedTime = ($distance / 50) * 60; // 50 km/h average

            return [
                'distance' => $distance,
                'duration' => $estimatedTime,
                'geometry' => null,
            ];
        });
    }

    /**
     * Trouve les livreurs les plus proches d'une position
     */
    public static function findNearbyDeliveryPersons($latitude, $longitude, $radiusKm = 10)
    {
        // Cette méthode suppose que vous avez un modèle User avec les coordonnées des livreurs
        // Vous pouvez l'adapter selon votre structure
        
        $deliveryPersons = \App\Models\User::where('role', 'delivery_person')
            ->whereNotNull('latitude')
            ->whereNotNull('longitude')
            ->get();

        $nearby = [];

        foreach ($deliveryPersons as $person) {
            $distance = self::calculateDistance(
                $latitude, $longitude,
                $person->latitude, $person->longitude
            );

            if ($distance <= $radiusKm) {
                $nearby[] = [
                    'delivery_person' => $person,
                    'distance' => $distance,
                ];
            }
        }

        // Trier par distance croissante
        usort($nearby, function ($a, $b) {
            return $a['distance'] <=> $b['distance'];
        });

        return $nearby;
    }

    /**
     * Valide si des coordonnées GPS sont valides
     */
    public static function isValidCoordinates($latitude, $longitude)
    {
        return is_numeric($latitude) && is_numeric($longitude) &&
               $latitude >= -90 && $latitude <= 90 &&
               $longitude >= -180 && $longitude <= 180;
    }

    /**
     * Formate les coordonnées pour l'affichage
     */
    public static function formatCoordinates($latitude, $longitude)
    {
        return [
            'latitude' => number_format($latitude, 6),
            'longitude' => number_format($longitude, 6),
            'display' => sprintf('%.6f°, %.6f°', $latitude, $longitude),
        ];
    }
}
