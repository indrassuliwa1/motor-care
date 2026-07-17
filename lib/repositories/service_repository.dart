import '../models/service.dart';
import '../database/db_helper.dart';

class ServiceRepository {
  final DBHelper _dbHelper = DBHelper();

  // Tambah Jadwal/Riwayat Service Baru
  Future<int> insertService(ServiceModel service) async {
    final db = await _dbHelper.database;
    return await db.insert('service', service.toMap());
  }

  // Ambil Semua Data Service
  Future<List<ServiceModel>> getServices() async {
    final db = await _dbHelper.database;
    // Kita urutkan berdasarkan tanggal terdekat secara default
    final List<Map<String, dynamic>> maps = await db.query('service', orderBy: 'tanggalService ASC');
    return List.generate(maps.length, (i) => ServiceModel.fromMap(maps[i]));
  }

  // Ambil Data Service khusus untuk satu Motor tertentu
  Future<List<ServiceModel>> getServicesByMotorId(int motorId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'service',
      where: 'motorId = ?',
      whereArgs: [motorId],
      orderBy: 'tanggalService ASC',
    );
    return List.generate(maps.length, (i) => ServiceModel.fromMap(maps[i]));
  }

  // Update Data Service (termasuk update status Done/Overdue)
  Future<int> updateService(ServiceModel service) async {
    final db = await _dbHelper.database;
    return await db.update(
      'service',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  // Hapus Data Service
  Future<int> deleteService(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'service',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}