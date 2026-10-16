import 'package:flutter/material.dart';
import '../database/parking_record_dao.dart';
import '../database/vehicle_type_dao.dart';
import '../models/parking_record.dart';
import '../utils/helpers.dart';
import 'invoice_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  final ParkingRecordDao _recordDao = ParkingRecordDao();
  final VehicleTypeDao _typeDao = VehicleTypeDao();

  List<ParkingRecord> _records = [];
  Map<int, String> _typeNames = {};
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _setToday() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _loadData();
  }

  void refresh() => _loadData();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final types = await _typeDao.getAll();
    final typeNames = {for (final t in types) t.id!: t.name};

    final records = await _recordDao.getByDateRange(_startDate, _endDate);

    setState(() {
      _records = records;
      _typeNames = typeNames;
      _isLoading = false;
    });
  }

  Future<void> _pickStartDate() async {
    if (!context.mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      helpText: 'Fecha inicial',
    );
    if (picked == null) return;
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
    });
    if (_startDate.isAfter(_endDate)) {
      _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    }
    _loadData();
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    if (!context.mounted) return;
    final initial = _endDate.isAfter(now) ? now : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _startDate,
      lastDate: now,
      helpText: 'Fecha final',
    );
    if (picked == null) return;
    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    });
    _loadData();
  }

  Future<void> _deleteRecord(ParkingRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Eliminar el registro de ${record.personName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _recordDao.delete(record.id!);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _setToday,
            tooltip: 'Hoy',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4 + (_filteredRecords.isEmpty ? 1 : _filteredRecords.length + 2),
              itemBuilder: (context, index) {
                if (index == 0) return _buildFilterRow();
                if (index == 1) return const SizedBox(height: 12);
                if (index == 2) return _buildSearchBar();
                if (index == 3) return const SizedBox(height: 8);
                if (_filteredRecords.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Center(
                      child: Text(
                        'No hay registros',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ),
                  );
                }
                if (index == 4) {
                  return Text(
                    '${_filteredRecords.length} registro(s)',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                if (index == 5) return const SizedBox(height: 4);
                final record = _filteredRecords[index - 6];
                final typeName = _typeNames[record.vehicleTypeId] ?? 'N/A';
                return Dismissible(
                  key: ValueKey(record.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) async {
                    await _deleteRecord(record);
                    return false;
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(typeName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(record.personName),
                          if (record.plate != null) Text(record.plate!, style: Theme.of(context).textTheme.bodySmall),
                          Text(
                            '${formatDate(record.checkIn)}${record.checkOut != null ? ' → ${formatDate(record.checkOut!)}' : ' (activo)'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      trailing: Text(formatDuration(record.duration)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InvoiceScreen(record: record, typeName: typeName),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  List<ParkingRecord> get _filteredRecords {
    if (_searchQuery.isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      return (r.plate?.toLowerCase().contains(q) ?? false) ||
          r.personName.toLowerCase().contains(q) ||
          (r.cedula?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Buscar por placa, nombre o cédula...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: _pickStartDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_calendar, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Desde: ${formatDateShort(_startDate)}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickEndDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.outline),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit_calendar, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Hasta: ${formatDateShort(_endDate)}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
