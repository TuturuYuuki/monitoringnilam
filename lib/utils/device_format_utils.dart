import 'package:monitoring/utils/location_label_utils.dart';

String formatNVRDisplay(String nvrId, String location) {
  return formatFullStandardLabel('NVR', nvrId, location);
}

String formatSwitchDisplay(String switchId, String location) {
  return formatFullStandardLabel('SWITCH', switchId, location);
}

String formatMMTDisplay(String mmtId, String location) {
  return formatFullStandardLabel('MMT', mmtId, location);
}

String formatCCTVDisplay(String cameraId, String location) {
  return formatFullStandardLabel('CCTV', cameraId, location);
}

/// Generic formatter that auto-detects device type
String formatDeviceDisplay(String deviceType, String id, String location) {
  return formatFullStandardLabel(deviceType, id, location);
}
