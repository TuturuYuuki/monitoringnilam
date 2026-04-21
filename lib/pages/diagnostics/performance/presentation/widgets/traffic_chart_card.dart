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
    final minX = rxSpots.isNotEmpty ? rxSpots.first.x : 0.0;
    final maxX = rxSpots.isNotEmpty ? rxSpots.last.x : 1.0;

    final allValues = [...rxSpots.map((e) => e.y), ...txSpots.map((e) => e.y)];
    final maxDataY = allValues.isEmpty
        ? 10.0
        : allValues.reduce((a, b) => a > b ? a : b).toDouble();
    final maxY = (maxDataY * 1.2).clamp(10.0, 1000000.0);

    const rxColor = Color(0xFFE0E0E0);
    const txColor = Color(0xFF9E9E9E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2631),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Traffic Trend (Mbps)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Maksimum $maxSamples sampel terakhir (refresh setiap $refreshSeconds detik)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
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
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
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
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                        ),
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
                    left: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    bottom: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                ),
                lineTouchData: const LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: Color(0xFF111827),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: rxSpots,
                    isCurved: true,
                    color: rxColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: rxColor.withValues(alpha: 0.15),
                    ),
                  ),
                  LineChartBarData(
                    spots: txSpots,
                    isCurved: true,
                    color: txColor,
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
              _LegendDot(color: rxColor, label: 'RX'),
              SizedBox(width: 16),
              _LegendDot(color: txColor, label: 'TX'),
            ],
          ),
        ],
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
