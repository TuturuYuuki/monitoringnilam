import 'package:flutter/material.dart';

class DeviceTelemetryDataTableCard extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const DeviceTelemetryDataTableCard({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final hasRows = rows.isNotEmpty;
    final visibleRows = hasRows
        ? rows
            .map(
              (row) => _TelemetryRow(
                updated: _toText(row['sampled_at']),
                cpuLoad: _fmt(row['cpu_load_percent']),
                ramUsage: _fmt(row['ram_usage_percent']),
                latency: _fmt(row['latency_ms']),
                responseTime: _fmt(row['response_time_ms']),
                packetLoss: _fmt(row['packet_loss_percent']),
                trafficRx: _fmt(row['traffic_rx_mbps']),
                trafficTx: _fmt(row['traffic_tx_mbps']),
                uptime: _toText(row['uptime_seconds']),
              ),
            )
            .toList(growable: false)
        : <_TelemetryRow>[
            const _TelemetryRow(
              updated: 'NO DATA',
              cpuLoad: '-',
              ramUsage: '-',
              latency: '-',
              responseTime: '-',
              packetLoss: '-',
              trafficRx: '-',
              trafficTx: '-',
              uptime: '-',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Device Telemetry',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2C3A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                _TelemetryHeaderRow(),
                ...visibleRows.asMap().entries.map(
                  (entry) => _TelemetryDataRow(
                    row: entry.value,
                    isLast: entry.key == visibleRows.length - 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _toText(dynamic value) {
    if (value == null) {
      return '-';
    }
    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  static String _fmt(dynamic value) {
    if (value is num) {
      return value.toStringAsFixed(2);
    }
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      return '-';
    }
    return parsed.toStringAsFixed(2);
  }
}

class _TelemetryRow {
  final String updated;
  final String cpuLoad;
  final String ramUsage;
  final String latency;
  final String responseTime;
  final String packetLoss;
  final String trafficRx;
  final String trafficTx;
  final String uptime;

  const _TelemetryRow({
    required this.updated,
    required this.cpuLoad,
    required this.ramUsage,
    required this.latency,
    required this.responseTime,
    required this.packetLoss,
    required this.trafficRx,
    required this.trafficTx,
    required this.uptime,
  });
}

class _TelemetryHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const headers = [
      ('sampled_at', 2),
      ('cpu_load_percent', 1),
      ('ram_usage_percent', 1),
      ('latency_ms', 1),
      ('response_time_ms', 1),
      ('packet_loss_percent', 1),
      ('traffic_rx_mbps', 1),
      ('traffic_tx_mbps', 1),
      ('uptime_seconds', 1),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: headers
            .map(
              (item) => Expanded(
                flex: item.$2,
                child: Text(
                  item.$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _TelemetryDataRow extends StatelessWidget {
  final _TelemetryRow row;
  final bool isLast;

  const _TelemetryDataRow({required this.row, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLast ? Colors.transparent : Colors.white.withValues(alpha: 0.03),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          _cell(row.updated, flex: 2),
          _cell(row.cpuLoad, flex: 1),
          _cell(row.ramUsage, flex: 1),
          _cell(row.latency, flex: 1),
          _cell(row.responseTime, flex: 1),
          _cell(row.packetLoss, flex: 1),
          _cell(row.trafficRx, flex: 1),
          _cell(row.trafficTx, flex: 1),
          _cell(row.uptime, flex: 1),
        ],
      ),
    );
  }

  Widget _cell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

