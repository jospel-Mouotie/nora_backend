import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../config/app_colors.dart';

class DeliveryMap extends StatefulWidget {
  final double? pickupLat;
  final double? pickupLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final double? driverLat;
  final double? driverLng;
  final Function(LatLng)? onMapTap;

  const DeliveryMap({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.deliveryLat,
    this.deliveryLng,
    this.driverLat,
    this.driverLng,
    this.onMapTap,
  });

  @override
  State<DeliveryMap> createState() => _DeliveryMapState();
}

class _DeliveryMapState extends State<DeliveryMap> {
  final MapController _mapController = MapController();

  LatLng? _pickupPosition;
  LatLng? _deliveryPosition;
  LatLng? _driverPosition;

  // Centre par défaut (Yaoundé, Cameroun)
  static const LatLng _defaultCenter = LatLng(3.8480, 11.5021);
  static const double _defaultZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _updatePositions();
  }

  @override
  void didUpdateWidget(DeliveryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updatePositions();
  }

  void _updatePositions() {
    setState(() {
      _pickupPosition = (widget.pickupLat != null && widget.pickupLng != null)
          ? LatLng(widget.pickupLat!, widget.pickupLng!)
          : null;
      _deliveryPosition = (widget.deliveryLat != null && widget.deliveryLng != null)
          ? LatLng(widget.deliveryLat!, widget.deliveryLng!)
          : null;
      _driverPosition = (widget.driverLat != null && widget.driverLng != null)
          ? LatLng(widget.driverLat!, widget.driverLng!)
          : null;

      _animateCamera();
    });
  }

  void _animateCamera() {
    LatLng? center;

    if (_driverPosition != null && _deliveryPosition != null) {
      // Centrer entre le livreur et la destination
      center = LatLng(
        (_driverPosition!.latitude + _deliveryPosition!.latitude) / 2,
        (_driverPosition!.longitude + _deliveryPosition!.longitude) / 2,
      );
    } else if (_deliveryPosition != null) {
      center = _deliveryPosition;
    } else if (_pickupPosition != null) {
      center = _pickupPosition;
    } else if (_driverPosition != null) {
      center = _driverPosition;
    }

    if (center != null) {
      _mapController.move(center, _defaultZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Collecter tous les marqueurs
    final List<Marker> markers = [];

    // Marqueur ramassage (vert)
    if (_pickupPosition != null) {
      markers.add(
        Marker(
          point: _pickupPosition!,
          width: 40,
          height: 40,
          child: _buildMarkerIcon(Icons.location_on, Colors.green),
        ),
      );
    }

    // Marqueur livraison (rouge)
    if (_deliveryPosition != null) {
      markers.add(
        Marker(
          point: _deliveryPosition!,
          width: 40,
          height: 40,
          child: _buildMarkerIcon(Icons.location_on, Colors.red),
        ),
      );
    }

    // Marqueur livreur (bleu)
    if (_driverPosition != null) {
      markers.add(
        Marker(
          point: _driverPosition!,
          width: 40,
          height: 40,
          child: _buildMarkerIcon(Icons.delivery_dining, AppColors.primary),
        ),
      );
    }

    // Polyline (trajet entre livreur et destination)
    final List<LatLng> polylinePoints = [];
    if (_driverPosition != null && _deliveryPosition != null) {
      polylinePoints.addAll([_driverPosition!, _deliveryPosition!]);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _getInitialCenter(),
        initialZoom: _defaultZoom,
        onTap: (tapPosition, point) {
          if (widget.onMapTap != null) {
            widget.onMapTap!(point);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.nora',
        ),
        if (polylinePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polylinePoints,
                color: AppColors.primary,
                strokeWidth: 4,
              ),
            ],
          ),
        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }

  Widget _buildMarkerIcon(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  LatLng _getInitialCenter() {
    if (_driverPosition != null) return _driverPosition!;
    if (_deliveryPosition != null) return _deliveryPosition!;
    if (_pickupPosition != null) return _pickupPosition!;
    return _defaultCenter;
  }
}
