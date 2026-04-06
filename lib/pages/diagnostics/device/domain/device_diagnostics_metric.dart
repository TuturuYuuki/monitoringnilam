import 'package:flutter/material.dart';

class DeviceDiagnosticsMetric {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const DeviceDiagnosticsMetric({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });
}
