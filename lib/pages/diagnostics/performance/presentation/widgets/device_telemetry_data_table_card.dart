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
                uptime: _toText(row['uptime_seconds']),
              ),
            )
            .toList(growable: false)
        : <_TelemetryRow>[
            const _TelemetryRow(
              updated: '-',
              cpuLoad: '-',
              ramUsage: '-',
              latency: '-',
              responseTime: '-',
              packetLoss: '-',
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
          const SizedBox(height: 12),
          Text(
            hasRows 
              ? 'Latest telemetry readings from all monitored devices'
              : 'No telemetry data available',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = _TelemetryLayout.getTableWidth(constraints.maxWidth);
              final columnWidths = _TelemetryLayout.getColumnWidths(tableWidth, isMobile);

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
  final String uptime;

  const _TelemetryRow({
    required this.updated,
    required this.cpuLoad,
    required this.ramUsage,
    required this.latency,
    required this.responseTime,
    required this.packetLoss,
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
      'UPTIME',
    ];

    return Container(
      width: tableWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2C3A).withValues(alpha: 0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Container(
            width: tableWidth,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0D47A1).withValues(alpha: 0.4),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
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
                    isNumeric: i > 0,
                  ),
              ],
            ),
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
        hoverColor: Colors.white.withValues(alpha: 0.08),
        child: Container(
          width: tableWidth,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 16),
          decoration: BoxDecoration(
            color: (isLast ? 0 : 1) % 2 == 0
                ? const Color(0xFF1E2C3A).withValues(alpha: 0.3)
                : const Color(0xFF263849).withValues(alpha: 0.3),
            border: Border(
              bottom: isLast 
                ? BorderSide.none 
                : BorderSide(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 1.0,
                  ),
            ),
          ),
          child: Row(
            children: [
              _tableCell(
                text: row.updated,
                width: columnWidths[0],
                isMobile: isMobile,
                isTime: true,
                isNumeric: false,
              ),
              _tableCell(
                text: row.cpuLoad,
                width: columnWidths[1],
                isMobile: isMobile,
                isNumeric: true,
              ),
              _tableCell(
                text: row.ramUsage,
                width: columnWidths[2],
                isMobile: isMobile,
                isNumeric: true,
              ),
              _tableCell(
                text: row.latency,
                width: columnWidths[3],
                isMobile: isMobile,
                isNumeric: true,
              ),
              _tableCell(
                text: row.responseTime,
                width: columnWidths[4],
                isMobile: isMobile,
                isNumeric: true,
              ),
              _tableCell(
                text: row.packetLoss,
                width: columnWidths[5],
                isMobile: isMobile,
                isNumeric: true,
              ),
              _tableCell(
                text: row.uptime,
                width: columnWidths[6],
                isMobile: isMobile,
                isNumeric: false,
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
    // Make table wider - use full available width or minimum 1400
    return availableWidth > 1400 ? availableWidth * 0.95 : 1400;
  }

  static List<double> getColumnWidths(double tableWidth, bool isMobile) {
    // Subtract horizontal padding of the container to get actual content width
    final horizontalPadding = isMobile ? 24.0 : 32.0;
    final contentWidth = tableWidth - horizontalPadding;

    // Distribution for 7 columns: TIME, CPU, RAM, LATENCY, RESP TIME, PKT LOSS, UPTIME
    final timeWidth = contentWidth * 0.13;      // 13% for Time
    final uptimeWidth = contentWidth * 0.10;    // 10% for Uptime
    final remaining = contentWidth - timeWidth - uptimeWidth;
    final eachMiddle = remaining / 5; // CPU, RAM, LATENCY, RESP TIME, PKT LOSS

    return [
      timeWidth,
      eachMiddle,
      eachMiddle,
      eachMiddle,
      eachMiddle,
      eachMiddle,
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
  bool isNumeric = false,
}) {
  // Determine text alignment based on content type
  final alignment = isTime ? TextAlign.left : (isNumeric ? TextAlign.right : TextAlign.center);
  
  return SizedBox(
    width: width,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12),
      child: Tooltip(
        message: text,
        child: Text(
          text,
          textAlign: alignment,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isHeader 
              ? const Color(0xFF64B5F6)
              : Colors.white.withValues(alpha: 0.85),
            fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
            fontSize: isMobile ? 10 : 13,
            letterSpacing: isHeader ? 0.4 : 0.1,
            height: 1.5,
          ),
        ),
      ),
    ),
  );
}

