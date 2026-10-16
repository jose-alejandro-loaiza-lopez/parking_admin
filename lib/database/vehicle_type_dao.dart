import '../models/vehicle_type.dart';
import 'database_helper.dart';

class VehicleTypeDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<VehicleType>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('vehicle_types', orderBy: 'name ASC');
    return maps.map((map) => VehicleType.fromMap(map)).toList();
  }

  Future<VehicleType?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'vehicle_types',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return VehicleType.fromMap(maps.first);
  }

  Future<int> insert(VehicleType type) async {
    final db = await _dbHelper.database;
    return await db.insert('vehicle_types', type.toMap());
  }

  Future<int> update(VehicleType type) async {
    final db = await _dbHelper.database;
    return await db.update(
      'vehicle_types',
      type.toMap(),
      where: 'id = ?',
      whereArgs: [type.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'vehicle_types',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
