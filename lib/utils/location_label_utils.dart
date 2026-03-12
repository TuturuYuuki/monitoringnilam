String normalizeLocationLabel(String value) {
  var normalized = value.trim();
  if (normalized.isEmpty) return normalized;

  normalized = normalized.replaceFirst(
    RegExp(r'^device\s*-\s*', caseSensitive: false),
    '',
  );

  normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  return normalized;
}

String buildMasterLocationLabel({
  required String locationType,
  required String locationCode,
  required String locationName,
  required String containerYard,
}) {
  final normalizedType = locationType.trim().toUpperCase();
  final normalizedCode = locationCode.trim();
  final normalizedName = locationName.trim();
  final normalizedYard = containerYard.trim().toUpperCase();

  // Format CY label: "CY1" → "CY 1"
  String cyLabel = normalizedYard;
  final cyMatch = RegExp(r'^(CY)\s*(\d+)$', caseSensitive: false).firstMatch(normalizedYard);
  if (cyMatch != null) {
    cyLabel = '${cyMatch.group(1)!.toUpperCase()} ${cyMatch.group(2)}';
  }

  // Use locationName if available, otherwise locationCode
  final mainLabel = normalizedName.isNotEmpty
      ? normalizedName
      : (normalizedCode.isNotEmpty ? normalizedCode : 'UNKNOWN');

  return '$normalizedType - $mainLabel - $cyLabel';
}

String normalizeLocationMatchKey(String value) {
  return normalizeLocationLabel(value)
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

List<Map<String, String>> buildMasterLocationOptions(
  List<Map<String, dynamic>> rows,
) {
  final options = <Map<String, String>>[];

  for (final row in rows) {
    final label = buildMasterLocationLabel(
      locationType: (row['location_type'] ?? '').toString(),
      locationCode: (row['location_code'] ?? '').toString(),
      locationName: (row['location_name'] ?? '').toString(),
      containerYard: (row['container_yard'] ?? '').toString(),
    );

    options.add({
      'label': label,
      'container_yard': (row['container_yard'] ?? '').toString().toUpperCase(),
      'location_type': (row['location_type'] ?? '').toString().toUpperCase(),
      'location_code': (row['location_code'] ?? '').toString(),
      'location_name': (row['location_name'] ?? '').toString(),
    });
  }

  options.sort(
    (a, b) => (a['label'] ?? '').toLowerCase().compareTo(
          (b['label'] ?? '').toLowerCase(),
        ),
  );
  return options;
}

Map<String, String>? matchMasterLocationOption(
  List<Map<String, String>> options,
  String currentLocation, {
  String? currentContainerYard,
}) {
  final currentKey = normalizeLocationMatchKey(currentLocation);
  final currentYard = (currentContainerYard ?? '').trim().toUpperCase();

  for (final option in options) {
    final label = option['label'] ?? '';
    final labelKey = normalizeLocationMatchKey(label);
    final codeKey = normalizeLocationMatchKey(option['location_code'] ?? '');
    final nameKey = normalizeLocationMatchKey(option['location_name'] ?? '');
    final sameYard = currentYard.isEmpty || option['container_yard'] == currentYard;

    final matched = labelKey == currentKey ||
        (codeKey.isNotEmpty && (currentKey.contains(codeKey) || codeKey.contains(currentKey))) ||
        (nameKey.isNotEmpty && (currentKey.contains(nameKey) || nameKey.contains(currentKey)));

    if (matched && sameYard) {
      return option;
    }
  }

  for (final option in options) {
    final labelKey = normalizeLocationMatchKey(option['label'] ?? '');
    final codeKey = normalizeLocationMatchKey(option['location_code'] ?? '');
    final nameKey = normalizeLocationMatchKey(option['location_name'] ?? '');

    final matched = labelKey == currentKey ||
        (codeKey.isNotEmpty && (currentKey.contains(codeKey) || codeKey.contains(currentKey))) ||
        (nameKey.isNotEmpty && (currentKey.contains(nameKey) || nameKey.contains(currentKey)));

    if (matched) {
      return option;
    }
  }

  return options.isNotEmpty ? options.first : null;
}