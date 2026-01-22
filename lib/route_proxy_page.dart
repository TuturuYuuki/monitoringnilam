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
    // Minimal scaffold to satisfy OpenContainer openBuilder
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const SizedBox.shrink(),
    );
  }
}
