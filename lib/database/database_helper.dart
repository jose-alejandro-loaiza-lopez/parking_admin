import 'package:sqflite/sqflite.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/${AppConstants.dbName}';

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicle_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pricing_type TEXT NOT NULL,
        price REAL NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE parking_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_type_id INTEGER NOT NULL,
        plate TEXT,
        person_name TEXT NOT NULL,
        cedula TEXT,
        check_in TEXT NOT NULL,
        check_out TEXT,
        total_amount REAL,
        is_active INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_types(id)
      )
    ''');

    for (final type in AppConstants.defaultVehicleTypes) {
      await db.insert('vehicle_types', {
        'name': type['name'],
        'pricing_type': type['pricing_type'],
        'price': type['price'],
        'is_custom': 0,
        'is_default': 1,
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE parking_records RENAME TO parking_records_old');
      await db.execute('''
        CREATE TABLE parking_records (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          vehicle_type_id INTEGER NOT NULL,
          plate TEXT,
          person_name TEXT NOT NULL,
          cedula TEXT,
          check_in TEXT NOT NULL,
          check_out TEXT,
          total_amount REAL,
          is_active INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_types(id)
        )
      ''');
      await db.execute('''
        INSERT INTO parking_records (id, vehicle_type_id, plate, person_name, cedula, check_in, check_out, total_amount, is_active)
        SELECT id, vehicle_type_id, plate, person_name, cedula, check_in, check_out, total_amount, is_active FROM parking_records_old
      ''');
      await db.execute('DROP TABLE parking_records_old');
    }
  }
}
