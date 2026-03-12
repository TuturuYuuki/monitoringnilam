import 'dart:core';

void main() {
  final titles = [
    'Access Point DOWN - AP01',
    'CCTV DOWN - CAM-G2',
    'AP01 is DOWN',
    'CAM-G2 is DOWN',
    'AP01 is offline',
    'MMT-05 is DOWN',
    'MMT DOWN - MMT-05',
    'MMT DOWN - MMT-02'
  ];

  final uniqueAlerts = <String, String>{};

  for (final t in titles) {
    String devName = t;
    devName = devName.replaceAll(RegExp(r'(.*?)\s+is\s+(now\s+)?(DOWN|UP|WARNING)', caseSensitive: false), '\$1');
    devName = devName.replaceAll(RegExp(r'(Access\sPoint|CCTV|MMT)\s+DOWN\s+-\s+', caseSensitive: false), '');
    devName = devName.trim();
    
    uniqueAlerts[devName] = t;
  }

  print("Parsed Unique Names:");
  uniqueAlerts.keys.forEach(print);
}
