import '../models/parking_record.dart';
import 'database_helper.dart';

class ParkingRecordDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ParkingRecord>> getActive() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'parking_records',
      where: 'is_active = 1',
      orderBy: 'check_in DESC',
    );
    return maps.map((map) => ParkingRecord.fromMap(map)).toList();
  }

  Future<List<ParkingRecord>> getAll({String? orderBy}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'parking_records',
      orderBy: orderBy ?? 'check_in DESC',
    );
    return maps.map((map) => ParkingRecord.fromMap(map)).toList();
  }

  Future<List<ParkingRecord>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'parking_records',
      where: 'check_in >= ? AND check_in <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'check_in DESC',
    );
    return maps.map((map) => ParkingRecord.fromMap(map)).toList();
  }

  Future<List<ParkingRecord>> getCompletedInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'parking_records',
      where:
          'is_active = 0 AND check_out >= ? AND check_out <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'check_out DESC',
    );
    return maps.map((map) => ParkingRecord.fromMap(map)).toList();
  }

  Future<ParkingRecord?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'parking_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ParkingRecord.fromMap(maps.first);
  }

  Future<int> insert(ParkingRecord record) async {
    final db = await _dbHelper.database;
    return await db.insert('parking_records', record.toMap());
  }

  Future<int> update(ParkingRecord record) async {
    final db = await _dbHelper.database;
    return await db.update(
      'parking_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<double> getIncomeInRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM parking_records '
      'WHERE is_active = 0 AND check_out >= ? AND check_out <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<int> getActiveCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM parking_records WHERE is_active = 1',
    );
    return result.first['count'] as int;
  }

  Future<int> getCompletedCountInRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM parking_records '
      'WHERE is_active = 0 AND check_out >= ? AND check_out <= ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    return result.first['count'] as int;
  }

  Future<List<Map<String, dynamic>>> getIncomeByTypeInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _dbHelper.database;
    return await db.rawQuery(
      'SELECT vt.name, COUNT(pr.id) as count, COALESCE(SUM(pr.total_amount), 0) as total '
      'FROM parking_records pr '
      'JOIN vehicle_types vt ON pr.vehicle_type_id = vt.id '
      'WHERE pr.is_active = 0 AND pr.check_out >= ? AND pr.check_out <= ? '
      'GROUP BY vt.name',
      [start.toIso8601String(), end.toIso8601String()],
    );
  }

  Future<bool> existsDuplicate(String? plate, DateTime checkIn, DateTime? checkOut) async {
    final db = await _dbHelper.database;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (plate != null) {
      conditions.add('plate = ?');
      args.add(plate);
    } else {
      conditions.add('plate IS NULL');
    }

    conditions.add('check_in = ?');
    args.add(checkIn.toIso8601String());

    if (checkOut != null) {
      conditions.add('check_out = ?');
      args.add(checkOut.toIso8601String());
    } else {
      conditions.add('check_out IS NULL');
    }

    final result = await db.query(
      'parking_records',
      where: conditions.join(' AND '),
      whereArgs: args,
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<void> clearAll() async {
    final db = await _dbHelper.database;
    await db.rawDelete('DELETE FROM parking_records');
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('parking_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertBatch(List<ParkingRecord> records) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (final record in records) {
      batch.insert('parking_records', record.toMap());
    }
    await batch.commit(noResult: true);
  }
}
