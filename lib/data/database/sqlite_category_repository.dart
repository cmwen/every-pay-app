import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:everypay/data/database/database_helper.dart';
import 'package:everypay/domain/entities/category.dart';
import 'package:everypay/domain/repositories/category_repository.dart';

class SqliteCategoryRepository implements CategoryRepository {
  final _changeController = StreamController<void>.broadcast();

  Map<String, dynamic> _toMap(Category c) => {
        'id': c.id,
        'name': c.name,
        'icon': c.icon,
        'colour': c.colour,
        'is_default': c.isDefault ? 1 : 0,
        'sort_order': c.sortOrder,
        'created_at': c.createdAt.toIso8601String(),
        'updated_at': c.updatedAt.toIso8601String(),
        'is_deleted': 0,
      };

  Category _fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        name: m['name'] as String,
        icon: m['icon'] as String,
        colour: m['colour'] as String,
        isDefault: m['is_default'] == 1,
        sortOrder: m['sort_order'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  @override
  Stream<List<Category>> watchCategories() async* {
    yield await _queryCategories();
    await for (final _ in _changeController.stream) {
      yield await _queryCategories();
    }
  }

  Future<List<Category>> _queryCategories() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'categories',
      where: 'is_deleted = 0',
      orderBy: 'sort_order ASC',
    );
    return results.map(_fromMap).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'categories',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  @override
  Future<void> upsertCategory(Category category) async {
    final db = await DatabaseHelper.database;
    await db.insert(
      'categories',
      _toMap(category),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _changeController.add(null);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'categories',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _changeController.add(null);
  }

  @override
  Future<List<Category>> getAllCategories() async {
    final db = await DatabaseHelper.database;
    final results = await db.query(
      'categories',
      where: 'is_deleted = 0',
      orderBy: 'sort_order ASC',
    );
    return results.map(_fromMap).toList();
  }

  void dispose() {
    _changeController.close();
  }
}
