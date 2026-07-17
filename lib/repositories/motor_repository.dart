import '../models/motor.dart';
import '../database/db_helper.dart';

class MotorRepository {
  final DBHelper _dbHelper = DBHelper();

  // Tambah Motor Baru
  Future<int> insertMotor(Motor motor) async {
    final db = await _dbHelper.database;
    return await db.insert('motor', motor.toMap());
  }

  // Ambil Semua Data Motor
  Future<List<Motor>> getMotors() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('motor');
    return List.generate(maps.length, (i) => Motor.fromMap(maps[i]));
  }

  // Ambil Data Motor berdasarkan ID
  Future<Motor?> getMotorById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'motor',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Motor.fromMap(maps.first);
    }
    return null;
  }

  // Update Data Motor
  Future<int> updateMotor(Motor motor) async {
    final db = await _dbHelper.database;
    return await db.update(
      'motor',
      motor.toMap(),
      where: 'id = ?',
      whereArgs: [motor.id],
    );
  }

  // Hapus Data Motor
  Future<int> deleteMotor(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'motor',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}