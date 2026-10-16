import 'package:flutter/material.dart';
import '../database/parking_record_dao.dart';
import '../database/vehicle_type_dao.dart';
import '../models/parking_record.dart';
import '../models/vehicle_type.dart';
import '../services/pricing_service.dart';
import '../utils/helpers.dart';

class CheckOutScreen extends StatefulWidget {
  final ParkingRecord record;

  const CheckOutScreen({super.key, required this.record});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  final ParkingRecordDao _recordDao = ParkingRecordDao();
  final VehicleTypeDao _typeDao = VehicleTypeDao();
  final PricingService _pricingService = PricingService();

  VehicleType? _vehicleType;
  double _totalAmount = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadType();
  }

  Future<void> _loadType() async {
    final type = await _typeDao.getById(widget.record.vehicleTypeId);
    if (type != null) {
      final amount = _pricingService.calculateAmount(widget.record, type);
      setState(() {
        _vehicleType = type;
        _totalAmount = amount;
      });
    }
  }

  Future<void> _processCheckOut() async {
    setState(() => _isProcessing = true);

    final updatedRecord = widget.record.copyWith(
      checkOut: DateTime.now(),
      totalAmount: _totalAmount,
      isActive: false,
    );

    await _recordDao.update(updatedRecord);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehículo retirado. Total: ${formatCurrency(_totalAmount)}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.record.duration;

    return Scaffold(
      appBar: AppBar(title: const Text('Procesar salida'), surfaceTintColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Placa', widget.record.plate ?? 'Sin placa'),
                  const Divider(),
                  _buildInfoRow('Persona', widget.record.personName),
                  if (widget.record.cedula != null) ...[
                    const Divider(),
                    _buildInfoRow('Cédula', widget.record.cedula!),
                  ],
                  const Divider(),
                  _buildInfoRow('Tipo', _vehicleType?.name ?? 'Cargando...'),
                  const Divider(),
                  _buildInfoRow(
                    'Ingreso',
                    formatDate(widget.record.checkIn),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Tiempo transcurrido',
                    formatDuration(duration),
                  ),
                  if (_vehicleType != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      'Tarifa aplicada',
                      '${_vehicleType!.pricingLabel}: ${formatCurrency(_vehicleType!.price)}',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Total a pagar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formatCurrency(_totalAmount),
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _isProcessing ? null : _processCheckOut,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: Text(_isProcessing ? 'Procesando...' : 'Confirmar salida y cobrar'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
