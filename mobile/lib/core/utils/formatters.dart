import 'package:intl/intl.dart';

/// Display formatting helpers for money and dates.
abstract final class Formatters {
  /// Renders integer minor units (cents) as a currency string, e.g. 4500 -> $45.00.
  static String money(int minorUnits, String currency) {
    final major = minorUnits / 100;
    return '${_symbol(currency)}${major.toStringAsFixed(2)}';
  }

  static String _symbol(String currency) => switch (currency) {
        'USD' => '\$',
        'EUR' => '€',
        'GBP' => '£',
        'NGN' => '₦',
        'EGP' => 'E£',
        'AED' => 'AED ',
        'SAR' => 'SAR ',
        _ => '$currency ',
      };

  static String weekdayShort(DateTime date) => DateFormat('EEE').format(date);
  static String dayOfMonth(DateTime date) => DateFormat('d').format(date);
  static String monthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);
  static String fullDate(DateTime date) => DateFormat('EEE, MMM d').format(date);
  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  /// "1h 30m" style duration label.
  static String durationLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }
}
