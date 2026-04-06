class DeviceDiagnosticsEvent {
  final String time;
  final String event;
  final String duration;

  const DeviceDiagnosticsEvent({
    required this.time,
    required this.event,
    required this.duration,
  });
}
