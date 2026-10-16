class ParkingRecord {
  final int? id;
  final int vehicleTypeId;
  final String? plate;
  final String personName;
  final String? cedula;
  final DateTime checkIn;
  final DateTime? checkOut;
  final double? totalAmount;
  final bool isActive;

  ParkingRecord({
    this.id,
    required this.vehicleTypeId,
    this.plate,
    required this.personName,
    this.cedula,
    required this.checkIn,
    this.checkOut,
    this.totalAmount,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'vehicle_type_id': vehicleTypeId,
        'plate': plate,
        'person_name': personName,
        'cedula': cedula,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut?.toIso8601String(),
        'total_amount': totalAmount,
        'is_active': isActive ? 1 : 0,
      };

  factory ParkingRecord.fromMap(Map<String, dynamic> map) => ParkingRecord(
        id: map['id'] as int?,
        vehicleTypeId: map['vehicle_type_id'] as int,
        plate: map['plate'] as String?,
        personName: map['person_name'] as String,
        cedula: map['cedula'] as String?,
        checkIn: DateTime.parse(map['check_in'] as String),
        checkOut: map['check_out'] != null
            ? DateTime.parse(map['check_out'] as String)
            : null,
        totalAmount: map['total_amount'] != null
            ? (map['total_amount'] as num).toDouble()
            : null,
        isActive: (map['is_active'] as int) == 1,
      );

  Duration get duration {
    final end = checkOut ?? DateTime.now();
    return end.difference(checkIn);
  }

  ParkingRecord copyWith({
    int? id,
    int? vehicleTypeId,
    String? plate,
    String? personName,
    String? cedula,
    DateTime? checkIn,
    DateTime? checkOut,
    double? totalAmount,
    bool? isActive,
  }) =>
      ParkingRecord(
        id: id ?? this.id,
        vehicleTypeId: vehicleTypeId ?? this.vehicleTypeId,
        plate: plate ?? this.plate,
        personName: personName ?? this.personName,
        cedula: cedula ?? this.cedula,
        checkIn: checkIn ?? this.checkIn,
        checkOut: checkOut ?? this.checkOut,
        totalAmount: totalAmount ?? this.totalAmount,
        isActive: isActive ?? this.isActive,
      );
}
