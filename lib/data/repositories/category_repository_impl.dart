import 'dart:async';

import 'package:everypay/core/constants/category_defaults.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/repositories/category_repository.dart';

class InMemoryCategoryRepository implements CategoryRepository {
  final Map<String, Category> _categories = {};
  final _controller = StreamController<void>.broadcast();

  InMemoryCategoryRepository() {
    for (final cat in defaultCategories) {
      _categories[cat.id] = cat;
    }
  }

  List<Category> get _sorted =>
      _categories.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void _notify() {
    _controller.add(null);
  }

  @override
  Stream<List<Category>> watchCategories() async* {
    yield _sorted;
    await for (final _ in _controller.stream) {
      yield _sorted;
    }
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    return _categories[id];
  }

  @override
  Future<void> upsertCategory(Category category) async {
    _categories[category.id] = category;
    _notify();
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.remove(id);
    _notify();
  }

  @override
  Future<List<Category>> getAllCategories() async {
    return _sorted;
  }

  void dispose() {
    _controller.close();
  }
}
