import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.backgroundLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}