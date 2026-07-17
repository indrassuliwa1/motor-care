import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _database;

  Future get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future _initDB() async {
    String path = join(await getDatabasesPath(), 'motor_care.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
    );
  }

  // Mengaktifkan fitur Foreign Key di SQLite
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    // Tabel Motor
    await db.execute('''
      CREATE TABLE motor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merk TEXT,
        namaMotor TEXT,
        tipeMotor TEXT,
        tahun INTEGER,
        nomorPolisi TEXT,
        kilometerSaatIni INTEGER,
        tanggalPembelian TEXT,
        fotoMotor TEXT
      )
    ''');

    // Tabel Service
    await db.execute('''
      CREATE TABLE service (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        motorId INTEGER,
        jenisService TEXT,
        tanggalService TEXT,
        kilometerService INTEGER,
        catatan TEXT,
        status TEXT,
        FOREIGN KEY (motorId) REFERENCES motor (id) ON DELETE CASCADE
      )
    ''');

    // Tabel Notification
    await db.execute('''
      CREATE TABLE notification (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serviceId INTEGER,
        title TEXT,
        body TEXT,
        scheduledTime TEXT,
        isRead INTEGER,
        createdAt TEXT,
        FOREIGN KEY (serviceId) REFERENCES service (id) ON DELETE CASCADE
      )
    ''');
  }
}