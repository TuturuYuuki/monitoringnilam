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

String formatFullStandardLabel(String? type, String? id, String? yard) {
  String normalizeType(String rawType) {
    final normalized = rawType.trim().toUpperCase();
    if (normalized == 'ACCESS_POINT' || normalized == 'ACCESS POINT') {
      return 'AP';
    }
    return normalized;
  }

  String normalizeLocationToken(String rawLocation) {
    final raw = rawLocation.trim().toUpperCase();
    if (raw.isEmpty) return '';

    final cyMatch = RegExp(r'CY\s*(\d+)', caseSensitive: false).firstMatch(raw);
    if (cyMatch != null) {
      return 'CY${cyMatch.group(1)}';
    }
    if (raw.contains('GATE')) return 'GATE';
    if (raw.contains('PARKING')) return 'PARKING';

    final parts = raw
        .split(RegExp(r'[^A-Z0-9]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) {
      return parts.last;
    }
    return raw.replaceAll(' ', '');
  }

  final t = normalizeType(type ?? '');
  String i = (id ?? '').trim().toUpperCase();
  final y = normalizeLocationToken(yard ?? '');

  if (t.isEmpty && i.isEmpty && y.isEmpty) return 'UNKNOWN';

  // 1. Remove redundant yard from ID (e.g. "TOWER T5 PARKING" -> "TOWER T5")
  // We do this aggressively to handle cases like "PARKING - PARKING" or "MMT TOWER PARKING PARKING"
  if (y.isNotEmpty) {
    final escapedY = RegExp.escape(y);
    final yardRegex = RegExp(r'\s*[-\s]*' + escapedY + r'\b', caseSensitive: false);
    
    // Keep removing until no more matches at the end or as a standalone word
    String lastI;
    do {
      lastI = i;
      i = i.replaceAll(yardRegex, '').trim();
    } while (i != lastI && i.isNotEmpty);
    
    if (i == y) i = '';
  }

  // 2. Remove redundant type from ID (e.g. "TOWER T5" -> "T5")
  if (t.isNotEmpty) {
    final escapedT = RegExp.escape(t);
    final typeRegex = RegExp(r'^' + escapedT + r'(\s+|[-_\s]+)', caseSensitive: false);
    
    String lastI;
    do {
      lastI = i;
      i = i.replaceFirst(typeRegex, '').trim();
    } while (i != lastI && i.isNotEmpty);
    
    if (i == t) i = '';
  }

  final parts = <String>[];
  if (t.isNotEmpty) parts.add(t);
  if (i.isNotEmpty) parts.add(i);
  if (y.isNotEmpty) parts.add(y);

  // join with space and clean up double spaces
  final result = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  
  // Final check: if the result ends with "Y Y", remove one Y
  if (y.isNotEmpty) {
     final escapedY = RegExp.escape(y);
     final doubleYardRegex = RegExp(r'\b' + escapedY + r'\s+' + escapedY + r'$', caseSensitive: false);
     return result.replaceFirst(doubleYardRegex, y);
  }

  return result;
}

String formatDisplayLocation(String location) {
  var formatted = location;
  // Replace T or TOWER followed by digits with Tower followed by digits
  formatted = formatted.replaceAllMapped(RegExp(r'\b(?:TOWER|T)\s*(\d+)\b', caseSensitive: false), (match) {
    return 'Tower ${match.group(1)}';
  });
  return formatted;
}

String canonicalizeLocationLabel(String value) {
  final normalized = normalizeLocationLabel(value);
  if (normalized.isEmpty) return normalized;

  final segments = normalized
      .split(RegExp(r'\s*-\s*'))
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

  String prettifySegment(String segment) {
    String s = segment.toUpperCase();
    final cyMatch = RegExp(r'^CY\s*(\d+)$', caseSensitive: false).firstMatch(s);
    if (cyMatch != null) {
      return 'CY${cyMatch.group(1)}';
    }
    if (s == 'ACCESS POINT' || s == 'ACCESS_POINT' || s == 'AP') return 'AP';
    
    return s;
  }

  final prettifiedSegments = segments.map(prettifySegment).toList();
  return prettifiedSegments.join(' ');
}

String buildMasterLocationLabel({
  required String locationType,
  required String locationCode,
  required String locationName,
  required String containerYard,
}) {
  final normalizedType = locationType.trim().toUpperCase();
  final normalizedCode = locationCode.trim().toUpperCase();
  final normalizedYard = containerYard.trim().toUpperCase();

  // Prefer code as ID (T1, R4), fallback to name if code is empty
  String idPart = normalizedCode.isNotEmpty ? normalizedCode : locationName.trim().toUpperCase();

  // Strip redundant type from ID ONLY if it is an exact match or followed by space
  // This ensures "RTG RTG1" stays as "RTG RTG1" while "RTG RTG 01" becomes "RTG 01"
  String displayType = normalizedType;
  if (normalizedType == 'ACCESS_POINT') displayType = 'ACCESS POINT';
  
  // We strictly follow [TYPE] [ID] [LOCATION] without over-cleaning the ID
  // to keep it synchronized with what is shown in Master Data.
  return formatFullStandardLabel(displayType, idPart, normalizedYard);
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
  if (currentLocation.trim().isEmpty) return null;

  final currentKey = normalizeLocationMatchKey(currentLocation);
  final currentYard = (currentContainerYard ?? '').trim().toUpperCase().replaceAll(' ', '');

  // Helper to strip "CY X" part from key for more flexible matching
  String stripYardFromKey(String key) {
    return key.replaceAll(RegExp(r'CY\d+$'), '')
              .replaceAll(RegExp(r'PARKING$'), '')
              .replaceAll(RegExp(r'GATE$'), '');
  }
  final currentCodeOnlyKey = stripYardFromKey(currentKey);

  // Pass 1: Strict Match in Same Yard
  for (final option in options) {
    final optionYard = (option['container_yard'] ?? '').trim().toUpperCase().replaceAll(' ', '');
    final sameYard = currentYard.isEmpty || optionYard == currentYard;
    if (!sameYard) continue;

    final labelKey = normalizeLocationMatchKey(option['label'] ?? '');
    final codeKey = normalizeLocationMatchKey(option['location_code'] ?? '');
    final nameKey = normalizeLocationMatchKey(option['location_name'] ?? '');
    
    final formattedCodeKey = normalizeLocationMatchKey(formatDisplayLocation(option['location_code'] ?? ''));
    final formattedNameKey = normalizeLocationMatchKey(formatDisplayLocation(option['location_name'] ?? ''));

    // Check if input matches label exactly, or if input contains the code/name
    if (labelKey == currentKey || codeKey == currentKey || nameKey == currentKey ||
        formattedCodeKey == currentKey || formattedNameKey == currentKey ||
        (codeKey.isNotEmpty && currentKey.contains(codeKey)) ||
        (nameKey.isNotEmpty && currentKey.contains(nameKey)) ||
        (codeKey.isNotEmpty && currentCodeOnlyKey == codeKey) ||
        (nameKey.isNotEmpty && currentCodeOnlyKey == nameKey)) {
      return option;
    }
  }

  // Pass 2: Strict Match in Any Yard
  for (final option in options) {
    final labelKey = normalizeLocationMatchKey(option['label'] ?? '');
    final codeKey = normalizeLocationMatchKey(option['location_code'] ?? '');
    final nameKey = normalizeLocationMatchKey(option['location_name'] ?? '');

    if (labelKey == currentKey || codeKey == currentKey || nameKey == currentKey ||
        (codeKey.isNotEmpty && currentKey.contains(codeKey)) ||
        (nameKey.isNotEmpty && currentKey.contains(nameKey)) ||
        (codeKey.isNotEmpty && currentCodeOnlyKey == codeKey) ||
        (nameKey.isNotEmpty && currentCodeOnlyKey == nameKey)) {
      return option;
    }
  }

  // Pass 3: Fuzzy Match (Prefix/Suffix) - Only as last resort
  for (final option in options) {
    final codeKey = normalizeLocationMatchKey(option['location_code'] ?? '');
    if (codeKey.isEmpty) continue;
    
    if (currentKey.startsWith(codeKey) || currentKey.endsWith(codeKey) || currentKey.contains(codeKey)) {
      if (codeKey.length > 1) {
         return option;
      }
    }
  }

  return null;
}

String resolveFullLocationLabel(
  List<Map<String, String>> options,
  String currentLocation, {
  String? currentContainerYard,
}) {
  if (currentLocation.trim().isEmpty) return 'UNKNOWN';

  // 1. Try to find a match in Master Data
  final matched = matchMasterLocationOption(options, currentLocation, currentContainerYard: currentContainerYard);
  if (matched != null) {
    return formatFullStandardLabel(
      matched['location_type'],
      (matched['location_code'] ?? '').isNotEmpty
          ? matched['location_code']
          : matched['location_name'],
      matched['container_yard'],
    );
  }

  // 2. Fallback: Clean up the input string and ensure standard format
  // Strip redundant yard from the string if we already have it in currentContainerYard
  String cleanLocation = currentLocation;
  final y = (currentContainerYard ?? '').trim().toUpperCase();
  
  if (y.isNotEmpty) {
    final escapedY = RegExp.escape(y);
    // Remove yard at the end (e.g. "T5 PARKING" -> "T5")
    cleanLocation = cleanLocation.replaceAll(RegExp(r'\s*[-\s]*' + escapedY + r'\s*$', caseSensitive: false), '').trim();
  }

  // Use formatFullStandardLabel to assemble the parts correctly
  return formatFullStandardLabel('', cleanLocation, y);
}