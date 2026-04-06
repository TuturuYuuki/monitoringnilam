import 'dart:math';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:monitoring/pages/diagnostics/global/application/global_diagnostics_controller.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';

class GlobalDiagnosticsPage extends StatefulWidget {
  const GlobalDiagnosticsPage({super.key});

  @override
  State<GlobalDiagnosticsPage> createState() => _GlobalDiagnosticsPageState();
}

class _GlobalDiagnosticsPageState extends State<GlobalDiagnosticsPage> {
  final GlobalDiagnosticsController _controller = GlobalDiagnosticsController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _controller.bootstrap();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _refreshDiagnostics() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _controller.refresh();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1100;
    final snapshot = _controller.snapshot;
    final latencySpots = snapshot.latencySeries
        .map((point) => FlSpot(point.x, point.y))
        .toList(growable: false);
    final packetLossSpots = snapshot.packetLossSeries
        .map((point) => FlSpot(point.x, point.y))
        .toList(growable: false);
    final cpuLoadSpots = snapshot.cpuAverageSeries
        .map((point) => FlSpot(point.x, point.y))
        .toList(growable: false);
    final diskUsageSpotsA = snapshot.diskSeriesA
        .map((point) => FlSpot(point.x, point.y))
        .toList(growable: false);
    final diskUsageSpotsB = snapshot.diskSeriesB
        .map((point) => FlSpot(point.x, point.y))
        .toList(growable: false);

    final cpuValue = snapshot.cpuLoadPercent;
    final memoryValue = snapshot.memoryUsedPercent;
    final latencyGaugeValue =
        (snapshot.responseTimeMs / 2.5).clamp(0, 100).toDouble();
    final packetGaugeValue =
        (snapshot.packetLossPercent * 8).clamp(0, 100).toDouble();
    final upCount = snapshot.nodeUp;
    final downCount =
      snapshot.nodeWarning + snapshot.nodeCritical + snapshot.nodeUndefined;

    final diskVolumes = snapshot.diskVolumes
        .map((item) => _DiskVolumeRow(
              name: item.name,
              size: item.size,
              used: item.used,
              percent: item.percent,
            ))
        .toList(growable: false);

