import 'dart:async';
import 'package:anjanitek/modals/notifications.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static late Database _db;

  DatabaseHelper._internal();

  Future<Database> get db async {
    // if (_db != null) {
    //   return _db;
    // }
    _db = await initDb();
    return _db;
  }

  Future<Database> initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'anjanitek_database.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE notifications(notificationId INTEGER PRIMARY KEY AUTOINCREMENT, sender TEXT, receiver TEXT, sentAt TEXT, message TEXT, seen INTEGER)');
  }

  Future<int> insertNotification(Notifications notification) async {
    Database dbClient = await db;
    return await dbClient.insert('notifications', notification.toJson());
  }

  Future<List<Notifications>> getNotifications() async {
    final dbClient = await db;
    final List<Map<String, dynamic>> maps = await dbClient.query(
      'notifications',
      orderBy: 'sentAt DESC', // Sort by sentAt in descending order
    );

    return List.generate(maps.length, (i) {
      return Notifications(
        notificationId: maps[i]['notificationId'],
        sender: maps[i]['sender'],
        receiver: maps[i]['receiver'],
        sentAt: maps[i]['sentAt'],
        message: maps[i]['message'],
        seen: maps[i]['seen'],
      );
    });
  }

  Future<void> deleteAllNotifications() async {
    Database dbClient = await db;
    await dbClient.delete('notifications');
  }

  // Future<List<Notifications>> getAllNotifications() async {
  //   Database dbClient = await db;
  //   List<Map<String, dynamic>> result = await dbClient.query('notifications');
  //   return result.map((json) => Notifications.fromJson(json)).toList();
  // }

  // Future<int> insert(Map<String, dynamic> row) async {
  //   Database dbClient = await db;
  //   return await dbClient.insert('my_table', row);
  // }

  // Future<List<Map<String, dynamic>>> queryAll() async {
  //   Database dbClient = await db;
  //   return await dbClient.query('my_table');
  // }
}
