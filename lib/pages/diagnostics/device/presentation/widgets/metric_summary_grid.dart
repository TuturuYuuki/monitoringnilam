import 'package:flutter/material.dart';
import 'package:monitoring/pages/diagnostics/device/domain/device_diagnostics_metric.dart';

class MetricSummaryGrid extends StatelessWidget {
  final bool isMobile;
  final List<DeviceDiagnosticsMetric> metrics;

  const MetricSummaryGrid({
    super.key,
    required this.isMobile,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final cards = metrics;

    if (cards.length < 4) {
      return const SizedBox.shrink();
    }

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _MetricSummaryCard(data: cards[0])),
              const SizedBox(width: 8),
              Expanded(child: _MetricSummaryCard(data: cards[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _MetricSummaryCard(data: cards[2])),
              const SizedBox(width: 8),
              Expanded(child: _MetricSummaryCard(data: cards[3])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _MetricSummaryCard(data: cards[0])),
        const SizedBox(width: 12),
        Expanded(child: _MetricSummaryCard(data: cards[1])),
        const SizedBox(width: 12),
        Expanded(child: _MetricSummaryCard(data: cards[2])),
        const SizedBox(width: 12),
        Expanded(child: _MetricSummaryCard(data: cards[3])),
      ],
    );
  }
}

class _MetricSummaryCard extends StatelessWidget {
  final DeviceDiagnosticsMetric data;

  const _MetricSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: data.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withValues(alpha: 0.6),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
