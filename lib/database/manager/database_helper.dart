import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:notes_taking_app/database/db_helper.dart';

class DatabaseHelper {
  // Field:
  final String tableName;

  // Constructor:
  DatabaseHelper(this.tableName);

  // Private Constructor to create instance:
  static final Map<String, DatabaseHelper> _instances = {};

  // To check whether the tableName exists in the _instances (Prevent data from being stored in the same table):
  static DatabaseHelper getInstance(String tableName) {
    if (!_instances.containsKey(tableName)) {
      _instances[tableName] = DatabaseHelper(tableName);
    }

    return _instances[tableName]!;
  }

  // No need for a static _database variable here, we'll fetch it dynamically
  // Initializer the instance of database:
  Future<Database> get database async {
    return await DBHelper.getDatabase();
  }

  //****************** Insert ********************//
  // Insert data:
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await database; // No need for nullable type here
    return await db.insert(tableName, row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  //****************** Query ********************//
  // Get all the data from the table:
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await database;
    return await db.query(tableName);
  }

  // Get the number of rows from the table:
  Future<int?> queryRowCount() async {
    Database db = await database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tableName'));
  }

  // Get last row from the table:
  Future<Map<String, dynamic>?> getLastRow() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableName,
      orderBy: 'id DESC',
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // Get the last id from the table:
  Future<int?> getLastRowId() async {
    Database db = await database;
    List<Map<String, dynamic>> result =
        await db.rawQuery('SELECT MAX(id) as lastId FROM $tableName');
    if (result.isNotEmpty) {
      return result.first['lastId'] as int?;
    }
    return null;
  }

  // Get the row by id:
  Future<Map<String, dynamic>?> getRowById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null; // Or handle the case when the row is not found
    }
  }

  //****************** Update ********************//
  // Update:
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await database;
    int id = row['id'];
    return await db.update(tableName, row, where: 'id = ?', whereArgs: [id]);
  }

  //****************** Delete ********************//
  // Delete:
  Future<int> delete(int id) async {
    Database db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
