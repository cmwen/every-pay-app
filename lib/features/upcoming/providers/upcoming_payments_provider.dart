import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/features/stats/providers/upcoming_provider.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

/// A family provider that produces UpcomingStats for a given number of days.
/// Usage: `ref.watch(upcomingPaymentsProvider(7))` or `ref.watch(upcomingPaymentsProvider(30))`
final upcomingPaymentsProvider = StreamProvider.family<UpcomingStats, int>((
  ref,
  days,
) {
  final repo = ref.watch(expenseRepositoryProvider);
  return repo.watchExpenses().map(
    (expenses) => UpcomingStats.compute(expenses: expenses, days: days),
  );
});
