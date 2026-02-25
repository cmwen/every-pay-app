import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:everypay/core/constants/category_defaults.dart';

class DatabaseHelper {
  static Database? _database;
  static const _dbName = 'everypay.db';
  static const _dbVersion = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT 'category',
        colour TEXT NOT NULL DEFAULT '#546E7A',
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        device_id TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        provider TEXT,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT 'USD',
        billing_cycle TEXT NOT NULL,
        custom_days INTEGER,
        start_date TEXT NOT NULL,
        end_date TEXT,
        next_due_date TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT,
        logo_asset TEXT,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        device_id TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_state (
        device_id TEXT PRIMARY KEY,
        last_sync_at TEXT NOT NULL,
        last_expense_sync TEXT,
        last_category_sync TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE paired_devices (
        id TEXT PRIMARY KEY,
        device_name TEXT NOT NULL,
        device_id TEXT NOT NULL UNIQUE,
        paired_at TEXT NOT NULL,
        last_seen TEXT,
        public_key TEXT,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create indexes
    await db.execute(
      'CREATE INDEX idx_expenses_category ON expenses(category_id)',
    );
    await db.execute('CREATE INDEX idx_expenses_status ON expenses(status)');
    await db.execute(
      'CREATE INDEX idx_expenses_deleted ON expenses(is_deleted)',
    );
    await db.execute(
      'CREATE INDEX idx_categories_deleted ON categories(is_deleted)',
    );

    // v2 additions
    await _createPaymentMethodsTable(db);
    await db.execute(
      'ALTER TABLE expenses ADD COLUMN payment_method_id TEXT REFERENCES payment_methods(id)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_payment_method ON expenses(payment_method_id)',
    );

    // Seed default categories
    final batch = db.batch();
    for (final cat in defaultCategories) {
      batch.insert('categories', {
        'id': cat.id,
        'name': cat.name,
        'icon': cat.icon,
        'colour': cat.colour,
        'is_default': cat.isDefault ? 1 : 0,
        'sort_order': cat.sortOrder,
        'created_at': cat.createdAt.toIso8601String(),
        'updated_at': cat.updatedAt.toIso8601String(),
        'is_deleted': 0,
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createPaymentMethodsTable(db);
      await db.execute(
        'ALTER TABLE expenses ADD COLUMN payment_method_id TEXT REFERENCES payment_methods(id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_payment_method ON expenses(payment_method_id)',
      );
    }
  }

  static Future<void> _createPaymentMethodsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payment_methods (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        last4_digits TEXT,
        bank_name TEXT,
        colour_hex TEXT NOT NULL DEFAULT '#546E7A',
        is_default INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payment_methods_deleted ON payment_methods(is_deleted)',
    );
  }

  /// Close the database (for testing)
  static Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Delete and recreate (for testing)
  static Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
