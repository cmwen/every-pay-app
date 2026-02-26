import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/repositories/category_repository.dart';
import 'package:everypay/features/demo/data/demo_data.dart';

/// In-memory, read-only category repository for demo mode.
class DemoCategoryRepository implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories() {
    return Stream.value(List.from(demoCategories));
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    try {
      return demoCategories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> upsertCategory(Category category) async {
    // No-op in demo mode
  }

  @override
  Future<void> deleteCategory(String id) async {
    // No-op in demo mode
  }

  @override
  Future<List<Category>> getAllCategories() async => List.from(demoCategories);
}
