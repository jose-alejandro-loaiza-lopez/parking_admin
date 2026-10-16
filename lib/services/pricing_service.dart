import '../models/parking_record.dart';
import '../models/vehicle_type.dart';

class PricingService {
  double calculateAmount(ParkingRecord record, VehicleType type) {
    final duration = record.duration;

    switch (type.pricingType) {
      case 'per_hour':
        final hours = duration.inMinutes / 60.0;
        final billableHours = hours.ceil();
        return billableHours * type.price;

      case 'per_minute':
        final minutes = duration.inMinutes;
        return minutes * type.price;

      case 'per_day':
        final days = duration.inHours / 24.0;
        final billableDays = days.ceil();
        return billableDays * type.price;

      case 'flat_rate':
        return type.price;

      default:
        return 0;
    }
  }
}
