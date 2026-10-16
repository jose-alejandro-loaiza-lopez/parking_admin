import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../database/parking_record_dao.dart';
import '../database/vehicle_type_dao.dart';
import '../models/parking_record.dart';
import '../models/vehicle_type.dart';

class CsvService {
  final ParkingRecordDao _recordDao = ParkingRecordDao();
  final VehicleTypeDao _typeDao = VehicleTypeDao();

  Future<String> exportToCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    List<ParkingRecord> records;
    if (startDate != null && endDate != null) {
      records = await _recordDao.getCompletedInRange(startDate, endDate);
    } else {
      records = await _recordDao.getAll();
    }

    final types = await _typeDao.getAll();

    final rows = <List<dynamic>>[
      ['__TIPO__', 'id', 'name', 'pricing_type', 'price', 'is_custom', 'is_default'],
    ];

    for (final type in types) {
      rows.add([
        '__TIPO__',
        type.id.toString(),
        type.name,
        type.pricingType,
        type.price.toString(),
        type.isCustom ? '1' : '0',
        type.isDefault ? '1' : '0',
      ]);
    }

    rows.add([
      '__REG__',
      'vehicle_type_id',
      'plate',
      'person_name',
      'cedula',
      'check_in',
      'check_out',
      'total',
    ]);

    for (final record in records) {
      rows.add([
        '__REG__',
        record.vehicleTypeId.toString(),
        record.plate ?? '',
        record.personName,
        record.cedula ?? '',
        record.checkIn.toIso8601String(),
        record.checkOut?.toIso8601String() ?? '',
        record.totalAmount?.toString() ?? '',
      ]);
    }

    final csvData = csv.encode(rows);
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'parking_backup_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvData);

    return file.path;
  }

  Future<void> shareCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final path = await exportToCsv(startDate: startDate, endDate: endDate);
    await Share.shareXFiles(
      [XFile(path)],
      text: 'Respaldo Parking Admin',
    );
  }

  Future<int> importFromCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result == null || result.files.single.path == null) return 0;

    final file = File(result.files.single.path!);
    final csvData = await file.readAsString();
    final allRows = csv.decode(csvData);

    if (allRows.isEmpty) return 0;

    return _importWithTypes(allRows);
  }

  Future<int> _importWithTypes(List<List<dynamic>> allRows) async {
    final Map<int, int> typeIdMap = {};
    int? regMarkerIndex;

    for (int i = 1; i < allRows.length; i++) {
      final row = allRows[i];
      if (row.isEmpty) continue;
      if (row[0] == '__REG__') {
        regMarkerIndex = i;
        break;
      }
      if (row[0] == '__TIPO__' && row.length >= 7) {
        final oldId = int.tryParse(row[1].toString());
        final name = row[2].toString();
        final pricingType = row[3].toString();
        final price = double.tryParse(row[4].toString()) ?? 0;
        final isCustom = row[5].toString() == '1';
        final isDefault = row[6].toString() == '1';

        if (oldId == null || name.isEmpty) continue;

        final existingTypes = await _typeDao.getAll();
        final existing = existingTypes.cast<VehicleType?>().firstWhere(
          (t) => t!.name.toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );

        int newId;
        if (existing != null) {
          newId = existing.id!;
        } else {
          newId = await _typeDao.insert(VehicleType(
            name: name,
            pricingType: pricingType,
            price: price,
            isCustom: isCustom,
            isDefault: isDefault,
          ));
        }
        typeIdMap[oldId] = newId;
      }
    }

    if (regMarkerIndex == null) return 0;

    final records = <ParkingRecord>[];
    for (int i = regMarkerIndex + 1; i < allRows.length; i++) {
      final row = allRows[i];
      if (row.length < 8) continue;
      if (row[0] != '__REG__') continue;

      try {
        final oldTypeId = int.tryParse(row[1].toString()) ?? 0;
        final mappedId = typeIdMap[oldTypeId] ?? oldTypeId;
        final plate = row[2].toString();

        records.add(ParkingRecord(
          vehicleTypeId: mappedId,
          plate: plate.isEmpty ? null : plate,
          personName: row[3].toString(),
          cedula: row[4].toString().isEmpty ? null : row[4].toString(),
          checkIn: DateTime.parse(row[5].toString()),
          checkOut: row[6].toString().isNotEmpty
              ? DateTime.parse(row[6].toString())
              : null,
          totalAmount: row[7].toString().isNotEmpty
              ? double.tryParse(row[7].toString())
              : null,
          isActive: row[6].toString().isEmpty,
        ));
      } catch (_) {}
    }

    return _insertNewRecords(records);
  }

  Future<int> _insertNewRecords(List<ParkingRecord> records) async {
    final newRecords = <ParkingRecord>[];
    for (final record in records) {
      final exists = await _recordDao.existsDuplicate(
        record.plate,
        record.checkIn,
        record.checkOut,
      );
      if (!exists) {
        newRecords.add(record);
      }
    }

    if (newRecords.isNotEmpty) {
      await _recordDao.insertBatch(newRecords);
    }

    return newRecords.length;
  }
}
