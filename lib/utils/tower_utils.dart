import 'package:monitoring/models/tower_model.dart';

class TowerUtils {
  /// Normalizes and sorts a list of towers by their ID and number.
  /// Removes duplicates based on towerId (case-insensitive).
  static List<Tower> normalizeAndSortTowers(List<Tower> input) {
    final dedup = <String, Tower>{};
    for (final tower in input) {
      dedup[tower.towerId.toLowerCase()] = tower;
    }
    final list = dedup.values.toList();
    list.sort((a, b) => orderValue(a).compareTo(orderValue(b)));
    return list;
  }

  /// Calculates a numeric sort value for a tower.
  static double orderValue(Tower tower) {
    if (tower.towerNumber > 0) {
      return tower.towerNumber.toDouble();
    }

    final regex = RegExp(r'^(\d+)([A-Za-z]?)$');
    final match = regex.firstMatch(tower.towerId.trim());
    if (match != null) {
      final base = double.tryParse(match.group(1) ?? '') ?? 9999;
      final suffix = match.group(2);
      if (suffix != null && suffix.isNotEmpty) {
        final offset = (suffix.codeUnitAt(0) - 'A'.codeUnitAt(0) + 1) / 10;
        return base + offset;
      }
      return base;
    }

    return 9999;
  }
}
