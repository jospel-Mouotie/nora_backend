import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../services/storage_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _images = [
    'assets/images/1.png',
    'assets/images/2.png',
    'assets/images/3.png',
    'assets/images/4.png',
  ];

  final List<Map<String, String>> _contents = [
    {
      'title': 'ACHETEZ',
      'description': 'Découvrez des milliers de produits uniques auprès de boutiques fiables au meilleur prix.',
    },
    {
      'title': 'VENDEZ',
      'description': 'Créez votre boutique en ligne gratuitement et vendez vos produits à des millions de clients.',
    },
    {
      'title': 'GAGNEZ',
      'description': 'Gagnez des MB Coins à chaque achat et échangez-les contre des avantages exclusifs.',
    },
    {
      'title': 'Boutiques vérifiées',
      'description': 'Achetez en toute sérénité avec nos boutiques certifiées et notre système de paiement sécurisé.',
    },
  ];

  void _goToNextPage() {
    if (_currentPage < _images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Images plein écran
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: screenWidth,
                height: screenHeight,
                child: Image.asset(
                  _images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          // Contenu au-dessus de l'image
          SafeArea(
            child: Column(
              children: [
                // Header avec boutons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton Précédent
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: _goToPreviousPage,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.arrow_back_ios, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Précédent',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(width: 80),
                      
                      // Bouton Passer
                      if (_currentPage < _images.length - 1)
                        TextButton(
                          onPressed: () async {
                            await StorageService().setOnboardingCompleted(true);
                            if (mounted) {
                              context.go(AppRoutes.interests);
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Passer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 60),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Logo N°RA
                Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.shopping_bag,
                              size: 30,
                              color: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'N°RA',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'MARKETPLACE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Indicateurs de page
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: _currentPage == index ? 28 : 8,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppColors.primaryLight
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Titre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _contents[_currentPage]['title']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                      shadows: const [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _contents[_currentPage]['description']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.95),
                      height: 1.4,
                      shadows: const [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black26,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Bouton Suivant / Commencer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentPage < _images.length - 1) {
                          _goToNextPage();
                        } else {
                          await StorageService().setOnboardingCompleted(true);
                          if (mounted) {
                            context.go(AppRoutes.interests);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage < _images.length - 1 ? 'Suivant' : 'Commencer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_currentPage < _images.length - 1)
                            const SizedBox(width: 8),
                          if (_currentPage < _images.length - 1)
                            const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}