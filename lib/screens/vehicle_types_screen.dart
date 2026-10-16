import 'package:flutter/material.dart';
import '../database/vehicle_type_dao.dart';
import '../models/vehicle_type.dart';
import '../utils/helpers.dart';

class VehicleTypesScreen extends StatefulWidget {
  const VehicleTypesScreen({super.key});

  @override
  State<VehicleTypesScreen> createState() => _VehicleTypesScreenState();
}

class _VehicleTypesScreenState extends State<VehicleTypesScreen> {
  final VehicleTypeDao _dao = VehicleTypeDao();
  List<VehicleType> _types = [];

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  Future<void> _loadTypes() async {
    final types = await _dao.getAll();
    setState(() => _types = types);
  }

  Future<void> _addType() async {
    final result = await showDialog<VehicleType>(
      context: context,
      builder: (_) => const _VehicleTypeDialog(),
    );
    if (result != null) {
      await _dao.insert(result);
      _loadTypes();
    }
  }

  Future<void> _editType(VehicleType type) async {
    final result = await showDialog<VehicleType>(
      context: context,
      builder: (_) => _VehicleTypeDialog(type: type),
    );
    if (result != null) {
      await _dao.update(result);
      _loadTypes();
    }
  }

  Future<void> _deleteType(VehicleType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar tipo'),
        content: Text('¿Eliminar "${type.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _dao.delete(type.id!);
      _loadTypes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tipos de vehículo'), surfaceTintColor: Colors.transparent),
      floatingActionButton: FloatingActionButton(
        onPressed: _addType,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _types.length,
        itemBuilder: (context, index) {
          final type = _types[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  type.name.substring(0, 1).toUpperCase(),
                ),
              ),
              title: Text(type.name),
              subtitle: Text(
                '${type.pricingLabel}: ${formatCurrency(type.price)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type.isDefault)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Chip(
                        label: Text('Predefinido',
                            style: TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _editType(type),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteType(type),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VehicleTypeDialog extends StatefulWidget {
  final VehicleType? type;

  const _VehicleTypeDialog({this.type});

  @override
  State<_VehicleTypeDialog> createState() => _VehicleTypeDialogState();
}

class _VehicleTypeDialogState extends State<_VehicleTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late String _pricingType;

  bool get isEditing => widget.type != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.type?.name ?? '');
    _priceController =
        TextEditingController(text: widget.type?.price.toString() ?? '');
    _pricingType = widget.type?.pricingType ?? 'per_hour';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Editar tipo' : 'Agregar tipo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _pricingType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de tarifa',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'per_hour', child: Text('Por hora')),
                  DropdownMenuItem(
                      value: 'per_minute', child: Text('Por minuto')),
                  DropdownMenuItem(
                      value: 'per_day', child: Text('Por día')),
                  DropdownMenuItem(
                      value: 'flat_rate', child: Text('Tarifa única')),
                ],
                onChanged: (v) => setState(() => _pricingType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio (\$)',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null || double.parse(v) < 0) {
                    return 'Ingrese un valor válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final type = VehicleType(
              id: widget.type?.id,
              name: _nameController.text.trim(),
              pricingType: _pricingType,
              price: double.parse(_priceController.text.trim()),
              isCustom: widget.type?.isCustom ?? !isEditing,
              isDefault: widget.type?.isDefault ?? false,
            );
            Navigator.pop(context, type);
          },
          child: Text(isEditing ? 'Guardar' : 'Agregar'),
        ),
      ],
    );
  }
}
