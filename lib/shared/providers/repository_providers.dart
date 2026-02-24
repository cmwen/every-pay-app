import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:everypay/data/repositories/expense_repository_impl.dart';
import 'package:everypay/data/repositories/category_repository_impl.dart';
import 'package:everypay/domain/repositories/expense_repository.dart';
import 'package:everypay/domain/repositories/category_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final repo = InMemoryExpenseRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final repo = InMemoryCategoryRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});
