import 'package:flutter/material.dart';
import '../models/vehicle_type.dart';
import '../utils/helpers.dart';

class VehicleTypeCard extends StatelessWidget {
  final VehicleType type;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const VehicleTypeCard({
    super.key,
    required this.type,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(type.name.substring(0, 1).toUpperCase()),
        ),
        title: Text(type.name),
        subtitle: Text('${type.pricingLabel}: ${formatCurrency(type.price)}'),
        trailing: type.isDefault
            ? const Chip(label: Text('Predefinido'))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
      ),
    );
  }
}
