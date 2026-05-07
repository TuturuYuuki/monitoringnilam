import 'package:flutter/material.dart';
import 'package:monitoring/widgets/dashboard/status_cards.dart';

class DashboardStatsGrid extends StatelessWidget {
  final int totalTowers;
  final int totalOnlineTowers;
  final int totalDownTowers;
  final int totalUpCameras;
  final int totalDownCameras;
  final int totalUpMMT;
  final int totalDownMMT;
  final int totalUpNVR;
  final int totalDownNVR;
  final int totalUpSwitch;
  final int totalDownSwitch;
  final int totalWarnings;

  const DashboardStatsGrid({
    super.key,
    required this.totalTowers,
    required this.totalOnlineTowers,
    required this.totalDownTowers,
    required this.totalUpCameras,
    required this.totalDownCameras,
    required this.totalUpMMT,
    required this.totalDownMMT,
    required this.totalUpNVR,
    required this.totalDownNVR,
    required this.totalUpSwitch,
    required this.totalDownSwitch,
    required this.totalWarnings,
  });

  bool isMobileScreen(BuildContext context) => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final double spacing = isMobile ? 8.0 : 16.0;

        // CASE 1: Desktop / Ultra-Wide (Expanded grid)
        if (width > 1200) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExpandedCard(NetworkStatusCard(
                    totalOnline: totalOnlineTowers,
                    totalDown: totalDownTowers,
                  )),
                  SizedBox(width: spacing),
                  _buildExpandedCard(CCTVMonitoringCard(
                    totalUp: totalUpCameras,
                    totalDown: totalDownCameras,
                  )),
                  SizedBox(width: spacing),
                  _buildExpandedCard(MMTMonitoringCard(
                    totalUp: totalUpMMT,
                    totalDown: totalDownMMT,
                  )),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExpandedCard(NVRMonitoringCard(
                    totalUp: totalUpNVR,
                    totalDown: totalDownNVR,
                  )),
                  SizedBox(width: spacing),
                  _buildExpandedCard(SwitchMonitoringCard(
                    totalUp: totalUpSwitch,
                    totalDown: totalDownSwitch,
                  )),
                  SizedBox(width: spacing),
                  _buildExpandedCard(ActiveAlertsCard(totalWarnings: totalWarnings)),
                ],
              ),
            ],
          );
        }
        
        // CASE 2: Tablet / Small Laptop (2 columns)
        if (width > 600) {
          return Column(
            children: [
              Row(
                children: [
                  _buildExpandedCard(NetworkStatusCard(
                    totalOnline: totalOnlineTowers,
                    totalDown: totalDownTowers,
                  )),
                  SizedBox(width: spacing),
                  _buildExpandedCard(CCTVMonitoringCard(
                    totalUp: totalUpCameras,
                    totalDown: totalDownCameras,
                  )),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  _buildExpandedCard(MMTMonitoringCard(
                    totalUp: totalUpMMT,
                    totalDown: totalDownMMT,
                  )),
                  SizedBox(width: spacing),
                  _buildExpandedCard(NVRMonitoringCard(
                    totalUp: totalUpNVR,
                    totalDown: totalDownNVR,
                  )),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  _buildExpandedCard(SwitchMonitoringCard(
                    totalUp: totalUpSwitch,
                    totalDown: totalDownSwitch,
                  )),
                  SizedBox(width: spacing),
                  _buildExpandedCard(ActiveAlertsCard(totalWarnings: totalWarnings)),
                ],
              ),
            ],
          );
        }

        // CASE 3: Mobile (Stacked layout)
        return Column(
          children: [
            _buildExpandedCard(NetworkStatusCard(totalOnline: totalOnlineTowers, totalDown: totalDownTowers)),
            SizedBox(height: spacing),
            _buildExpandedCard(CCTVMonitoringCard(totalUp: totalUpCameras, totalDown: totalDownCameras)),
            SizedBox(height: spacing),
            _buildExpandedCard(MMTMonitoringCard(totalUp: totalUpMMT, totalDown: totalDownMMT)),
            SizedBox(height: spacing),
            _buildExpandedCard(NVRMonitoringCard(totalUp: totalUpNVR, totalDown: totalDownNVR)),
            SizedBox(height: spacing),
            _buildExpandedCard(SwitchMonitoringCard(totalUp: totalUpSwitch, totalDown: totalDownSwitch)),
            SizedBox(height: spacing),
            _buildExpandedCard(ActiveAlertsCard(totalWarnings: totalWarnings)),
          ],
        );
      },
    );
  }

  Widget _buildExpandedCard(Widget child) {
    return Expanded(child: child);
  }
}
