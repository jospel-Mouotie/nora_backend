<?php

namespace App\Http\Controllers;

use App\Models\Delivery;
use App\Models\DeliveryTracking;
use App\Models\Order;
use App\Models\User;
use App\Services\GeolocationService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use App\Traits\ApiResponse;

class DeliveryController extends Controller
{
    use ApiResponse;

    /**
     * Créer une nouvelle livraison
     */
    public function store(Request $request): JsonResponse
    {
        if ($error = $this->validateRequestData($request->all(), [
            'order_id' => 'required|exists:orders,id',
            'delivery_address' => 'required|string|max:500',
            'delivery_fee' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string|max:1000',
        ])) {
            return $error;
        }

        $order = Order::findOrFail($request->order_id);
        
        // Géocoder l'adresse de livraison
        $coordinates = GeolocationService::geocodeAddress($request->delivery_address);
        
        if (!$coordinates) {
            return $this->errorResponse('Impossible de géolocaliser l\'adresse de livraison', 400);
        }

        $delivery = Delivery::create([
            'order_id' => $request->order_id,
            'delivery_address' => $request->delivery_address,
            'delivery_fee' => $request->delivery_fee ?? 0,
            'notes' => $request->notes,
            'delivery_latitude' => $coordinates['latitude'],
            'delivery_longitude' => $coordinates['longitude'],
            'status' => 'assigned',
            'estimated_delivery_at' => now()->addHours(2),
        ]);

        return $this->createdResponse(
            ['delivery' => $delivery->load('order')],
            'Livraison créée avec succès'
        );
    }

    /**
     * Mettre à jour la position actuelle du livreur
     */
    public function updateLocation(Request $request, Delivery $delivery): JsonResponse
    {
        if ($error = $this->validateRequestData($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
        ])) {
            return $error;
        }

        $delivery->updateCurrentLocation($request->latitude, $request->longitude);

        return $this->successResponse(
            ['delivery' => $delivery],
            'Position mise à jour'
        );
    }

    /**
     * Assigner un livreur à une livraison
     */
    public function assignDeliveryPerson(Request $request, Delivery $delivery): JsonResponse
    {
        if ($error = $this->validateRequestData($request->all(), [
            'delivery_person_id' => 'required|exists:users,id',
        ])) {
            return $error;
        }

        $deliveryPerson = User::findOrFail($request->delivery_person_id);
        
        // Vérifier que l'utilisateur est un livreur
        if ($deliveryPerson->role !== 'livreur' && $deliveryPerson->role !== 'delivery_person') {
            return $this->errorResponse('Cet utilisateur n\'est pas un livreur', 400);
        }

        $delivery->update([
            'delivery_person_id' => $request->delivery_person_id,
            'status' => 'assigned',
        ]);

        return $this->successResponse(
            ['delivery' => $delivery->load('deliveryPerson')],
            'Livreur assigné avec succès'
        );
    }

    /**
     * Marquer la livraison comme prise en charge
     */
    public function markAsPickedUp(Delivery $delivery): JsonResponse
    {
        if ($delivery->status !== 'assigned') {
            return $this->errorResponse('Cette livraison ne peut pas être marquée comme prise en charge', 400);
        }

        $delivery->markAsPickedUp();

        return $this->successResponse(
            ['delivery' => $delivery],
            'Livraison marquée comme prise en charge'
        );
    }

    /**
     * Marquer la livraison comme terminée
     */
    public function markAsDelivered(Delivery $delivery): JsonResponse
    {
        if ($delivery->status !== 'in_transit' && $delivery->status !== 'picked_up') {
            return $this->errorResponse('Cette livraison ne peut pas être marquée comme terminée', 400);
        }

        $delivery->markAsDelivered();

        return $this->successResponse(
            ['delivery' => $delivery],
            'Livraison marquée comme terminée'
        );
    }

    /**
     * Obtenir les détails d'une livraison avec informations de suivi
     */
    public function show(Delivery $delivery): JsonResponse
    {
        $delivery->load(['order', 'deliveryPerson', 'tracking']);

        $data = [
            'delivery' => $delivery,
            'distance_to_delivery' => $delivery->getDistanceToDelivery(),
            'estimated_time_remaining' => $delivery->getEstimatedTimeRemaining(),
            'tracking_history' => $delivery->tracking()->latest()->get(),
        ];

        // Si les coordonnées sont disponibles, calculer l'itinéraire
        if ($delivery->current_latitude && $delivery->current_longitude &&
            $delivery->delivery_latitude && $delivery->delivery_longitude) {
            
            $route = GeolocationService::calculateRoute(
                $delivery->current_latitude,
                $delivery->current_longitude,
                $delivery->delivery_latitude,
                $delivery->delivery_longitude
            );

            $data['route'] = $route;
        }

        return response()->json($data);
    }

    /**
     * Obtenir les livraisons d'un livreur
     */
    public function getDeliveryPersonDeliveries(Request $request): JsonResponse
    {
        if ($error = $this->validateRequestData($request->all(), [
            'delivery_person_id' => 'required|exists:users,id',
            'status' => 'nullable|in:assigned,picked_up,in_transit,delivered,cancelled',
        ])) {
            return $error;
        }

        $query = Delivery::forDeliveryPerson($request->delivery_person_id)
            ->with('order');

        if ($request->status) {
            $query->withStatus($request->status);
        }

        $deliveries = $query->orderBy('created_at', 'desc')->get();

        return response()->json(['deliveries' => $deliveries]);
    }

    /**
     * Trouver les livreurs disponibles à proximité
     */
    public function findNearbyDeliveryPersons(Request $request): JsonResponse
    {
        if ($error = $this->validateRequestData($request->all(), [
            'latitude' => 'required|numeric|between:-90,90',
            'longitude' => 'required|numeric|between:-180,180',
            'radius_km' => 'nullable|numeric|min:1|max:50',
        ])) {
            return $error;
        }

        $radiusKm = $request->radius_km ?? 10;
        $nearbyDeliveryPersons = GeolocationService::findNearbyDeliveryPersons(
            $request->latitude,
            $request->longitude,
            $radiusKm
        );

        return response()->json([
            'nearby_delivery_persons' => $nearbyDeliveryPersons,
            'total_found' => count($nearbyDeliveryPersons)
        ]);
    }

    /**
     * Obtenir les statistiques de livraison
     */
    public function getStats(Request $request): JsonResponse
    {
        if ($error = $this->validateRequestData($request->all(), [
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ])) {
            return $error;
        }

        $query = Delivery::query();

        if ($request->start_date) {
            $query->whereDate('created_at', '>=', $request->start_date);
        }

        if ($request->end_date) {
            $query->whereDate('created_at', '<=', $request->end_date);
        }

        $stats = [
            'total_deliveries' => $query->count(),
            'delivered' => $query->where('status', 'delivered')->count(),
            'in_transit' => $query->where('status', 'in_transit')->count(),
            'picked_up' => $query->where('status', 'picked_up')->count(),
            'assigned' => $query->where('status', 'assigned')->count(),
            'cancelled' => $query->where('status', 'cancelled')->count(),
            'total_revenue' => $query->sum('delivery_fee'),
        ];

        return response()->json($stats);
    }

    /**
     * Annuler une livraison
     */
    public function cancel(Delivery $delivery): JsonResponse
    {
        if (in_array($delivery->status, ['delivered', 'cancelled'])) {
            return $this->errorResponse('Cette livraison ne peut pas être annulée', 400);
        }

        $delivery->update(['status' => 'cancelled']);

        return $this->successResponse(
            ['delivery' => $delivery],
            'Livraison annulée'
        );
    }
}
