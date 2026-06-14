import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final Function(int) onQuantityChanged;
  final int minQuantity;
  final int maxQuantity;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
    this.minQuantity = 1,
    this.maxQuantity = 99,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Quantité',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: quantity > minQuantity
                    ? () => onQuantityChanged(quantity - 1)
                    : null,
                icon: const Icon(Icons.remove, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  quantity.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: quantity < maxQuantity
                    ? () => onQuantityChanged(quantity + 1)
                    : null,
                icon: const Icon(Icons.add, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40),
              ),
            ],
          ),
        ),
      ],
    );
  }
}