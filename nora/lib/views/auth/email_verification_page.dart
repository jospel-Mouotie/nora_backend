import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../../services/fcm_service.dart';

class EmailVerificationPage extends StatefulWidget {
  final String email;
  final String name;

  const EmailVerificationPage({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  final AuthService _authService = AuthService();
  final LanguageService _languageService = LanguageService();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
        return true;
      }
      return false;
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeControllers.map((c) => c.text).join();
    
    if (code.length != 6) {
      setState(() => _errorMessage = _languageService.translate('enter_code'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.verifyCode(
        email: widget.email,
        code: code,
      );

      if (response['success']) {
        // Stocker le token et les données utilisateur
        await StorageService().setToken(response['token']);
        await StorageService().setUser(jsonEncode(response['user']));

        // Synchroniser le token FCM pour les notifications
        await FcmService().syncToken();

        if (mounted) {
          context.go('/interests');
        }
      } else {
        setState(() => _errorMessage = response['message'] ?? _languageService.translate('code_incorrect'));
      }
    } catch (e) {
      setState(() => _errorMessage = _languageService.translate('server_error'));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCountdown > 0) return;

    setState(() => _isResending = true);

    try {
      final response = await _authService.resendCode(email: widget.email);

      if (response['success']) {
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_languageService.translate('new_code_sent')),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        setState(() => _errorMessage = response['message'] ?? _languageService.translate('server_error'));
      }
    } catch (e) {
      setState(() => _errorMessage = _languageService.translate('server_error'));
    } finally {
      setState(() => _isResending = false);
    }
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 24),
            Text(
              _languageService.translate('verify_email'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_languageService.translate('verify_email_description')} ${widget.email}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            // Code input fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onCodeChanged(index, value),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _languageService.translate('validate'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: _isResending || _resendCountdown > 0
                    ? null
                    : _resendCode,
                child: _isResending
                    ? const CircularProgressIndicator(color: AppColors.primary)
                    : Text(
                        _resendCountdown > 0
                            ? '${_languageService.translate('resend_in')} $_resendCountdown ${_languageService.translate('seconds')}'
                            : _languageService.translate('resend_code'),
                        style: TextStyle(
                          color: _resendCountdown > 0
                              ? AppColors.textTertiary
                              : AppColors.primary,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
