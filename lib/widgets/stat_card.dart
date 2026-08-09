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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(icon, size: 16, color: effectiveIconColor),
              ),
              if (subtitle != null)
                Flexible(
                  child: Text(
                    subtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    letterSpacing: -0.5,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 3),
                  Text(
                    unit!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}