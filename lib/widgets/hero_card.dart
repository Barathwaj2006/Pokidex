import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeroCard extends StatelessWidget {
  final String title;
  final String progressPercent;
  final String subtitle;
  final String highlightText;
  final VoidCallback onAction;

  const HeroCard({
    super.key,
    required this.title,
    required this.progressPercent,
    required this.subtitle,
    required this.highlightText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(AppRadius.heroCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkSurface.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.electric_bolt,
                      size: 16,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onAction,
                icon: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                progressPercent,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (double.tryParse(progressPercent.replaceAll('%', '')) ?? 84) / 100.0,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              color: AppColors.primaryAccent,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Text(
                highlightText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}