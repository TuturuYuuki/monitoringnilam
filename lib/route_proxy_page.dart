import 'package:flutter/material.dart';

class RouteProxyPage extends StatefulWidget {
  final String routeName;
  const RouteProxyPage(this.routeName, {super.key});

  @override
  State<RouteProxyPage> createState() => _RouteProxyPageState();
}

class _RouteProxyPageState extends State<RouteProxyPage> {
  @override
  void initState() {
    super.initState();
    // Navigate after the transition starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, widget.routeName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF2C3E50),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading page...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
