import 'package:flutter/material.dart';
import 'package:monitoring/pages/alerts/alerts.dart';
import 'package:monitoring/pages/cctv/cctv.dart';
import 'package:monitoring/pages/mmt/mmt_monitoring.dart';
import 'package:monitoring/pages/network/network.dart';

class TowerStatusTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final double iconBoxSize;
  final double iconSize;
  final double countFontSize;
  final double labelFontSize;
  final double spacing;

  const TowerStatusTile({
    super.key,
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    this.iconBoxSize = 60,
    this.iconSize = 30,
    this.countFontSize = 28,
    this.labelFontSize = 12,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
          SizedBox(height: spacing),
          Text(
            '$count',
            style: TextStyle(
              color: Colors.white,
              fontSize: countFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: labelFontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCardShell extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _DashboardCardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF3B4D63).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusCardFrame extends StatelessWidget {
  final VoidCallback onTap;
  final IconData headerIcon;
  final String title;
  final List<Widget> tiles;
  final EdgeInsetsGeometry padding;
  final int maxTitleLines;

  const _StatusCardFrame({
    required this.onTap,
    required this.headerIcon,
    required this.title,
    required this.tiles,
    required this.padding,
    required this.maxTitleLines,
  }); 

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 320 || constraints.maxHeight < 220;
            final iconPad = compact ? 8.0 : 10.0;
            final headerFont = compact ? 12.0 : 15.0;
            final topGap = compact ? 8.0 : 14.0;
            final tileGap = compact ? 6.0 : 16.0;

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight == double.infinity
                  ? (compact ? 160 : 185)
                  : constraints.maxHeight,
              child: _DashboardCardShell(
                padding: padding,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(compact ? 6 : 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            headerIcon,
                            color: Colors.white,
                            size: compact ? 18 : 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: maxTitleLines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: headerFont,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.1,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: topGap),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (int i = 0; i < tiles.length; i++) ...[
                            Expanded(child: Center(child: tiles[i])),
                            if (i != tiles.length - 1) SizedBox(width: tileGap),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class NetworkStatusCard extends StatelessWidget {
  final int totalOnline;
  final int totalDown;

  const NetworkStatusCard({
    super.key,
    required this.totalOnline,
    required this.totalDown,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCardFrame(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NetworkPage()),
      ),
      headerIcon: Icons.router,
      title: 'Access Point Monitoring',
      padding: const EdgeInsets.all(16),
      maxTitleLines: 2,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalOnline,
                label: 'UP',
                color: Colors.green,
                icon: Icons.wifi,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalDown,
                label: 'DOWN',
                color: Colors.red,
                icon: Icons.wifi_off,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

class CCTVMonitoringCard extends StatelessWidget {
  final int totalUp;
  final int totalDown;

  const CCTVMonitoringCard({
    super.key,
    required this.totalUp,
    required this.totalDown,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCardFrame(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CCTVPage()),
      ),
      headerIcon: Icons.videocam,
      title: 'CCTV Monitoring',
      padding: const EdgeInsets.all(16),
      maxTitleLines: 2,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalUp,
                label: 'UP',
                color: Colors.green,
                icon: Icons.videocam,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalDown,
                label: 'DOWN',
                color: Colors.red,
                icon: Icons.videocam_off,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

class MMTMonitoringCard extends StatelessWidget {
  final int totalUp;
  final int totalDown;

  const MMTMonitoringCard({
    super.key,
    required this.totalUp,
    required this.totalDown,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCardFrame(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MMTMonitoringPage()),
      ),
      headerIcon: Icons.tablet_android,
      title: 'MMT Monitoring',
      padding: const EdgeInsets.all(16),
      maxTitleLines: 2,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalUp,
                label: 'UP',
                color: Colors.green,
                icon: Icons.tablet_android,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalDown,
                label: 'DOWN',
                color: Colors.red,
                icon: Icons.tablet_android,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

class ActiveAlertsCard extends StatelessWidget {
  final int totalWarnings;

  const ActiveAlertsCard({
    super.key,
    required this.totalWarnings,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCardFrame(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AlertsPage()),
      ),
      headerIcon: Icons.warning_amber_rounded,
      title: 'Alert Monitoring',
      padding: const EdgeInsets.all(16),
      maxTitleLines: 2,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 140;
              return TowerStatusTile(
                count: totalWarnings,
                label: 'DOWN',
                color: Colors.red,
                icon: Icons.report_problem,
                iconBoxSize: compact ? 48 : 56,
                iconSize: compact ? 24 : 28,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

class NVRMonitoringCard extends StatelessWidget {
  final int totalUp;
  final int totalDown;

  const NVRMonitoringCard({
    super.key,
    required this.totalUp,
    required this.totalDown,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCardFrame(
      onTap: () => Navigator.pushNamed(context, '/nvr-monitoring-cy1'),
      headerIcon: Icons.dns,
      title: 'NVR Monitoring',
      padding: const EdgeInsets.all(16),
      maxTitleLines: 2,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalUp,
                label: 'UP',
                color: Colors.green,
                icon: Icons.dns,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalDown,
                label: 'DOWN',
                color: Colors.red,
                icon: Icons.dns_outlined,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

class SwitchMonitoringCard extends StatelessWidget {
  final int totalUp;
  final int totalDown;

  const SwitchMonitoringCard({
    super.key,
    required this.totalUp,
    required this.totalDown,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCardFrame(
      onTap: () => Navigator.pushNamed(context, '/switch-monitoring-cy1'),
      headerIcon: Icons.device_hub,
      title: 'Switch Monitoring',
      padding: const EdgeInsets.all(16),
      maxTitleLines: 2,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalUp,
                label: 'UP',
                color: Colors.green,
                icon: Icons.device_hub,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalDown,
                label: 'DOWN',
                color: Colors.red,
                icon: Icons.device_hub,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

class PCMonitoringCard extends StatelessWidget {
  final int totalUp;
  final int totalDown;

  const PCMonitoringCard({
    super.key,
    required this.totalUp,
    required this.totalDown,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusCardFrame(
      onTap: () => Navigator.pushNamed(context, '/pc-monitoring'),
      headerIcon: Icons.desktop_windows,
      title: 'PC Monitoring',
      padding: const EdgeInsets.all(16),
      maxTitleLines: 2,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalUp,
                label: 'UP',
                color: Colors.green,
                icon: Icons.desktop_windows,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalDown,
                label: 'DOWN',
                color: Colors.red,
                icon: Icons.desktop_windows,
                iconBoxSize: compact ? 46 : 52,
                iconSize: compact ? 22 : 26,
                countFontSize: compact ? 22 : 26,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 6 : 8,
              );
            },
          ),
        ),
      ],
    );
  }
}

class SystemHealthCard extends StatelessWidget {
  final double uptimePercent;
  final double avgLatency;
  final double packetLoss;

  const SystemHealthCard({
    super.key,
    required this.uptimePercent,
    this.avgLatency = 0.0,
    this.packetLoss = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color healthColor = uptimePercent >= 95 
        ? Colors.green 
        : (uptimePercent >= 80 ? Colors.orange : Colors.red);

    return _StatusCardFrame(
      onTap: () => Navigator.pushNamed(context, '/global-diagnostics'),
      headerIcon: Icons.health_and_safety,
      title: 'System Health Status',
      padding: const EdgeInsets.all(16),
      maxTitleLines: 2,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 140;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. Latency Circle (Left)
                  _buildStatusCircle(
                    value: (1.0 - (avgLatency / 200).clamp(0.0, 1.0)),
                    displayValue: '${avgLatency.toStringAsFixed(0)}ms',
                    label: 'Latency',
                    color: avgLatency < 50 ? Colors.cyanAccent : (avgLatency < 150 ? Colors.orangeAccent : Colors.redAccent),
                    compact: compact,
                  ),
                  
                  // 2. Main Health Circle (Center - Larger)
                  _buildStatusCircle(
                    value: uptimePercent / 100,
                    displayValue: '${uptimePercent.toStringAsFixed(1)}%',
                    label: 'Health',
                    color: healthColor,
                    compact: compact,
                    isMain: true,
                  ),

                  // 3. Stability Circle (Right)
                  _buildStatusCircle(
                    value: (1.0 - (packetLoss / 10).clamp(0.0, 1.0)),
                    displayValue: '${(100 - packetLoss).toStringAsFixed(1)}%',
                    label: 'Stable',
                    color: packetLoss < 1 ? Colors.greenAccent : (packetLoss < 5 ? Colors.yellowAccent : Colors.redAccent),
                    compact: compact,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCircle({
    required double value,
    required String displayValue,
    required String label,
    required Color color,
    required bool compact,
    bool isMain = false,
  }) {
    final double size = isMain ? (compact ? 48 : 58) : (compact ? 38 : 44);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: isMain ? 4 : 3,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              displayValue,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMain ? (compact ? 9 : 11) : (compact ? 8 : 9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: isMain ? (compact ? 9 : 10) : (compact ? 8 : 9),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetric(IconData icon, String value, String label, bool compact) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 10 : 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: compact ? 8 : 9,
          ),
        ),
      ],
    );
  }
}