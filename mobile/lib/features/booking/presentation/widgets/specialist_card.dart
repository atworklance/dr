import 'package:flutter/material.dart';

import '../../../../core/entities/consultation_mode.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/specialist.dart';
import 'rating_stars.dart';

/// A premium directory row for a specialist: avatar, name, specialty, rating,
/// mode badges, starting price, and a clear tap affordance.
class SpecialistCard extends StatelessWidget {
  const SpecialistCard({
    required this.specialist,
    required this.onTap,
    super.key,
  });

  final Specialist specialist;
  final VoidCallback onTap;

  String get _initials {
    final parts = specialist.displayName
        .replaceAll(RegExp('^(dr\\.?|prof\\.?)\\s*', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  int get _startingFee {
    if (specialist.offersOnline && specialist.offersClinic) {
      return specialist.pricing.onlineFee < specialist.pricing.clinicFee
          ? specialist.pricing.onlineFee
          : specialist.pricing.clinicFee;
    }
    return specialist.offersOnline
        ? specialist.pricing.onlineFee
        : specialist.pricing.clinicFee;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          onTap: specialist.isBookable ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            specialist.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _titleCase(specialist.primarySpecialty),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          RatingStars(
                            rating: specialist.ratingAverage,
                            count: specialist.ratingCount,
                          ),
                        ],
                      ),
                    ),
                    if (!specialist.isBookable)
                      const _Badge(
                        label: 'Unavailable',
                        color: AppColors.textTertiary,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    for (final mode in specialist.consultationModes) ...[
                      _ModeBadge(mode: mode),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    const Spacer(),
                    Text(
                      'from ',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      Formatters.money(_startingFee, specialist.pricing.currency),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _titleCase(String value) => value
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});

  final ConsultationMode mode;

  @override
  Widget build(BuildContext context) {
    final bool online = mode == ConsultationMode.online;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online ? Icons.videocam_rounded : Icons.local_hospital_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            online ? 'Online' : 'Clinic',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
