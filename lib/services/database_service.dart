import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('accounting.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER DEFAULT (strftime('%s', 'now')),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');
  }

  // SHA-256 加密
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // 用户注册
  Future<int> registerUser(String username, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);

    try {
      final id = await db.insert(
        'users',
        {
          'username': username,
          'password': hashedPassword,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return id;
    } catch (e) {
      throw Exception('用户名已存在');
    }
  }

  // 用户登录
  Future<Map<String, dynamic>?> loginUser(String username, String password) async {
    final db = await instance.database;
    final hashedPassword = _hashPassword(password);

    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, hashedPassword],
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // 添加交易记录
  Future<int> addTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;
    return await db.insert('transactions', transaction);
  }

  // 获取交易记录
  Future<List<Map<String, dynamic>>> getTransactions(int userId, {
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;

    String query = 'SELECT * FROM transactions WHERE user_id = ?';
    List<dynamic> args = [userId];

    if (type != null) {
      query += ' AND type = ?';
      args.add(type);
    }

    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate.millisecondsSinceEpoch ~/ 1000);
    }

    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate.millisecondsSinceEpoch ~/ 1000);
    }

    query += ' ORDER BY date DESC, created_at DESC';

    return await db.rawQuery(query, args);
  }

  // 获取统计数据
  Future<List<Map<String, dynamic>>> getStatistics(int userId, {
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;

    String query = '''
      SELECT category, SUM(amount) as total, COUNT(*) as count
      FROM transactions
      WHERE user_id = ?
    ''';
    List<dynamic> args = [userId];

    if (type != null) {
      query += ' AND type = ?';
      args.add(type);
    }

    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate.millisecondsSinceEpoch ~/ 1000);
    }

    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate.millisecondsSinceEpoch ~/ 1000);
    }

    query += ' GROUP BY category ORDER BY total DESC';

    return await db.rawQuery(query, args);
  }

  // 获取总金额
  Future<List<Map<String, dynamic>>> getTotal(int userId, {
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await instance.database;

    String query = 'SELECT type, SUM(amount) as total FROM transactions WHERE user_id = ?';
    List<dynamic> args = [userId];

    if (type != null) {
      query += ' AND type = ?';
      args.add(type);
    }

    if (startDate != null) {
      query += ' AND date >= ?';
      args.add(startDate.millisecondsSinceEpoch ~/ 1000);
    }

    if (endDate != null) {
      query += ' AND date <= ?';
      args.add(endDate.millisecondsSinceEpoch ~/ 1000);
    }

    query += ' GROUP BY type';

    return await db.rawQuery(query, args);
  }

  // 更新交易记录
  Future<int> updateTransaction(int id, Map<String, dynamic> transaction) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      transaction,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除交易记录
  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 关闭数据库
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}