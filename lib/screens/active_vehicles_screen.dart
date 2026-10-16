import 'dart:async';
import 'package:flutter/material.dart';
import '../database/parking_record_dao.dart';
import '../database/vehicle_type_dao.dart';
import '../models/parking_record.dart';
import '../utils/helpers.dart';
import 'check_in_screen.dart';
import 'check_out_screen.dart';

class ActiveVehiclesScreen extends StatefulWidget {
  final bool showFab;

  const ActiveVehiclesScreen({super.key, this.showFab = true});

  @override
  State<ActiveVehiclesScreen> createState() => ActiveVehiclesScreenState();
}

class ActiveVehiclesScreenState extends State<ActiveVehiclesScreen> {
  final ParkingRecordDao _recordDao = ParkingRecordDao();
  final VehicleTypeDao _typeDao = VehicleTypeDao();

  List<ParkingRecord> _records = [];
  Map<int, String> _typeNames = {};
  int _activeCount = 0;
  double _todayIncome = 0;
  int _todayCompleted = 0;
  bool _isLoading = true;
  Timer? _timer;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusManager.instance.primaryFocus?.unfocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void refresh() => _loadData();

  Future<void> _loadData() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final records = await _recordDao.getActive();
    final types = await _typeDao.getAll();
    final typeNames = {for (final t in types) t.id!: t.name};
    final activeCount = await _recordDao.getActiveCount();
    final todayIncome = await _recordDao.getIncomeInRange(startOfDay, endOfDay);
    final todayCompleted =
        await _recordDao.getCompletedCountInRange(startOfDay, endOfDay);

    setState(() {
      _records = records;
      _typeNames = typeNames;
      _activeCount = activeCount;
      _todayIncome = todayIncome;
      _todayCompleted = todayCompleted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Admin'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: 4 + (_filteredRecords.isEmpty ? 1 : _filteredRecords.length),
            itemBuilder: (context, index) {
              if (index == 0) return _buildStatsRow();
              if (index == 1) return const SizedBox(height: 8);
              if (index == 2) return _buildSearchBar();
              if (index == 3) return const SizedBox(height: 4);
              final recordIndex = index - 4;
              if (_filteredRecords.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.directions_car, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay vehículos estacionados',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final record = _filteredRecords[recordIndex];
              return _ActiveVehicleCard(
                record: record,
                typeName: _typeNames[record.vehicleTypeId] ?? 'N/A',
                onTap: () => _openCheckOut(context, record),
              );
            },
          ),
        ),
      ),
      floatingActionButton: widget.showFab
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCheckIn(context),
              icon: const Icon(Icons.add),
              label: const Text('Registrar ingreso'),
            )
          : null,
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.directions_car,
              label: 'Activos',
              value: '$_activeCount',
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle,
              label: 'Completados hoy',
              value: '$_todayCompleted',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.attach_money,
              label: 'Ingreso hoy',
              value: formatCurrency(_todayIncome),
              color: Colors.orange,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Future<void> _navigateToCheckIn(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckInScreen()),
    );
    _loadData();
  }

  Future<void> _openCheckOut(BuildContext context, ParkingRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CheckOutScreen(record: record)),
    );
    _loadData();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ActiveVehicleCard extends StatelessWidget {
  final ParkingRecord record;
  final String typeName;
  final VoidCallback onTap;

  const _ActiveVehicleCard({
    required this.record,
    required this.typeName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final duration = record.duration;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          record.plate ?? 'Sin placa',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.personName),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('$typeName · '),
                Text(
                  formatDuration(duration),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue,
                  ),
                ),
                const Icon(Icons.timer, size: 14, color: Colors.blue),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
