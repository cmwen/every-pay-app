import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/data/repositories/category_repository_impl.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/core/constants/category_defaults.dart';

void main() {
  late InMemoryCategoryRepository repo;

  setUp(() {
    repo = InMemoryCategoryRepository();
  });

  tearDown(() {
    repo.dispose();
  });

  group('InMemoryCategoryRepository', () {
    test('initializes with default categories', () async {
      final categories = await repo.getAllCategories();
      expect(categories.length, defaultCategories.length);
    });

    test('getCategoryById returns correct category', () async {
      final cat = await repo.getCategoryById('cat-entertainment');
      expect(cat, isNotNull);
      expect(cat!.name, 'Entertainment & Streaming');
    });

    test('getCategoryById returns null for missing id', () async {
      final cat = await repo.getCategoryById('nonexistent');
      expect(cat, isNull);
    });

    test('upsertCategory adds new category', () async {
      final now = DateTime.now();
      await repo.upsertCategory(
        Category(
          id: 'custom-1',
          name: 'Custom Category',
          icon: 'category',
          colour: '#FF0000',
          sortOrder: 100,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final categories = await repo.getAllCategories();
      expect(categories.length, defaultCategories.length + 1);
    });

    test('deleteCategory removes category', () async {
      await repo.deleteCategory('cat-other');
      final categories = await repo.getAllCategories();
      expect(categories.length, defaultCategories.length - 1);
    });

    test('watchCategories emits current state', () async {
      final stream = repo.watchCategories();
      final first = await stream.first;
      expect(first.length, defaultCategories.length);
    });

    test('categories are sorted by sortOrder', () async {
      final categories = await repo.getAllCategories();
      for (int i = 1; i < categories.length; i++) {
        expect(
          categories[i].sortOrder,
          greaterThanOrEqualTo(categories[i - 1].sortOrder),
        );
      }
    });
  });
}
