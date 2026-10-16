class AppConstants {
  static const String dbName = 'parking_admin.db';
  static const int dbVersion = 2;

  static const List<Map<String, dynamic>> defaultVehicleTypes = [
    {
      'name': 'Bicicleta',
      'pricing_type': 'flat_rate',
      'price': 2000.0,
    },
    {
      'name': 'Moto',
      'pricing_type': 'per_hour',
      'price': 3000.0,
    },
    {
      'name': 'Carro',
      'pricing_type': 'per_hour',
      'price': 5000.0,
    },
  ];

  static const String currencySymbol = '\$';
  static const String appName = 'Parking Admin';
}
