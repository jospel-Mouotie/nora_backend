import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

enum VariantType { color, size, text }

class VariantSelector extends StatelessWidget {
  final String title;
  final List<dynamic> variants;
  final VariantType type;
  final Function(Map<String, dynamic>) onVariantSelected;

  const VariantSelector({
    super.key,
    required this.title,
    required this.variants,
    required this.type,
    required this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: variants.map((variant) {
            final isSelected = false; // À gérer avec un state
            return GestureDetector(
              onTap: () => onVariantSelected(variant),
              child: type == VariantType.color
                  ? _buildColorVariant(variant, isSelected)
                  : _buildTextVariant(variant, isSelected),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorVariant(dynamic variant, bool isSelected) {
    final colorCode = variant['code'] ?? variant['color_code'] ?? '#000000';
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(int.parse('0xFF${colorCode.replaceFirst('#', '')}')),
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 20, color: Colors.white)
          : null,
    );
  }

  Widget _buildTextVariant(dynamic variant, bool isSelected) {
    final name = variant['name'] ?? variant['size'] ?? variant.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : AppColors.backgroundLight,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}