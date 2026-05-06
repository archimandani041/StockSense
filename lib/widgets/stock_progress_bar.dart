import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StockProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String status;
  final double height;
  final double radius;

  const StockProgressBar({
    super.key,
    required this.value,
    required this.status,
    this.height = 6,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: AppColors.surfaceGray,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getColor(),
          ),
        ),
      ),
    );
  }

  Color _getColor() {
    switch (status.toUpperCase()) {
      case 'NORMAL':
        return AppColors.emerald;
      case 'LOW':
        return AppColors.warning;
      case 'CRITICAL':
        return AppColors.critical;
      default:
        return AppColors.primary;
    }
  }
}

class GradientProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String status;
  final double height;
  final double radius;

  const GradientProgressBar({
    super.key,
    required this.value,
    required this.status,
    this.height = 6,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final filledWidth =
            (constraints.maxWidth * value.clamp(0.0, 1.0));
        return Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: AppColors.surfaceGray,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              width: filledWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: AppColors.progressGradient(status),
              ),
            ),
          ),
        );
      },
    );
  }
}
