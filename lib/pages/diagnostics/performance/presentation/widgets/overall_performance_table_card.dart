import 'package:flutter/material.dart';

class OverallPerformanceTableCard extends StatelessWidget {
  final Map<String, dynamic>? overallData;
  final String title;
  final String selectedRange;

  const OverallPerformanceTableCard({
    super.key,
    required this.overallData,
    this.title = 'Data Keseluruhan Performance',
    this.selectedRange = 'all',
  });

  @override
  Widget build(BuildContext context) {
    final health = _asMap(overallData?['health_overview']);
    final vital = _asMap(overallData?['vital']);

    final up = _toInt(health['up']);
    final warning = _toInt(health['warning']);
    final critical = _toInt(health['critical']);
    final undefined = _toInt(health['undefined']);
    final down = warning + critical + undefined;

    final rows = <_OverallMetricRow>[
      _OverallMetricRow(
        label: 'UP Devices',
        value: up.toString(),
      ),
      _OverallMetricRow(
        label: 'DOWN/WARNING Devices',
        value: down.toString(),
      ),
      _OverallMetricRow(
        label: 'Rata-rata CPU',
        value: '${_toDouble(vital['cpu_load_percent']).toStringAsFixed(2)} %',
      ),
      _OverallMetricRow(
        label: 'Rata-rata Memory',
        value: '${_toDouble(vital['memory_used_percent']).toStringAsFixed(2)} %',
      ),
      _OverallMetricRow(
        label: 'Rata-rata Latency',
        value: '${_toDouble(vital['response_time_ms']).toStringAsFixed(2)} ms',
      ),
      _OverallMetricRow(
        label: 'Rata-rata Packet Loss',
        value: '${_toDouble(vital['packet_loss_percent']).toStringAsFixed(2)} %',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF172330),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 760;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      _rangeLabel(selectedRange),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusPill('UP', up.toString(), const Color(0xFF3CB371)),
                  _statusPill('DOWN/WARN', down.toString(), const Color(0xFFB0B0B0)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < rows.length; i++)
                      _metricRow(
                        rows[i],
                        dense: isCompact,
                        showDivider: i != rows.length - 1,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _metricRow(
    _OverallMetricRow row, {
    required bool dense,
    required bool showDivider,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 10 : 12,
        vertical: dense ? 8 : 10,
      ),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                fontSize: dense ? 12 : 13,
              ),
            ),
          ),
          Text(
            row.value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: dense ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }

  static String _rangeLabel(String range) {
    switch (range) {
      case '24h':
        return '24 Jam';
      case '7d':
        return '7 Hari';
      case '30d':
        return '30 Hari';
      case 'all':
      default:
        return 'Semua Data';
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return const <String, dynamic>{};
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _OverallMetricRow {
  final String label;
  final String value;

  const _OverallMetricRow({
    required this.label,
    required this.value,
  });
}