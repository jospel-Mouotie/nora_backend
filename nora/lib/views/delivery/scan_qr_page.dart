import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../config/app_colors.dart';
import '../../../services/api_service.dart';
import '../../../services/storage_service.dart';

class ScanQrPage extends StatefulWidget {
  final int? deliveryId;

  const ScanQrPage({super.key, this.deliveryId});

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final ApiService _apiService = ApiService();
  final MobileScannerController _scannerController = MobileScannerController();
  
  bool _isProcessing = false;
  bool _isScanning = true;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _processQrCode(String qrCode) async {
    if (!_isScanning || _isProcessing) return;
    
    setState(() {
      _isScanning = false;
      _isProcessing = true;
    });
    
    final token = await StorageService().getToken();
    if (token == null) {
      _showError('Veuillez vous connecter');
      _resetScanner();
      return;
    }
    
    try {
      final result = await _apiService.scanQrCode(qrCode, token);
      
      if (result['success']) {
        _showSuccess('QR code validé !');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            if (widget.deliveryId != null) {
              context.pop();
            } else {
              context.pop(result['delivery']);
            }
          }
        });
      } else {
        _showError(result['message'] ?? 'QR code invalide');
        _resetScanner();
      }
    } catch (e) {
      _showError('Erreur de connexion');
      _resetScanner();
    }
  }

  void _resetScanner() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _isProcessing = false;
        });
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFlashlight() {
    _scannerController.toggleTorch();
  }

  void _switchCamera() {
    _scannerController.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Scanner QR Code',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: _toggleFlashlight,
          ),
          IconButton(
            icon: const Icon(Icons.camera_front, color: Colors.white),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (!_isScanning || _isProcessing) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final code = barcode.rawValue;
                if (code != null && code.isNotEmpty) {
                  _processQrCode(code);
                  break;
                }
              }
            },
          ),
          
          // Overlay pour le cadrage
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: AppColors.primary,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(60),
          ),
          
          // Indicateur de chargement
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Vérification en cours...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          
          // Message en bas
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Scannez le QR code du livreur',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}