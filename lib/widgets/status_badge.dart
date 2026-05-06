import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;

    switch (status.toUpperCase()) {
      case 'NORMAL':
        color = AppColors.emerald;
        bg = AppColors.emerald.withOpacity(0.1);
        break;
      case 'LOW':
        color = AppColors.warning;
        bg = AppColors.warning.withOpacity(0.1);
        break;
      case 'CRITICAL':
        color = AppColors.critical;
        bg = AppColors.critical.withOpacity(0.1);
        break;
      default:
        color = AppColors.textSecondary;
        bg = AppColors.surfaceGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
