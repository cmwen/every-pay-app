import 'package:flutter_test/flutter_test.dart';
import 'package:everypay/domain/entities/category.dart';

void main() {
  group('Category', () {
    test('creates with required fields', () {
      final now = DateTime.now();
      final cat = Category(
        id: 'test-cat',
        name: 'Test Category',
        icon: 'category',
        colour: '#FF0000',
        createdAt: now,
        updatedAt: now,
      );

      expect(cat.id, 'test-cat');
      expect(cat.name, 'Test Category');
      expect(cat.icon, 'category');
      expect(cat.colour, '#FF0000');
      expect(cat.isDefault, isFalse);
      expect(cat.sortOrder, 0);
    });

    test('copyWith creates modified copy', () {
      final now = DateTime.now();
      final cat = Category(
        id: 'test-cat',
        name: 'Original',
        icon: 'category',
        colour: '#FF0000',
        createdAt: now,
        updatedAt: now,
      );

      final modified = cat.copyWith(name: 'Modified', colour: '#00FF00');

      expect(modified.name, 'Modified');
      expect(modified.colour, '#00FF00');
      expect(modified.id, cat.id);
      expect(modified.icon, cat.icon);
    });
  });
}
