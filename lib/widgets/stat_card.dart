import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? unit;
  final String? subtitle;
  final Color? iconColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit,
    this.subtitle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(icon, size: 18, color: effectiveIconColor),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                  letterSpacing: -0.5,
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  unit!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}