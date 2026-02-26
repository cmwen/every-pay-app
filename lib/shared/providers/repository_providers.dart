import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/data/database/sqlite_expense_repository.dart';
import 'package:everypay/data/database/sqlite_category_repository.dart';
import 'package:everypay/data/database/sqlite_payment_method_repository.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/entities/expense.dart';
import 'package:everypay/domain/entities/payment_method.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';
import 'package:everypay/domain/repositories/category_repository.dart';
import 'package:everypay/domain/repositories/payment_method_repository.dart';
import 'package:everypay/features/demo/providers/demo_mode_provider.dart';
import 'package:everypay/features/demo/data/demo_expense_repository.dart';
import 'package:everypay/features/demo/data/demo_category_repository.dart';
import 'package:everypay/features/demo/data/demo_payment_method_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final demo = ref.watch(demoModeProvider);
  if (demo.isActive) return DemoExpenseRepository();
  final repo = SqliteExpenseRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final demo = ref.watch(demoModeProvider);
  if (demo.isActive) return DemoCategoryRepository();
  final repo = SqliteCategoryRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final paymentMethodRepositoryProvider = Provider<PaymentMethodRepository>((
  ref,
) {
  final demo = ref.watch(demoModeProvider);
  if (demo.isActive) return DemoPaymentMethodRepository();
  final repo = SqlitePaymentMethodRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// All (non-filtered) categories stream — use this instead of inline StreamProvider.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});

/// All (non-filtered) expenses stream — used by stats/charts.
final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchExpenses();
});

/// All (non-deleted) payment methods stream.
final allPaymentMethodsProvider = StreamProvider<List<PaymentMethod>>((ref) {
  return ref.watch(paymentMethodRepositoryProvider).watchPaymentMethods();
});
