import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/shared/providers/repository_providers.dart';

class ExpenseFilter {
  final String? categoryId;
  final String status;
  final String? searchQuery;
  final String? paymentMethodId;

  const ExpenseFilter({
    this.categoryId,
    this.status = 'active',
    this.searchQuery,
    this.paymentMethodId,
  });

  ExpenseFilter copyWith({
    String? categoryId,
    String? status,
    String? searchQuery,
    String? paymentMethodId,
    bool clearCategory = false,
    bool clearSearch = false,
    bool clearPaymentMethod = false,
  }) {
    return ExpenseFilter(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      status: status ?? this.status,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      paymentMethodId: clearPaymentMethod
          ? null
          : (paymentMethodId ?? this.paymentMethodId),
    );
  }
}

final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilter>(
      ExpenseFilterNotifier.new,
    );

class ExpenseFilterNotifier extends Notifier<ExpenseFilter> {
  @override
  ExpenseFilter build() => const ExpenseFilter();

  void setFilter(ExpenseFilter filter) => state = filter;
}

final expenseListProvider = StreamProvider<List<Expense>>((ref) {
  final repo = ref.watch(expenseRepositoryProvider);
  final filter = ref.watch(expenseFilterProvider);
  return repo.watchExpenses(
    categoryId: filter.categoryId,
    status: filter.status,
    searchQuery: filter.searchQuery,
    paymentMethodId: filter.paymentMethodId,
  );
});
