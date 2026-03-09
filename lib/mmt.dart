import 'package:flutter/material.dart';
import 'widgets/global_header_bar.dart';

class MMTPage extends StatelessWidget {
  const MMTPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            top: 60,
            child: Container(
              color: Colors.grey.shade100,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor, size: 80, color: Colors.blueGrey),
                    SizedBox(height: 16),
                    Text(
                      'MMT Monitoring',
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
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlobalHeaderBar(currentRoute: '/mmt'),
          ),
        ],
      ),
    );
  }
}
