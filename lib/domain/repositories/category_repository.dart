import 'package:everypay/domain/entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> watchCategories();
  Future<Category?> getCategoryById(String id);
  Future<void> upsertCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<List<Category>> getAllCategories();
}
