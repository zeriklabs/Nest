import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/note.dart';
import '../models/notebook.dart';
import '../models/reminder.dart';
import '../models/notification.dart';
import '../models/group.dart';
import '../models/project.dart';
import '../models/focus_session.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static bool _isDisabled = false;
  static bool _isInitializing = false;
  static bool get isDisabled => _isDisabled;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_isDisabled) throw Exception('Database is disabled');
    if (_database != null) return _database!;
    
    if (_isInitializing) {
      // Esperar a que la inicialización en curso termine o falle
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_isDisabled) throw Exception('Database is disabled');
      if (_database != null) return _database!;
    }

    _isInitializing = true;
    try {
      // En la Web, a veces el primer intento falla con "unsupported result null" 
      // si el worker no está listo. Intentamos un reintento suave.
      try {
        _database = await _initDatabase().timeout(const Duration(seconds: 5));
      } catch (e) {
        if (kIsWeb) {
          debugPrint('DatabaseService: Reintentando inicialización en Web...');
          await Future.delayed(const Duration(milliseconds: 500));
          _database = await _initDatabase().timeout(const Duration(seconds: 5));
        } else {
          rethrow;
        }
      }
      _isInitializing = false;
      return _database!;
    } catch (e) {
      debugPrint('DatabaseService: Error crítico de inicialización: $e');
      _isDisabled = true;
      _isInitializing = false;
      throw Exception('Database disabled');
    }
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      // En la web, si no están los binarios, esto lanzará excepción
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'nest_database.db';
    } else {
      path = join(await getDatabasesPath(), 'nest_database.db');
    }

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS contacts(
          id TEXT PRIMARY KEY,
          data TEXT
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE subjects(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE notebooks(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reminders(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE notifications(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE groups(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE projects(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE focus_sessions(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE contacts(
        id TEXT PRIMARY KEY,
        data TEXT
      )
    ''');
  }

  // Generic methods to save and load data as JSON blobs for flexibility
  Future<void> saveEntity(String table, String id, Map<String, dynamic> data) async {
    if (_isDisabled) return;
    try {
      final db = await database;
      await db.insert(
        table,
        {'id': id, 'data': jsonEncode(data)},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> deleteEntity(String table, String id) async {
    if (_isDisabled) return;
    try {
      final db = await database;
      await db.delete(table, where: 'id = ?', whereArgs: [id]);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getAllEntities(String table) async {
    if (_isDisabled) return [];
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(table);
      return maps.map((item) {
        final Map<String, dynamic> data = jsonDecode(item['data'] as String) as Map<String, dynamic>;
        if (!data.containsKey('id')) {
          data['id'] = item['id'];
        }
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearTable(String table) async {
    if (_isDisabled) return;
    try {
      final db = await database;
      await db.delete(table);
    } catch (_) {}
  }

  Future<void> clearAllUserData() async {
    if (_isDisabled) return;
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete('subjects');
        await txn.delete('notes');
        await txn.delete('notebooks');
        await txn.delete('reminders');
        await txn.delete('notifications');
        await txn.delete('groups');
        await txn.delete('projects');
        await txn.delete('focus_sessions');
        await txn.delete('settings', where: 'key IN (?, ?, ?)', whereArgs: ['userName', 'profileCompleted', 'userBirthday']);
      });
    } catch (_) {}
  }

  // Settings
  Future<void> saveSetting(String key, String value) async {
    if (_isDisabled) return;
    try {
      final db = await database;
      await db.insert(
        'settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<String?> getSetting(String key) async {
    if (_isDisabled) return null;
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
      );
      if (maps.isNotEmpty) {
        return maps.first['value'] as String;
      }
    } catch (_) {}
    return null;
  }
}
