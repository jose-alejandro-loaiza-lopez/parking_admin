import 'package:flutter/material.dart';
import '../database/parking_record_dao.dart';
import '../database/vehicle_type_dao.dart';
import '../models/parking_record.dart';
import '../models/vehicle_type.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _customPriceController = TextEditingController();
  final VehicleTypeDao _typeDao = VehicleTypeDao();
  final ParkingRecordDao _recordDao = ParkingRecordDao();

  List<VehicleType> _types = [];
  VehicleType? _selectedType;
  VehicleType? _bicicleta;
  VehicleType? _moto;
  VehicleType? _carro;
  bool _isCustomType = false;
  bool _isSaving = false;
  bool _isAutoDetecting = false;
  bool _userSelectedType = false;
  String _customPricingType = 'per_hour';

  @override
  void initState() {
    super.initState();
    _loadTypes();
    _plateController.addListener(_onPlateChanged);
  }

  VehicleType? _findTypeByName(String name) {
    for (final t in _types) {
      if (t.name.toLowerCase() == name) return t;
    }
    return null;
  }

  Future<void> _loadTypes() async {
    final types = await _typeDao.getAll();
    setState(() {
      _types = types;
      _bicicleta = _findTypeByName('bicicleta');
      _moto = _findTypeByName('moto');
      _carro = _findTypeByName('carro');
      _selectedType ??= _bicicleta ?? _moto ?? (types.isNotEmpty ? types.first : null);
    });
  }

  void _onPlateChanged() {
    if (_isAutoDetecting || _userSelectedType) return;
    final text = _plateController.text.trim();
    VehicleType? target;

    if (text.isEmpty) {
      target = _bicicleta;
    } else {
      final last = text.toUpperCase().characters.last;
      target = (last.codeUnitAt(0) >= 48 && last.codeUnitAt(0) <= 57) ? _carro : _moto;
    }

    if (target != null && target != _selectedType && !_isCustomType) {
      _isAutoDetecting = true;
      setState(() => _selectedType = target);
      _isAutoDetecting = false;
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _nameController.dispose();
    _cedulaController.dispose();
    _customTypeController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    int? typeId = _selectedType?.id;

    if (_isCustomType) {
      final customType = VehicleType(
        name: _customTypeController.text.trim(),
        pricingType: _customPricingType,
        price: double.tryParse(_customPriceController.text.trim()) ?? 0,
        isCustom: true,
      );
      typeId = await _typeDao.insert(customType);
    }

    if (typeId == null) return;

    final plate = _plateController.text.trim();
    final record = ParkingRecord(
      vehicleTypeId: typeId,
      plate: plate.isEmpty ? null : plate.toUpperCase(),
      personName: _nameController.text.trim(),
      cedula: _cedulaController.text.trim().isEmpty
          ? null
          : _cedulaController.text.trim(),
      checkIn: DateTime.now(),
    );

    await _recordDao.insert(record);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo registrado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar ingreso'), surfaceTintColor: Colors.transparent),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Placa (opcional)',
                hintText: 'ABC123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la persona',
                hintText: 'Nombre completo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Ingrese el nombre' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cedulaController,
              decoration: const InputDecoration(
                labelText: 'Cédula (opcional)',
                hintText: 'Número de documento',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Guardando...' : 'Registrar ingreso'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de vehículo',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (_types.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._types.map(
                (type) => ChoiceChip(
                  label: Text(type.name),
                  selected: _selectedType == type && !_isCustomType,
                  onSelected: (_) => setState(() {
                    _selectedType = type;
                    _isCustomType = false;
                    _userSelectedType = true;
                  }),
                ),
              ),
              ChoiceChip(
                label: const Text('Otro...'),
                selected: _isCustomType,
                onSelected: (_) => setState(() {
                  _selectedType = null;
                  _isCustomType = true;
                  _userSelectedType = true;
                }),
              ),
            ],
          ),
        if (_isCustomType) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _customTypeController,
            decoration: const InputDecoration(
              labelText: 'Nombre del tipo',
              hintText: 'Ej: Bus, Camión',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (!_isCustomType) return null;
              return v == null || v.trim().isEmpty
                  ? 'Ingrese el nombre del tipo'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Tipo de tarifa',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            value: _customPricingType,
            items: const [
              DropdownMenuItem(value: 'per_hour', child: Text('Por hora')),
              DropdownMenuItem(value: 'per_minute', child: Text('Por minuto')),
              DropdownMenuItem(value: 'per_day', child: Text('Por día')),
              DropdownMenuItem(value: 'flat_rate', child: Text('Tarifa única')),
            ],
            onChanged: (v) => setState(() => _customPricingType = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customPriceController,
            decoration: const InputDecoration(
              labelText: 'Precio',
              hintText: '0',
              border: OutlineInputBorder(),
              prefixText: '\$ ',
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (!_isCustomType) return null;
              if (v == null || v.trim().isEmpty) return 'Ingrese el precio';
              if (double.tryParse(v.trim()) == null) return 'Precio inválido';
              return null;
            },
          ),
        ],
      ],
    );
  }
}
