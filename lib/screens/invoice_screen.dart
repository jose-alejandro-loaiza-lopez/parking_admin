import 'package:flutter/material.dart';
import '../models/parking_record.dart';
import '../utils/helpers.dart';

class InvoiceScreen extends StatelessWidget {
  final ParkingRecord record;
  final String typeName;

  const InvoiceScreen({
    super.key,
    required this.record,
    required this.typeName,
  });

  @override
  Widget build(BuildContext context) {
    final duration = record.duration;

    return Scaffold(
      appBar: AppBar(surfaceTintColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Factura',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Parking Admin',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const Divider(height: 32),
          Text(typeName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _row('Vehículo', record.plate ?? 'Sin placa'),
          _row('Conductor', record.personName),
          if (record.cedula != null) _row('Cédula', record.cedula!),
          _row('Ingreso', formatDate(record.checkIn)),
          if (record.checkOut != null) _row('Salida', formatDate(record.checkOut!)),
          _row('Tiempo', formatDuration(duration)),
          if (record.checkOut != null) ...[
            const Divider(height: 24),
            if (record.totalAmount != null)
              _row('Total', formatCurrency(record.totalAmount!),
                  valueStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: valueStyle ?? const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
