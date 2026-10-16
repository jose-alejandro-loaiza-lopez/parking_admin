import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/csv_service.dart';
import '../database/parking_record_dao.dart';
import '../utils/helpers.dart';
import 'vehicle_types_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<ThemeMode>? onThemeChanged;

  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getString('themeMode') == 'dark';
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
    widget.onThemeChanged?.call(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), surfaceTintColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Tipos de vehículo',
            icon: Icons.directions_car,
            description: 'Administrar tarifas y tipos de vehículos',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const VehicleTypesScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildThemeToggle(),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Exportar respaldo CSV',
            icon: Icons.file_upload,
            description: 'Exportar historial a archivo CSV',
            onTap: () => _exportCsv(),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Importar respaldo CSV',
            icon: Icons.file_download,
            description: 'Restaurar datos desde archivo CSV',
            onTap: () => _importCsv(),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Borrar todos los registros',
            icon: Icons.delete_sweep,
            description: 'Eliminar todo el historial de parqueadero',
            onTap: () => _clearAllData(),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Parking Admin v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Aplicación local para administración de parqueadero',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(_themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode)),
        title: const Text('Tema'),
        trailing: SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
            ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
          ],
          selected: {_themeMode},
          onSelectionChanged: (v) => _setThemeMode(v.first),
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final result = await showDialog<_ExportResult>(
      context: context,
      builder: (_) => const _ExportDialog(),
    );
    if (result == null) return;

    final csvService = CsvService();
    try {
      await csvService.shareCsv(startDate: result.start, endDate: result.end);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo exportado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al exportar: $e')),
        );
      }
    }
  }

  Future<void> _importCsv() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importar respaldo'),
        content: const Text(
          'Esto agregará los registros del archivo CSV al historial existente. ¿Desea continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Seleccionar archivo'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final csvService = CsvService();
    try {
      final count = await csvService.importFromCsv();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count registros importados')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar: $e')),
        );
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ClearDatabasePage(),
      ),
    );
    if (confirmed != true) return;

    final dao = ParkingRecordDao();
    try {
      await dao.clearAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todos los registros han sido eliminados')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al borrar: $e')),
        );
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _ExportResult {
  final DateTime? start;
  final DateTime? end;
  _ExportResult({this.start, this.end});
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog();

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  bool _isCustomRange = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: DateTime(2020),
      lastDate: _endDate!,
      helpText: 'Fecha inicial',
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate!,
      firstDate: _startDate!,
      lastDate: DateTime.now(),
      helpText: 'Fecha final',
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar respaldo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<String>(
            title: const Text('Rango personalizado'),
            value: 'custom',
            groupValue: _isCustomRange ? 'custom' : 'all',
            onChanged: (_) => setState(() => _isCustomRange = true),
          ),
          if (_isCustomRange) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: _pickStart,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_calendar, size: 20),
                    const SizedBox(width: 8),
                    Text('Desde: ${formatDateShort(_startDate!)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickEnd,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_calendar, size: 20),
                    const SizedBox(width: 8),
                    Text('Hasta: ${formatDateShort(_endDate!)}'),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: const Text('Todo el historial'),
            value: 'all',
            groupValue: _isCustomRange ? 'custom' : 'all',
            onChanged: (_) => setState(() => _isCustomRange = false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (_isCustomRange) {
              Navigator.pop(context, _ExportResult(
                start: _startDate,
                end: _endDate!.add(const Duration(days: 1)).subtract(const Duration(seconds: 1)),
              ));
            } else {
              Navigator.pop(context, _ExportResult());
            }
          },
          child: const Text('Exportar'),
        ),
      ],
    );
  }
}

class _ClearDatabasePage extends StatefulWidget {
  const _ClearDatabasePage();

  @override
  State<_ClearDatabasePage> createState() => _ClearDatabasePageState();
}

class _ClearDatabasePageState extends State<_ClearDatabasePage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrar todos los registros'), surfaceTintColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('¿Está seguro de eliminar todo el historial? Esta acción no se puede deshacer.'),
            const SizedBox(height: 16),
            const Text('Escriba "confirmar" para continuar:'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'confirmar',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final ok = _controller.text.trim().toLowerCase() == 'confirmar';
                  Navigator.pop(context, ok);
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Borrar todo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
