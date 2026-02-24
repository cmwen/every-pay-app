import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  String get formatted => DateFormat.yMMMd().format(this);

  String get shortFormatted => DateFormat.MMMd().format(this);

  String get dayMonth => DateFormat('d MMM').format(this);

  String get monthYear => DateFormat.yMMM().format(this);

  String daysFromNow() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(year, month, day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff < 0) return '${-diff} days ago';
    if (diff <= 7) return 'In $diff days';
    return shortFormatted;
  }
}