    final topCpuBars = snapshot.topCpuSeries.map((item) {
      final color = _parseHexColor(item.colorHex);
      final series =
          item.series.map((point) => FlSpot(point.x, point.y)).toList(growable: false);
      return _CpuBarData(
        item.name,
        item.deviceType,
        item.deviceTypeLabel,
        item.value,
        color,
        series,
      );
    }).toList(growable: false);
    final highErrorRows = snapshot.highErrors
        .map(
          (item) => _HighErrorRow(
            node: item.node,
            interfaceName: item.interfaceName,
            receiveErrors: item.receiveErrors,
            receiveDiscards: item.receiveDiscards,
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/global-diagnostics'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  const GlobalSidebarNav(currentRoute: '/global-diagnostics'),
                if (!isMobile) const SizedBox(width: 12),
                Expanded(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF1F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFC7CDD4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Global Diagnostics',
                                    style: TextStyle(
                                      color: Color(0xFF2C3E50),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: (_controller.isLoading || _isRefreshing)
                                      ? null
                                      : _refreshDiagnostics,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1565C0),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: (_controller.isLoading || _isRefreshing)
                                      ? const SizedBox(
                                          height: 14,
                                          width: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.refresh),
                                  label: const Text('Refresh'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (_controller.errorMessage != null) ...[
                              _StatusBanner(
                                message: _controller.errorMessage!,
                                backgroundColor: const Color(0xFFFFF4E5),
                                borderColor: const Color(0xFFFFC107),
                                textColor: const Color(0xFF9A6700),
                              ),
                            ],
                            if (_controller.isLoading) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child:
                                    const LinearProgressIndicator(minHeight: 4),
                              ),
                            ],
                            const SizedBox(height: 10),
                            _SummaryMetricsBar(
                              cpuValue: cpuValue,
                              memoryValue: memoryValue,
                              responseTimeMs: snapshot.responseTimeMs,
                              packetLossPercent: snapshot.packetLossPercent,
                              upCount: upCount,
                              downCount: downCount,
                            ),
                            const SizedBox(height: 10),
                            if (isMobile) ...[
                              _SectionGroupCard(
                                child: Column(
                                  children: [
                                    _LatencyPacketChartPanel(
                                      latencySpots: latencySpots,
                                      packetLossSpots: packetLossSpots,
                                      latencyLabel:
                                          '${snapshot.responseTimeMs.toStringAsFixed(2)} ms',
                                      packetLossLabel:
                                          '${snapshot.packetLossPercent.toStringAsFixed(2)} %',
                                    ),
                                    const SizedBox(height: 10),
                                    _CpuAveragePanel(spots: cpuLoadSpots),
                                    const SizedBox(height: 10),
                                    _TopCpusPanel(bars: topCpuBars),
                                    const SizedBox(height: 10),
                                    _DiskUsageTrendPanel(
                                      spotsA: diskUsageSpotsA,
                                      spotsB: diskUsageSpotsB,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _SectionGroupCard(
                                child: Column(
                                  children: [
                                    _DiskVolumesPanel(rows: diskVolumes),
                                    const SizedBox(height: 10),
                                    _CpuMemoryPanel(
                                        cpuValue: cpuValue,
                                        memoryValue: memoryValue),
                                    const SizedBox(height: 10),
                                    _LatencyLossGaugePanel(
                                      latencyValue: latencyGaugeValue,
                                      packetLossValue: packetGaugeValue,
                                    ),
                                    const SizedBox(height: 10),
                                    _HighErrorsPanel(rows: highErrorRows),
                                  ],
                                ),
                              ),
                            ] else ...[
                              _SectionGroupCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _LatencyPacketChartPanel(
                                            latencySpots: latencySpots,
                                            packetLossSpots: packetLossSpots,
                                            latencyLabel:
                                                '${snapshot.responseTimeMs.toStringAsFixed(2)} ms',
                                            packetLossLabel:
                                                '${snapshot.packetLossPercent.toStringAsFixed(2)} %',
                                          ),
                                          const SizedBox(height: 10),
                                          _CpuAveragePanel(spots: cpuLoadSpots),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _TopCpusPanel(bars: topCpuBars),
                                          const SizedBox(height: 10),
                                          _DiskUsageTrendPanel(
                                            spotsA: diskUsageSpotsA,
                                            spotsB: diskUsageSpotsB,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              _SectionGroupCard(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _DiskVolumesPanel(rows: diskVolumes),
                                          const SizedBox(height: 10),
                                          _LatencyLossGaugePanel(
                                            latencyValue: latencyGaugeValue,
                                            packetLossValue: packetGaugeValue,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _CpuMemoryPanel(
                                              cpuValue: cpuValue,
                                              memoryValue: memoryValue),
                                          const SizedBox(height: 10),
                                          _HighErrorsPanel(rows: highErrorRows),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }
}

const double _kPanelMinHeight = 320;
const double _kChartHeight = 210;

class _AxisBounds {
  final double minX;
  final double maxX;

  const _AxisBounds(this.minX, this.maxX);
}

_AxisBounds _axisBoundsFromSeries(List<List<FlSpot>> seriesList) {
  final all = <FlSpot>[];
  for (final series in seriesList) {
    all.addAll(series);
  }
  if (all.isEmpty) {
    return const _AxisBounds(0, 1);
  }
  var minX = all.first.x;
  var maxX = all.first.x;
  for (final point in all) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
  }
  if ((maxX - minX).abs() < 0.001) {
    maxX = minX + 1;
  }
  return _AxisBounds(minX, maxX);
}

double _maxYFromSeries(List<List<FlSpot>> seriesList, {double floor = 10}) {
  var maxY = floor;
  for (final series in seriesList) {
    for (final point in series) {
      if (point.y > maxY) {
        maxY = point.y;
      }
    }
  }
  return (maxY * 1.1).clamp(floor, 1000).toDouble();
}

DateTime _timeAtAxisValue(
    double value, _AxisBounds bounds, DateTime startTime, DateTime endTime) {
  final total = bounds.maxX - bounds.minX;
  if (total.abs() < 0.001) {
    return endTime;
  }
  final ratio = ((value - bounds.minX) / total).clamp(0, 1);
  final duration = endTime.difference(startTime);
  return startTime
      .add(Duration(milliseconds: (duration.inMilliseconds * ratio).round()));
}

String _formatClock(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

double _xAxisInterval(_AxisBounds bounds, {int targetTicks = 4}) {
  final span = (bounds.maxX - bounds.minX).abs();
  final divisor = (targetTicks - 1).clamp(1, 10);
  return (span / divisor).clamp(0.1, 9999).toDouble();
}

double _yAxisInterval(double maxY, {int targetTicks = 4}) {
  final divisor = targetTicks.clamp(2, 10);
  return (maxY / divisor).clamp(1, 9999).toDouble();
}

Widget _axisHintText(String yDescription) {
  return Text(
    'X: Waktu (24 jam, interval 5 jam)  |  Y: $yDescription',
    style: const TextStyle(
      color: Color(0xFF5E6D79),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    ),
  );
}

Widget _bottomTimeTitleBuilder(
  double value,
  TitleMeta meta,
  _AxisBounds bounds,
  DateTime startTime,
  DateTime endTime,
) {
  final time = _timeAtAxisValue(value, bounds, startTime, endTime);
  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 6,
    child: Text(
      _formatClock(time),
      style: const TextStyle(
        color: Color(0xFF5E6D79),
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

Widget _leftAxisTitleBuilder(double value, TitleMeta meta) {
  final max = meta.max;
  if ((max - value).abs() < 0.001) {
    return const SizedBox.shrink();
  }
  return Text(
    value.toInt().toString(),
    style: const TextStyle(
      color: Color(0xFF5E6D79),
      fontSize: 10,
      fontWeight: FontWeight.w600,
    ),
  );
}

Color _parseHexColor(String hex) {
  final normalized = hex.replaceAll('#', '');
  final buffer = StringBuffer();
  if (normalized.length == 6) {
    buffer.write('ff');
  }
  buffer.write(normalized);
  return Color(int.tryParse(buffer.toString(), radix: 16) ?? 0xFF1B9FDC);
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _StatusBanner({
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryMetricsBar extends StatelessWidget {
  final double cpuValue;
  final double memoryValue;
  final double responseTimeMs;
  final double packetLossPercent;
  final int upCount;
  final int downCount;

  const _SummaryMetricsBar({
    required this.cpuValue,
    required this.memoryValue,
    required this.responseTimeMs,
    required this.packetLossPercent,
    required this.upCount,
    required this.downCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD3DAE1)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _SummaryChip(label: 'UP', value: upCount.toString(), color: const Color(0xFF219653)),
          _SummaryChip(label: 'DOWN', value: downCount.toString(), color: const Color(0xFFEB5757)),
          _SummaryChip(label: 'CPU', value: '${cpuValue.toStringAsFixed(1)} %', color: const Color(0xFF2D9CDB)),
          _SummaryChip(label: 'Memory', value: '${memoryValue.toStringAsFixed(1)} %', color: const Color(0xFF27AE60)),
          _SummaryChip(label: 'Speed', value: '${responseTimeMs.toStringAsFixed(1)} ms', color: const Color(0xFFF2994A)),
          _SummaryChip(label: 'Stability', value: '${packetLossPercent.toStringAsFixed(2)} % loss', color: const Color(0xFFEB5757)),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2B3D4F),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionGroupCard extends StatelessWidget {
  final Widget child;

  const _SectionGroupCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFFFFFF).withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6FB6FF).withValues(alpha: 0.20),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _SolarPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _SolarPanel({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _kPanelMinHeight),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFFFFF).withValues(alpha: 0.68)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF87C5FF).withValues(alpha: 0.22),
                  blurRadius: 22,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.45),
                    border: const Border(bottom: BorderSide(color: Color(0xFFD8DEE3))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF253647),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CpuMemoryPanel extends StatelessWidget {
  final double cpuValue;
  final double memoryValue;

  const _CpuMemoryPanel({
    required this.cpuValue,
    required this.memoryValue,
  });

  @override
  Widget build(BuildContext context) {
    return _SolarPanel(
      title: 'CPU Load & Memory Utilization',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: _GaugeTile(label: 'CPU Load', value: cpuValue),
              ),
              SizedBox(
                width: 220,
                child: _GaugeTile(
                  label: 'Memory Used',
                  value: memoryValue,
                  critical: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatencyLossGaugePanel extends StatelessWidget {
  final double latencyValue;
  final double packetLossValue;

  const _LatencyLossGaugePanel({
    required this.latencyValue,
    required this.packetLossValue,
  });

  @override
  Widget build(BuildContext context) {
    return _SolarPanel(
      title: 'Response Time & Packet Loss',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 18,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 220,
                child: _GaugeTile(
                  label: 'Average Response Time',
                  value: latencyValue,
                ),
              ),
              SizedBox(
                width: 220,
                child: _GaugeTile(label: 'Packet Loss', value: packetLossValue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugeTile extends StatelessWidget {
  final String label;
  final double value;
  final bool critical;

  const _GaugeTile({
    required this.label,
    required this.value,
    this.critical = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 140, child: _AnalogGauge(value: value)),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: critical ? const Color(0xFFC0262D) : const Color(0xFF30404F),
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AnalogGauge extends StatelessWidget {
  final double value;

  const _AnalogGauge({required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GaugePainter(value: value),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 74),
          child: Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF7C1214),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              '${value.toStringAsFixed(0)} %',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;

  _GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width.clamp(0, size.height) / 2) - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..color = const Color(0xFF1B1E24);
    canvas.drawCircle(center, radius, basePaint);

    final segmentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    const start = 2.55;
    const sweep = 5.18;

    segmentPaint.color = const Color(0xFF3BAA4B);
    canvas.drawArc(rect, start, sweep * 0.6, false, segmentPaint);

    segmentPaint.color = const Color(0xFFE8B923);
    canvas.drawArc(rect, start + sweep * 0.6, sweep * 0.2, false, segmentPaint);

    segmentPaint.color = const Color(0xFFCE2F2F);
    canvas.drawArc(rect, start + sweep * 0.8, sweep * 0.2, false, segmentPaint);

    final tickPaint = Paint()
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.4);

    for (int i = 0; i <= 20; i++) {
      final angle = start + (sweep / 20) * i;
      final p1 = Offset(center.dx + (radius - 1) * cos(angle), center.dy + (radius - 1) * sin(angle));
      final p2 = Offset(center.dx + (radius - 12) * cos(angle), center.dy + (radius - 12) * sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }

    final valueRatio = (value.clamp(0, 100) / 100).toDouble();
    final needleAngle = start + sweep * valueRatio;
    final needlePaint = Paint()
      ..strokeWidth = 3
      ..color = const Color(0xFFD9DDE2);

    final needleEnd = Offset(center.dx + (radius - 24) * cos(needleAngle), center.dy + (radius - 24) * sin(needleAngle));
    canvas.drawLine(center, needleEnd, needlePaint);

    final centerPaint = Paint()..color = const Color(0xFF8C9097);
    canvas.drawCircle(center, 7, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _DiskVolumesPanel extends StatelessWidget {
  final List<_DiskVolumeRow> rows;

  const _DiskVolumesPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    final entries = rows;

    return _SolarPanel(
      title: 'Disk Volumes',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No historical disk data',
                  style: TextStyle(
                    color: Color(0xFF6A7480),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              for (final item in entries)
                _DiskRow(
                  name: item.name,
                  size: item.size,
                  used: item.used,
                  percent: item.percent,
                ),
          ],
        ),
      ),
    );
  }
}

class _DiskRow extends StatelessWidget {
  final String name;
  final String size;
  final String used;
  final int percent;

  const _DiskRow({
    required this.name,
    required this.size,
    required this.used,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final barColor = percent >= 85
        ? const Color(0xFFDAA61A)
        : (percent >= 60 ? const Color(0xFF88B924) : const Color(0xFF41AE64));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF3B4D5D),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text('Size $size', style: const TextStyle(fontSize: 11, color: Color(0xFF607282)))),
              Expanded(child: Text('Used $used', style: const TextStyle(fontSize: 11, color: Color(0xFF607282)))),
              Text('$percent %', style: const TextStyle(fontSize: 11, color: Color(0xFF475666), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: percent / 100,
              backgroundColor: const Color(0xFFE3E9EE),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatencyPacketChartPanel extends StatelessWidget {
  final List<FlSpot> latencySpots;
  final List<FlSpot> packetLossSpots;
  final String latencyLabel;
  final String packetLossLabel;

  const _LatencyPacketChartPanel({
    required this.latencySpots,
    required this.packetLossSpots,
    required this.latencyLabel,
    required this.packetLossLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bounds = _axisBoundsFromSeries([latencySpots, packetLossSpots]);
    final maxY = _maxYFromSeries([latencySpots, packetLossSpots], floor: 30);
    final xInterval = _xAxisInterval(bounds, targetTicks: 4);
    final yInterval = _yAxisInterval(maxY, targetTicks: 4);
    final endTime = DateTime.now();
    final startTime = endTime.subtract(const Duration(hours: 12));
    final latencyTrend = _seriesTrend(latencySpots);
    final packetLossTrend = _seriesTrend(packetLossSpots);

    return _SolarPanel(
      title: 'Network Latency & Packet Loss',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _axisHintText('Latency (ms) dan Packet Loss (%)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TrendTag(
                  label: 'Latency',
                  trend: latencyTrend,
                  unit: 'ms',
                ),
                _TrendTag(
                  label: 'Packet Loss',
                  trend: packetLossTrend,
                  unit: '%',
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: _kChartHeight,
              child: LineChart(
                LineChartData(
                  minX: bounds.minX,
                  maxX: bounds.maxX,
                  lineBarsData: [
                    LineChartBarData(
                      spots: latencySpots,
                      color: const Color(0xFF2C9FD6),
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      isCurved: false,
                    ),
                    LineChartBarData(
                      spots: packetLossSpots,
                      color: const Color(0xFFE553B7),
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                      isCurved: false,
                    ),
                  ],
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFE7ECF1), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFD6DEE5)),
                      left: BorderSide(color: Color(0xFFD6DEE5)),
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ).copyWith(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: yInterval,
                        getTitlesWidget: _leftAxisTitleBuilder,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => _bottomTimeTitleBuilder(value, meta, bounds, startTime, endTime),
                      ),
                    ),
                  ),
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: const Color(0xFF1E2D3B),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isLatency = spot.barIndex == 0;
                          final label = isLatency ? 'Latency' : 'Packet Loss';
                          final unit = isLatency ? 'ms' : '%';
                          final value = spot.y.toStringAsFixed(2);
                          final timeLabel = _formatClock(
                            _timeAtAxisValue(
                              spot.x,
                              bounds,
                              startTime,
                              endTime,
                            ),
                          );
                          return LineTooltipItem(
                            '$label: $value $unit\n$timeLabel',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList(growable: false);
                      },
                    ),
                  ),
                  clipData: const FlClipData.all(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendTag(color: const Color(0xFF2C9FD6), text: '$latencyLabel  Average Response Time'),
                const SizedBox(width: 8),
                _LegendTag(color: const Color(0xFFE553B7), text: '$packetLossLabel  Packet Loss'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CpuAveragePanel extends StatelessWidget {
  final List<FlSpot> spots;

  const _CpuAveragePanel({required this.spots});

  @override
  Widget build(BuildContext context) {
    final bounds = _axisBoundsFromSeries([spots]);
    final xInterval = _xAxisInterval(bounds, targetTicks: 4);
    const yInterval = 20.0;
    final endTime = DateTime.now();
    final startTime = endTime.subtract(const Duration(hours: 12));
    final cpuTrend = _seriesTrend(spots);

    return _SolarPanel(
      title: 'Min/Max/Average CPU Load',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _axisHintText('CPU Load (%)'),
            const SizedBox(height: 8),
            _TrendTag(label: 'CPU Load', trend: cpuTrend, unit: '%'),
            const SizedBox(height: 10),
            SizedBox(
              height: _kChartHeight,
              child: LineChart(
                LineChartData(
                  minX: bounds.minX,
                  maxX: bounds.maxX,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      color: const Color(0xFF36A2D8),
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      isCurved: false,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: 85,
                      color: const Color(0xFFB54A45),
                      strokeWidth: 1,
                      dashArray: [5, 4],
                    ),
                    HorizontalLine(
                      y: 50,
                      color: const Color(0xFF7B868F),
                      strokeWidth: 1,
                      dashArray: [5, 4],
                    ),
                  ]),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFE7ECF1), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFD6DEE5)),
                      left: BorderSide(color: Color(0xFFD6DEE5)),
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ).copyWith(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: yInterval,
                        getTitlesWidget: _leftAxisTitleBuilder,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => _bottomTimeTitleBuilder(value, meta, bounds, startTime, endTime),
                      ),
                    ),
                  ),
                  minY: 0,
                  maxY: 100,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: const Color(0xFF1E2D3B),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final value = spot.y.toStringAsFixed(2);
                          final timeLabel = _formatClock(
                            _timeAtAxisValue(
                              spot.x,
                              bounds,
                              startTime,
                              endTime,
                            ),
                          );
                          return LineTooltipItem(
                            'CPU: $value %\n$timeLabel',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        }).toList(growable: false);
                      },
                    ),
                  ),
                  clipData: const FlClipData.all(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCpusPanel extends StatelessWidget {
  final List<_CpuBarData> bars;

  const _TopCpusPanel({required this.bars});

  @override
  Widget build(BuildContext context) {
    final items = bars;
    final bounds = _axisBoundsFromSeries([
      for (final item in items) item.series ?? const <FlSpot>[],
    ]);
    final xInterval = _xAxisInterval(bounds, targetTicks: 4);
    const yInterval = 20.0;
    final endTime = DateTime.now();
    final startTime = endTime.subtract(const Duration(hours: 12));

    return _SolarPanel(
      title: 'Top Devices by CPU Load',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No historical device CPU data',
                  style: TextStyle(
                    color: Color(0xFF6A7480),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _axisHintText('CPU Utilization per Device (%)'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: _kChartHeight,
                    child: LineChart(
                      LineChartData(
                        minX: bounds.minX,
                        maxX: bounds.maxX,
                        lineBarsData: [
                          for (int i = 0; i < items.length; i++)
                            LineChartBarData(
                              spots: items[i].series ?? const <FlSpot>[],
                              color: items[i].color,
                              barWidth: 2,
                              isCurved: false,
                              dotData: const FlDotData(show: true),
                            ),
                        ],
                        minY: 0,
                        maxY: 100,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) =>
                              const FlLine(
                                color: Color(0xFFE7ECF1),
                                strokeWidth: 1,
                              ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            bottom: BorderSide(color: Color(0xFFD6DEE5)),
                            left: BorderSide(color: Color(0xFFD6DEE5)),
                          ),
                        ),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ).copyWith(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: yInterval,
                              getTitlesWidget: _leftAxisTitleBuilder,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: xInterval,
                              reservedSize: 28,
                              getTitlesWidget: (value, meta) =>
                                  _bottomTimeTitleBuilder(
                                    value,
                                    meta,
                                    bounds,
                                    startTime,
                                    endTime,
                                  ),
                            ),
                          ),
                        ),
                        clipData: const FlClipData.all(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: items
                        .map(
                          (item) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${item.value.toStringAsFixed(2)}% ${item.name}',
                                style: const TextStyle(
                                  color: Color(0xFF30404F),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CpuBarData {
  final String name;
  final String deviceType;
  final String deviceTypeLabel;
  final double value;
  final Color color;
  final List<FlSpot>? series;

  _CpuBarData(
    this.name,
    this.deviceType,
    this.deviceTypeLabel,
    this.value,
    this.color, [
    this.series,
  ]);
}

class _DiskVolumeRow {
  final String name;
  final String size;
  final String used;
  final int percent;

  const _DiskVolumeRow({
    required this.name,
    required this.size,
    required this.used,
    required this.percent,
  });
}

class _HighErrorRow {
  final String node;
  final String interfaceName;
  final int receiveErrors;
  final int receiveDiscards;

  const _HighErrorRow({
    required this.node,
    required this.interfaceName,
    required this.receiveErrors,
    required this.receiveDiscards,
  });
}

class _HighErrorsPanel extends StatelessWidget {
  final List<_HighErrorRow> rows;

  const _HighErrorsPanel({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _SolarPanel(
      title: 'High Errors & Discards Today',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: rows.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No historical interface-error data',
                  style: TextStyle(
                    color: Color(0xFF6A7480),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FBFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD8E0E7)),
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(3),
                    1: FlexColumnWidth(2),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  border: const TableBorder.symmetric(
                    inside: BorderSide(color: Color(0xFFE5EBF0)),
                  ),
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Color(0xFFEFF4F8)),
                      children: [
                        _TableHeaderCell(text: 'DEVICE'),
                        _TableHeaderCell(text: 'CATEGORY'),
                        _TableHeaderCell(text: 'ERROR COUNT'),
                        _TableHeaderCell(text: 'WARNING/DISCARD'),
                      ],
                    ),
                    for (int i = 0; i < rows.length; i++)
                      TableRow(
                        decoration: BoxDecoration(
                          color: i.isEven
                              ? Colors.white
                              : const Color(0xFFF7FAFD),
                        ),
                        children: [
                          _TableValueCell(text: rows[i].node, isBold: true),
                          _TableValueCell(text: rows[i].interfaceName),
                          _TableValueCell(text: rows[i].receiveErrors.toString()),
                          _TableValueCell(
                            text: rows[i].receiveDiscards.toString(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DiskUsageTrendPanel extends StatelessWidget {
  final List<FlSpot> spotsA;
  final List<FlSpot> spotsB;

  const _DiskUsageTrendPanel({
    required this.spotsA,
    required this.spotsB,
  });

  @override
  Widget build(BuildContext context) {
    final bounds = _axisBoundsFromSeries([spotsA, spotsB]);
    final xInterval = _xAxisInterval(bounds, targetTicks: 4);
    const yInterval = 20.0;
    final endTime = DateTime.now();
    final startTime = endTime.subtract(const Duration(hours: 12));

    return _SolarPanel(
      title: 'Resource Usage by Device Type',
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _axisHintText('Disk Usage (%)'),
            const SizedBox(height: 10),
            SizedBox(
              height: _kChartHeight,
              child: LineChart(
                LineChartData(
                  minX: bounds.minX,
                  maxX: bounds.maxX,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spotsA,
                      color: const Color(0xFF7E69D6),
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: spotsB,
                      color: const Color(0xFF2B9FCE),
                      barWidth: 2,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFE7ECF1), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFD6DEE5)),
                      left: BorderSide(color: Color(0xFFD6DEE5)),
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ).copyWith(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: yInterval,
                        getTitlesWidget: _leftAxisTitleBuilder,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) => _bottomTimeTitleBuilder(value, meta, bounds, startTime, endTime),
                      ),
                    ),
                  ),
                  clipData: const FlClipData.all(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendTag extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendTag({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;

  const _TableHeaderCell({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF66727F),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TableValueCell extends StatelessWidget {
  final String text;
  final bool isBold;

  const _TableValueCell({
    required this.text,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF4F6070),
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _TrendTag extends StatelessWidget {
  final String label;
  final _SeriesTrend trend;
  final String unit;

  const _TrendTag({
    required this.label,
    required this.trend,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final Color trendColor;
    final IconData trendIcon;
    final String direction;

    if (trend.delta > 0.05) {
      trendColor = const Color(0xFFB54A45);
      trendIcon = Icons.trending_up;
      direction = 'naik';
    } else if (trend.delta < -0.05) {
      trendColor = const Color(0xFF219653);
      trendIcon = Icons.trending_down;
      direction = 'turun';
    } else {
      trendColor = const Color(0xFF607282);
      trendIcon = Icons.trending_flat;
      direction = 'stabil';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: trendColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trendIcon, size: 14, color: trendColor),
          const SizedBox(width: 4),
          Text(
            '$label $direction ${trend.delta.abs().toStringAsFixed(2)} $unit',
            style: TextStyle(
              color: trendColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesTrend {
  final double delta;

  const _SeriesTrend(this.delta);
}

_SeriesTrend _seriesTrend(List<FlSpot> spots) {
  if (spots.length < 2) {
    return const _SeriesTrend(0);
  }
  final first = spots.first.y;
  final last = spots.last.y;
  return _SeriesTrend(last - first);
}
