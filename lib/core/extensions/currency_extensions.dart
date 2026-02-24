import 'package:intl/intl.dart';

extension CurrencyExtensions on double {
  String formatCurrency([String currency = 'USD']) {
    final format = NumberFormat.simpleCurrency(name: currency);
    return format.format(this);
  }

  String formatCompact() {
    if (this >= 1000) {
      return NumberFormat.compact().format(this);
    }
    return toStringAsFixed(2);
  }
}
