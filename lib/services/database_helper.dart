import 'package:airon_chef/widgets/pantry_item.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import '../pages/shopping_list.dart';
import '../pages/shopping_ingredient.dart';
import '../widgets/pantry_item.dart';
import 'dart:convert';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = "airon_chef.db";
  static const _dbVersion = 2;
  static const _tablePantry = "pantry";

  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        // fresh install
        await db.execute(_createPantryTableSql);
        await db.execute(_createShoppingListsTableSql); 
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // only version 1 → 2 currently; drop & recreate
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS $_tablePantry');
          await db.execute('DROP TABLE IF EXISTS $_tableShoppingLists');
          await db.execute(_createPantryTableSql);
          await db.execute(_createShoppingListsTableSql);
        }
      },
    );
    return _db!;
  }

  static const String _createPantryTableSql = '''
    CREATE TABLE $_tablePantry (
      id           INTEGER PRIMARY KEY AUTOINCREMENT,
      name         TEXT    NOT NULL UNIQUE,
      quantity     INTEGER NOT NULL DEFAULT 1,
      category     TEXT    NOT NULL,
      expiry_date  TEXT,
      updated_at   INTEGER NOT NULL
    )
  ''';

  static const _tableShoppingLists = "shopping_lists";

  static const String _createShoppingListsTableSql = '''
    CREATE TABLE $_tableShoppingLists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL UNIQUE,
      ingredients TEXT NOT NULL  -- store JSON string of ingredients
    )
  ''';

  /// 1. Fetch the 5 most‐recently updated pantry names
  Future<List<PantryItem>> getRecentPantryItems({int limit = 5}) async {
    final db = await database;
    final path = await getDatabasesPath();
    debugPrint('💾  DB path: $path/airon_chef.db');
    final rows = await db.query(
      _tablePantry,
      distinct: true,
      orderBy: 'updated_at DESC',
      limit: limit,
    );
    return rows.map((r) => PantryItem.fromMap(r)).toList();
  }

  /// 2. Fetch all pantry names (e.g. for matching suggestions)
  Future<List<PantryItem>> getAllPantryItems() async {
    final db = await database;
    final rows = await db.query(
      _tablePantry,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map((r) => PantryItem.fromMap(r)).toList();
  }

  /// 3. Insert a new pantry item (or update an existing one’s timestamp)
  Future<int> addPantryItem({
    required String name,
    int quantity = 1,
    required String category,
    String? expiryDate,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Using REPLACE so that if name already exists, it updates timestamp/fields
    return db.insert(_tablePantry, {
      'name': name,
      'quantity': quantity,
      'category': category,
      'expiry_date': expiryDate,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Insert PantryItem (safe version, ignore isSelected)
  Future<int> insertPantryItem(PantryItem item) async {
    final db = await database;
    return await db.insert(
      'pantry',
      {
        'name': item.name,
        'quantity': item.quantity,
        'category': item.category,
        'expiry_date': item.expiryDate?.toIso8601String(),
        'updated_at': item.updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all ingredients from pantry
  Future<List<PantryItem>> getAllIngredients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tablePantry);

    return List.generate(maps.length, (i) {
      return PantryItem.fromMap(maps[i]);  // 🛠 only this!
    });
  }

  // Delete an ingredient by name
  Future<int> deleteIngredient(String name) async {
    final db = await database;
    return await db.delete(
      'pantry',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  // Insert or update ShoppingList
  Future<int> insertShoppingList(ShoppingList list) async {
    final db = await database;
    return await db.insert(
      _tableShoppingLists,
      {
        'title': list.title,
        'ingredients': json.encode(list.ingredients.map((e) => e.toJson()).toList()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  // Get all shopping lists
  Future<List<ShoppingList>> getAllShoppingLists() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableShoppingLists);

    return List.generate(maps.length, (i) {
      return ShoppingList(
        id: maps[i]['id'] as int?, // <-- add this!
        title: maps[i]['title'] as String,
        ingredients: (json.decode(maps[i]['ingredients']) as List)
            .map((e) => ShoppingIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    });
  }


  // Delete shopping list by title
  Future<int> deleteShoppingList(String title) async {
    final db = await database;
    return await db.delete(
      _tableShoppingLists,
      where: 'title = ?',
      whereArgs: [title],
    );
  }

}