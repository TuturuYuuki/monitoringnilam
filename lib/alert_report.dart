import 'package:flutter/material.dart';
import 'widgets/global_header_bar.dart';
import 'widgets/global_sidebar_nav.dart';

class AlertReportPage extends StatelessWidget {
  const AlertReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/alert-report'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar (Kiri)
                const GlobalSidebarNav(currentRoute: '/alert-report'),
                const SizedBox(width: 12),
                // Content (Kanan)
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assessment,
                              size: 80, color: Colors.blueGrey),
                          SizedBox(height: 16),
                          Text(
                            'Alert Report',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Halaman ini dalam pengembangan',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
