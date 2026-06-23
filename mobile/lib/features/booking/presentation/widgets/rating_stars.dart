import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Renders a 0–5 star rating with optional review count.
class RatingStars extends StatelessWidget {
  const RatingStars({
    required this.rating,
    this.count,
    this.size = 16,
    super.key,
  });

  final double rating;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : (rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded),
            color: AppColors.star,
            size: size,
          ),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: size - 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(color: AppColors.textTertiary, fontSize: size - 3),
          ),
        ],
      ],
    );
  }
}
