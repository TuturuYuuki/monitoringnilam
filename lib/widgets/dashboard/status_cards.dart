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
              color: color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.7),
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
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF3B4D63).withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1.2),
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
    this.padding = const EdgeInsets.all(20),
    this.maxTitleLines = 2,
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
            final iconPad = compact ? 10.0 : 12.0;
            final headerFont = compact ? 14.0 : 18.0;
            final topGap = compact ? 20.0 : 28.0;
            final tileGap = compact ? 10.0 : 16.0;

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight == double.infinity
                  ? 240
                  : constraints.maxHeight,
              child: _DashboardCardShell(
                padding: padding,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(iconPad),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            headerIcon,
                            color: Colors.white,
                            size: compact ? 24 : 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: maxTitleLines,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: headerFont,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
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
                iconBoxSize: compact ? 52 : 60,
                iconSize: compact ? 24 : 30,
                countFontSize: compact ? 24 : 28,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 8 : 12,
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
                iconBoxSize: compact ? 52 : 60,
                iconSize: compact ? 24 : 30,
                countFontSize: compact ? 24 : 28,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 8 : 12,
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
                iconBoxSize: compact ? 52 : 60,
                iconSize: compact ? 24 : 30,
                countFontSize: compact ? 24 : 28,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 8 : 12,
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
                iconBoxSize: compact ? 52 : 60,
                iconSize: compact ? 24 : 30,
                countFontSize: compact ? 24 : 28,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 8 : 12,
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
      headerIcon: Icons.tablet_mac,
      title: 'MMT Monitoring',
      maxTitleLines: 1,
      tiles: [
        Builder(
          builder: (context) => LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 120;
              return TowerStatusTile(
                count: totalUp,
                label: 'UP',
                color: Colors.green,
                icon: Icons.tablet_mac,
                iconBoxSize: compact ? 52 : 60,
                iconSize: compact ? 24 : 30,
                countFontSize: compact ? 24 : 28,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 8 : 12,
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
                icon: Icons.tablet_mac,
                iconBoxSize: compact ? 52 : 60,
                iconSize: compact ? 24 : 30,
                countFontSize: compact ? 24 : 28,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 8 : 12,
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
      maxTitleLines: 1,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                iconBoxSize: compact ? 56 : 64,
                iconSize: compact ? 28 : 34,
                countFontSize: compact ? 24 : 28,
                labelFontSize: compact ? 11 : 12,
                spacing: compact ? 8 : 12,
              );
            },
          ),
        ),
      ],
    );
  }
}
