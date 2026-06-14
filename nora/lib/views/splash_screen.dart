import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Attendre 2 secondes pour l'affichage du splash
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Vérifier si l'onboarding a déjà été vu
      final onboardingCompleted = await StorageService().isOnboardingCompleted();
      
      if (!onboardingCompleted) {
        context.go('/onboarding');
      } else {
        final interestsSelected = await StorageService().areInterestsSelected();
        
        if (!interestsSelected) {
          context.go('/interests');
        } else {
          final token = await StorageService().getToken();
          
          if (token != null && token.isNotEmpty) {
            context.go(AppRoutes.home);
          } else {
            context.go(AppRoutes.home); // Toujours vers home, pas login
          }
        }
      }
    } catch (e) {
      print('Erreur: $e');
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Fond vert principal
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec fond blanc
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.shopping_bag,
                      size: 50,
                      color: AppColors.primary,
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Texte N°RA en blanc
            const Text(
              'N°RA',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Texte MARKETPLACE en blanc transparent
            const Text(
              'MARKETPLACE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                letterSpacing: 1.5,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Slogan
            Text(
              'Acheter en détail au prix de gros',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Indicateur de chargement blanc
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}