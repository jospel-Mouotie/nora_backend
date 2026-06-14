import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../widgets/auth/social_login_buttons.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String _selectedRole = 'client';

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.register(
        name: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        role: _selectedRole,
        phone: _phoneController.text.trim(),
      );

      if (result['success'] || result['message'] == 'Code de validation envoyé à votre email') {
        // Naviguer vers la page de validation de code
        if (mounted) {
          context.push(
            '/email-verification',
            extra: {
              'email': _emailController.text.trim(),
              'name': _usernameController.text.trim(),
            },
          );
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? _languageService.translate('registration_error');
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = _languageService.translate('server_error');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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
            height: MediaQuery.of(context).size.height * 0.30,
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
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
                            color: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NORA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const Text(
                    'MARKETPLACE',
                    style: TextStyle(
                      fontSize: 10,
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
                  const SizedBox(height: 24),
                  
                  Text(
                    _languageService.translate('sign_up'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
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
                  
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            hintText: 'Masum Ahmed',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
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
                              return _languageService.translate('username_required');
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
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
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '+8801724585546',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
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
                              return _languageService.translate('phone_required');
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: _languageService.translate('role'),
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
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
                          items:[
                            DropdownMenuItem(
                              value: 'client',
                              child: Text(_languageService.translate('role_client')),
                            ),
                            DropdownMenuItem(
                              value: 'commercant',
                              child: Text(_languageService.translate('role_merchant')),
                            ),
                            DropdownMenuItem(
                              value: 'livreur',
                              child: Text(_languageService.translate('role_driver')),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value ?? 'client';
                            });
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
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
                        
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            hintText: '••••••••',
                            prefixIcon: const Icon(Icons.lock_outline, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
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
                              return _languageService.translate('confirm_password_required');
                            }
                            if (value != _passwordController.text) {
                              return _languageService.translate('passwords_not_match');
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
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
                              _languageService.translate('sign_up'),
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
                        _languageService.translate('already_have_account'),
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          context.push('/login');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          _languageService.translate('sign_in'),
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
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}