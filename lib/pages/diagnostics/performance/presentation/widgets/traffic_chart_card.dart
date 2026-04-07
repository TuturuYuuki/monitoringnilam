import 'dart:ui' show ImageFilter;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class TrafficChartCard extends StatelessWidget {
  final List<FlSpot> rxSpots;
  final List<FlSpot> txSpots;
  final int maxSamples;
  final int refreshSeconds;

  const TrafficChartCard({
    super.key,
    required this.rxSpots,
    required this.txSpots,
    required this.maxSamples,
    required this.refreshSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final double minX = rxSpots.isNotEmpty ? rxSpots.first.x : 0.0;
    final double maxX = rxSpots.isNotEmpty ? rxSpots.last.x : 1.0;

    final allValues = [...rxSpots.map((e) => e.y), ...txSpots.map((e) => e.y)];
    final double maxY = allValues.isEmpty
        ? 10.0
        : (allValues.reduce((a, b) => a > b ? a : b) * 1.2).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
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
              const Text(
                'Traffic Trend (Mbps)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Maksimum $maxSamples sampel terakhir (refresh setiap $refreshSeconds detik)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: LineChart(
                  LineChartData(
                    minX: minX,
                    maxX: maxX == minX ? minX + 1 : maxX,
                    minY: 0,
                    maxY: maxY < 10 ? 10 : maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, _) => Text(
                            value.toInt().toString(),
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        left: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                        bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: rxSpots,
                        isCurved: true,
                        color: const Color(0xFF4FC3F7),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                              const Color(0xFF4FC3F7).withValues(alpha: 0.18),
                        ),
                      ),
                      LineChartBarData(
                        spots: txSpots,
                        isCurved: true,
                        color: const Color(0xFFFFB74D),
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  _LegendDot(color: Color(0xFF4FC3F7), label: 'RX'),
                  SizedBox(width: 16),
                  _LegendDot(color: Color(0xFFFFB74D), label: 'TX'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
