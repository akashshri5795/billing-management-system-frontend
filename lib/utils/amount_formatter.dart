import 'package:intl/intl.dart';

class AmountFormatter {
  AmountFormatter._(); // prevent instance creation

  // Safe double conversion
  static double safeDouble(dynamic val) {
    if (val == null) return 0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0;
    return 0;
  }

  // Indian format with 2 fixed decimals (NO ₹)
  static final NumberFormat _inrFormat =
  NumberFormat('#,##,##0.00', 'en_IN');

  /// Main method to use everywhere
  static String format(dynamic value) {
    return _inrFormat.format(safeDouble(value));
  }

  /// Optional: Dr / Cr format
  static String formatWithDrCr(double value) {
    if (value == 0) return '0.00';
    return value > 0
        ? '${format(value)} Dr'
        : '${format(value.abs())} Cr';
  }
}
