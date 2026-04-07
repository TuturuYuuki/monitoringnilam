import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

class RadialGaugeCard extends StatelessWidget {
  final String title;
  final double value;
  final double maxValue;
  final String suffix;
  final double threshold;

  const RadialGaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.maxValue,
    required this.suffix,
    required this.threshold,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, maxValue).toDouble();
    final double percent =
        maxValue == 0 ? 0.0 : (clamped / maxValue).toDouble();
    final double warnRatio =
        maxValue == 0 ? 1.0 : (threshold / maxValue).clamp(0.0, 1.0).toDouble();

    final activeColor = clamped >= threshold
        ? const Color(0xFFE53935)
        : const Color(0xFF43A047);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.62)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF87C5FF).withValues(alpha: 0.12),
                blurRadius: 22,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(
                        Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    CircularProgressIndicator(
                      value: warnRatio,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFFFA726)),
                    ),
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation(activeColor),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            clamped.toStringAsFixed(suffix == '%' ? 0 : 1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            suffix,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Threshold: ${threshold.toStringAsFixed(suffix == '%' ? 0 : 1)}$suffix',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
