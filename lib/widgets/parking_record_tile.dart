import 'package:flutter/material.dart';
import '../models/parking_record.dart';
import '../utils/helpers.dart';

class ParkingRecordTile extends StatelessWidget {
  final ParkingRecord record;
  final String typeName;
  final VoidCallback? onTap;

  const ParkingRecordTile({
    super.key,
    required this.record,
    required this.typeName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(typeName.substring(0, 1).toUpperCase()),
        ),
        title: Text(record.plate ?? 'Sin placa'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.personName),
            Text(
              '$typeName · ${formatDate(record.checkIn)}${record.checkOut != null ? ' → ${formatDate(record.checkOut!)}' : ' (activo)'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: record.totalAmount != null
            ? Text(
                formatCurrency(record.totalAmount!),
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
