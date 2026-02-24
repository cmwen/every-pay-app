import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/data/database/sqlite_expense_repository.dart';
import 'package:everypay/data/database/sqlite_category_repository.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';
import 'package:everypay/domain/repositories/category_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final repo = SqliteExpenseRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final repo = SqliteCategoryRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});
