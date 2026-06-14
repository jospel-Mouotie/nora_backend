import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../widgets/auth/auth_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isEmailSent = false;

  Future<void> _handleSendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simuler l'envoi (à remplacer par vrai appel API)
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isLoading = false;
      _isEmailSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône et titre
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Mot de passe oublié ?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Entrez votre email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              if (!_isEmailSent) ...[
                // Formulaire
                Form(
                  key: _formKey,
                  child: AuthTextField(
                    label: 'Email',
                    hint: 'exemple@email.com',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email requis';
                      }
                      if (!value.contains('@')) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 32),
                
                // Bouton envoyer
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
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
                      : const Text(
                          'Envoyer le lien',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ] else ...[
                // Message de succès
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 64, color: AppColors.success),
                      const SizedBox(height: 16),
                      Text(
                        'Email envoyé !',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nous avons envoyé un lien de réinitialisation à ${_emailController.text}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Bouton retour
                ElevatedButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Retour à la connexion',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Lien retour
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vous vous souvenez ? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: Text(
                      'Se connecter',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}