import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DiagnosticsLineChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FlSpot> spots;
  final Color color;
  final bool showPercentInLeftAxis;

  const DiagnosticsLineChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.spots,
    required this.color,
    this.showPercentInLeftAxis = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartFrame(
      title: title,
      subtitle: subtitle,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: Colors.white24),
              left: BorderSide(color: Colors.white24),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: showPercentInLeftAxis ? 28 : 32,
                getTitlesWidget: (value, meta) {
                  final label = showPercentInLeftAxis
                      ? '${value.toInt()}%'
                      : value.toInt().toString();

                  return Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: !showPercentInLeftAxis,
                reservedSize: 20,
                getTitlesWidget: (value, meta) => const SizedBox.shrink(),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: color,
              barWidth: 3,
              spots: spots,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2631),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Last 1h',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
