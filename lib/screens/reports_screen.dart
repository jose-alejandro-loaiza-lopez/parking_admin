import 'package:flutter/material.dart';
import '../database/parking_record_dao.dart';
import '../utils/helpers.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  final ParkingRecordDao _recordDao = ParkingRecordDao();
  bool _isLoading = false;

  double _totalIncome = 0;
  int _totalCompleted = 0;
  List<Map<String, dynamic>> _incomeByType = [];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _setCurrentMonth();
  }

  void _setCurrentMonth() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
    _loadReport();
  }

  void refresh() => _loadReport();

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);

    final income = await _recordDao.getIncomeInRange(_startDate!, _endDate!);
    final count =
        await _recordDao.getCompletedCountInRange(_startDate!, _endDate!);
    final byType =
        await _recordDao.getIncomeByTypeInRange(_startDate!, _endDate!);

    setState(() {
      _totalIncome = income;
      _totalCompleted = count;
      _incomeByType = byType;
      _isLoading = false;
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    if (!context.mounted) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: DateTime(2020),
      lastDate: _endDate ?? now,
      helpText: 'Fecha inicial',
    );
    if (picked == null) return;
    setState(() {
      _startDate = DateTime(picked.year, picked.month, picked.day);
    });
    if (_endDate != null && _startDate!.isAfter(_endDate!)) {
      _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    }
    _loadReport();
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    if (!context.mounted) return;
    final endInitial = _endDate ?? now;
    final safeInitial = endInitial.isAfter(now) ? now : endInitial;
    final picked = await showDatePicker(
      context: context,
      initialDate: safeInitial,
      firstDate: _startDate!,
      lastDate: now,
      helpText: 'Fecha final',
    );
    if (picked == null) return;
    setState(() {
      _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
    });
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _setCurrentMonth,
            tooltip: 'Mes actual',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
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
                                            'Desde: ${formatDateShort(_startDate!)}',
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
                                            'Hasta: ${formatDateShort(_endDate!)}',
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
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.attach_money,
                                  size: 32, color: Colors.green),
                              const SizedBox(height: 8),
                              Text(
                                formatCurrency(_totalIncome),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text('Ingresos totales'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 32, color: Colors.blue),
                              const SizedBox(height: 8),
                              Text(
                                '$_totalCompleted',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const Text('Vehículos atendidos'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_incomeByType.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ingresos por tipo de vehículo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._incomeByType.map((item) => ListTile(
                                dense: true,
                                title: Text(item['name'] as String),
                                subtitle:
                                    Text('${item['count']} vehículos'),
                                trailing: Text(
                                  formatCurrency(
                                      (item['total'] as num).toDouble()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
