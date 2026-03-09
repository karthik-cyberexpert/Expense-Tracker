import 'package:flutter/material.dart';

/// Helper class to provide icons while allowing Flutter's tree-shaking
/// to correctly identify which icons are used in the application bundle.
class IconHelper {
  /// Maps an icon code (e.g. from database) to a constant [IconData].
  /// This ensures that tree-shaking works correctly.
  static IconData getIcon(int code) {
    // Return IconData directly from code to ensure any codePoint works accurately
    return IconData(code, fontFamily: 'MaterialIcons');
  }

  /// Provides an icon by name for easy reference in seed data.
  static int getCodeFromName(String name) {
    switch (name.toLowerCase()) {
      case 'holiday': return Icons.beach_access.codePoint;
      case 'grocery': return Icons.local_grocery_store.codePoint;
      case 'food': return Icons.restaurant.codePoint;
      case 'beverage': return Icons.local_cafe.codePoint;
      case 'transport': return Icons.directions_car.codePoint;
      case 'internet': return Icons.wifi.codePoint;
      case 'electric': return Icons.electric_bolt.codePoint;
      case 'water': return Icons.water_drop.codePoint;
      case 'gas': return Icons.local_gas_station.codePoint;
      case 'others': return Icons.more_horiz.codePoint;
      case 'salary': return Icons.wallet.codePoint;
      default: return Icons.circle.codePoint;
    }
  }
}
