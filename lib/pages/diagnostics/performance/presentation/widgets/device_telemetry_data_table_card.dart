import 'package:flutter/material.dart';
import 'package:monitoring/utils/ui_utils.dart'; // added for liquidGlassCard

class DeviceTelemetryDataTableCard extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const DeviceTelemetryDataTableCard({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
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

    return liquidGlassCard(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Device Telemetry Data',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isMobile
                ? 'Swipe table left/right to view all columns.'
                : 'Complete device telemetry table.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = _TelemetryLayout.getTableWidth(constraints.maxWidth);
              final columnWidths = _TelemetryLayout.getColumnWidths(tableWidth);

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2C3A).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: [
                      _TelemetryHeaderRow(
                        isMobile: isMobile,
                        tableWidth: tableWidth,
                        columnWidths: columnWidths,
                      ),
                      ...visibleRows.asMap().entries.map(
                        (entry) => _TelemetryDataRow(
                          row: entry.value,
                          isLast: entry.key == visibleRows.length - 1,
                          isMobile: isMobile,
                          tableWidth: tableWidth,
                          columnWidths: columnWidths,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
  final bool isMobile;
  final double tableWidth;
  final List<double> columnWidths;

  const _TelemetryHeaderRow({
    required this.isMobile,
    required this.tableWidth,
    required this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    const headers = [
      'TIME',
      'CPU %',
      'RAM %',
      'LATENCY',
      'RESP TIME',
      'PKT LOSS %',
      'RX MBPS',
      'TX MBPS',
      'UPTIME',
    ];

    return Container(
      width: tableWidth,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < headers.length; i++)
            _tableCell(
              text: headers[i],
              width: columnWidths[i],
              isHeader: true,
              isMobile: isMobile,
              isTime: i == 0,
            ),
        ],
      ),
    );
  }
}

class _TelemetryDataRow extends StatelessWidget {
  final _TelemetryRow row;
  final bool isLast;
  final bool isMobile;
  final double tableWidth;
  final List<double> columnWidths;

  const _TelemetryDataRow({
    required this.row,
    required this.isLast,
    required this.isMobile,
    required this.tableWidth,
    required this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {}, // For hover effect
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          width: tableWidth,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: isLast ? BorderSide.none : BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              _tableCell(
                text: row.updated,
                width: columnWidths[0],
                isMobile: isMobile,
                isTime: true,
              ),
              _tableCell(
                text: row.cpuLoad,
                width: columnWidths[1],
                isMobile: isMobile,
              ),
              _tableCell(
                text: row.ramUsage,
                width: columnWidths[2],
                isMobile: isMobile,
              ),
              _tableCell(
                text: row.latency,
                width: columnWidths[3],
                isMobile: isMobile,
              ),
              _tableCell(
                text: row.responseTime,
                width: columnWidths[4],
                isMobile: isMobile,
              ),
              _tableCell(
                text: row.packetLoss,
                width: columnWidths[5],
                isMobile: isMobile,
              ),
              _tableCell(
                text: row.trafficRx,
                width: columnWidths[6],
                isMobile: isMobile,
              ),
              _tableCell(
                text: row.trafficTx,
                width: columnWidths[7],
                isMobile: isMobile,
              ),
              _tableCell(
                text: row.uptime,
                width: columnWidths[8],
                isMobile: isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryLayout {
  static double getTableWidth(double availableWidth) {
    return availableWidth > 1100 ? availableWidth : 1100;
  }

  static List<double> getColumnWidths(double tableWidth) {
    // Proportional distribution for desktop
    final timeWidth = tableWidth * 0.18; // 18% for Time
    final uptimeWidth = tableWidth * 0.12; // 12% for Uptime
    final remainingWidth = tableWidth - timeWidth - uptimeWidth;
    final otherColWidth = remainingWidth / 7;

    return [
      timeWidth,
      otherColWidth,
      otherColWidth,
      otherColWidth,
      otherColWidth,
      otherColWidth,
      otherColWidth,
      otherColWidth,
      uptimeWidth,
    ];
  }
}

Widget _tableCell({
  required String text,
  required double width,
  bool isHeader = false,
  bool isMobile = false,
  bool isTime = false,
}) {
  return SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        text,
        textAlign: isTime ? TextAlign.left : TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isHeader ? Colors.white : Colors.white.withValues(alpha: 0.9),
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
          fontSize: isMobile ? 11 : 13,
          letterSpacing: isHeader ? 0.5 : 0,
        ),
      ),
    ),
  );
}

