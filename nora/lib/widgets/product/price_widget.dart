import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../utils/converters.dart';

class PriceWidget extends StatelessWidget {
  final dynamic price;
  final dynamic comparePrice;

  const PriceWidget({
    super.key,
    required this.price,
    this.comparePrice,
  });

  @override
  Widget build(BuildContext context) {
    final priceDouble = toDoubleSafe(price);
    final comparePriceDouble = toDoubleSafe(comparePrice);
    final hasDiscount = comparePriceDouble > 0 && comparePriceDouble > priceDouble;
    final discountPercent = hasDiscount
        ? ((comparePriceDouble - priceDouble) / comparePriceDouble * 100).toInt()
        : null;

    return Row(
      children: [
        Text(
          '${priceDouble.toInt().toString().replaceAll('.0', '')} FCFA',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '${comparePriceDouble.toInt().toString().replaceAll('.0', '')} FCFA',
            style: TextStyle(
              fontSize: 16,
              decoration: TextDecoration.lineThrough,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.promotion,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '-$discountPercent%',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}