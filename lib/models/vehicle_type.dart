class VehicleType {
  final int? id;
  final String name;
  final String pricingType; // per_hour, per_minute, per_day, flat_rate
  final double price;
  final bool isCustom;
  final bool isDefault;

  VehicleType({
    this.id,
    required this.name,
    required this.pricingType,
    required this.price,
    this.isCustom = false,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'pricing_type': pricingType,
        'price': price,
        'is_custom': isCustom ? 1 : 0,
        'is_default': isDefault ? 1 : 0,
      };

  factory VehicleType.fromMap(Map<String, dynamic> map) => VehicleType(
        id: map['id'] as int?,
        name: map['name'] as String,
        pricingType: map['pricing_type'] as String,
        price: (map['price'] as num).toDouble(),
        isCustom: (map['is_custom'] as int) == 1,
        isDefault: (map['is_default'] as int) == 1,
      );

  String get pricingLabel {
    switch (pricingType) {
      case 'per_hour':
        return 'Por hora';
      case 'per_minute':
        return 'Por minuto';
      case 'per_day':
        return 'Por día';
      case 'flat_rate':
        return 'Tarifa única';
      default:
        return pricingType;
    }
  }

  VehicleType copyWith({
    int? id,
    String? name,
    String? pricingType,
    double? price,
    bool? isCustom,
    bool? isDefault,
  }) =>
      VehicleType(
        id: id ?? this.id,
        name: name ?? this.name,
        pricingType: pricingType ?? this.pricingType,
        price: price ?? this.price,
        isCustom: isCustom ?? this.isCustom,
        isDefault: isDefault ?? this.isDefault,
      );
}
