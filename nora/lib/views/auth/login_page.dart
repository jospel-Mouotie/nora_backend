import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/language_service.dart';
import '../../services/fcm_service.dart';
import '../../widgets/auth/social_login_buttons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('📥 Login result: $result');

      if (result['success']) {
        // Sauvegarder le token
        await StorageService().setToken(result['token']);
        // Sauvegarder l'utilisateur
        final user = result['user'];
        if (user != null) {
          await StorageService().setUser(
            user is Map ? jsonEncode(user) : jsonEncode((user as dynamic).toJson()),
          );
        }
        
        print('✅ Token sauvegardé: ${result['token']}');
        
        // Synchroniser les intérêts locaux si existants
        await StorageService().syncInterestsWithApi(result['token']);
        
        // Synchroniser le token FCM pour les notifications push
        await FcmService().syncToken();
        
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? _languageService.translate('email_or_password_incorrect');
        });
      }
    } catch (e) {
      print('❌ Login error: $e');
      setState(() {
        _errorMessage = '${_languageService.translate('server_error')}: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Partie supérieure verte
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.shopping_bag,
                            size: 35,
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'NORA',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'MARKETPLACE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Partie inférieure blanche
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  
                  Text(
                    _languageService.translate('sign_in'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    _languageService.translate('please_enter_email'),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Message d'erreur
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Formulaire
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'demo@gmail.com',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _languageService.translate('email_required');
                            }
                            if (!value.contains('@')) {
                              return _languageService.translate('email_invalid');
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.border),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return _languageService.translate('password_required');
                            }
                            if (value.length < 6) {
                              return _languageService.translate('password_min_length');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        context.push('/forgot-password');
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        _languageService.translate('forgot_password'),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _languageService.translate('sign_in'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  const SocialLoginButtons(),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _languageService.translate('dont_have_account'),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          _languageService.translate('sign_up'),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
