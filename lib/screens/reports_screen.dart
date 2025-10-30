import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/vehicle_provider.dart';
import '../providers/fuel_entry_provider.dart';
import '../models/fuel_entry.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month'; // month, 3months, 6months, year, all
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() => _selectedPeriod = value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'month', child: Text('Last Month')),
              PopupMenuItem(value: '3months', child: Text('Last 3 Months')),
              PopupMenuItem(value: '6months', child: Text('Last 6 Months')),
              PopupMenuItem(value: 'year', child: Text('Last Year')),
              PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: Consumer2<VehicleProvider, FuelEntryProvider>(
        builder: (context, vehicleProvider, entryProvider, _) {
          final selectedVehicle = vehicleProvider.selectedVehicle;
          
          if (selectedVehicle == null) {
            return const Center(child: Text('No vehicle selected'));
          }

          final allEntries = entryProvider.entries;
          
          if (allEntries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No data available yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add fuel entries to see reports',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Filter entries based on selected period
          final filteredEntries = _filterEntriesByPeriod(allEntries, _selectedPeriod);

          if (filteredEntries.isEmpty) {
            return Center(
              child: Text(
                'No data for selected period',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummaryCards(filteredEntries),
                
                const SizedBox(height: 24),
                
                // Expense Chart
                Text(
                  'Monthly Expenses',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _ExpenseChart(entries: filteredEntries),
                
                const SizedBox(height: 32),
                
                // Efficiency Chart
                Text(
                  'Fuel Efficiency Trend',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _EfficiencyChart(entries: filteredEntries),
                
                const SizedBox(height: 32),
                
                // Detailed Statistics
                Text(
                  'Detailed Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildDetailedStats(filteredEntries),
              ],
            ),
          );
        },
      ),
    );
  }

  List<FuelEntry> _filterEntriesByPeriod(List<FuelEntry> entries, String period) {
    final now = DateTime.now();
    DateTime cutoffDate;

    switch (period) {
      case 'month':
        cutoffDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3months':
        cutoffDate = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6months':
        cutoffDate = DateTime(now.year, now.month - 6, now.day);
        break;
      case 'year':
        cutoffDate = DateTime(now.year - 1, now.month, now.day);
        break;
      case 'all':
      default:
        return entries;
    }

    return entries.where((entry) => entry.date.isAfter(cutoffDate)).toList();
  }

  Widget _buildSummaryCards(List<FuelEntry> entries) {
    final totalSpent = entries.fold<double>(
      0.0,
      (sum, entry) => sum + (entry.getFuelRupees() ?? 0),
    );

    final totalLiters = entries.fold<double>(
      0.0,
      (sum, entry) => sum + (entry.getFuelLiters() ?? 0),
    );

    final efficiencies = <double>[];
    for (var i = 0; i < entries.length - 1; i++) {
      final current = entries[i];
      final previous = entries[i + 1];
      final eff = current.calculateEfficiency(previous.odometerReading);
      if (eff != null && eff > 0) {
        efficiencies.add(eff);
      }
    }

    final avgEfficiency = efficiencies.isNotEmpty
        ? efficiencies.reduce((a, b) => a + b) / efficiencies.length
        : 0.0;

    final totalDistance = entries.length > 1
        ? entries.first.odometerReading - entries.last.odometerReading
        : 0.0;

    final costPerKm = totalDistance > 0 ? totalSpent / totalDistance : 0.0;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Spent',
            value: '₹${totalSpent.toStringAsFixed(0)}',
            icon: Icons.currency_rupee,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Avg Efficiency',
            value: avgEfficiency > 0 ? '${avgEfficiency.toStringAsFixed(1)} km/l' : 'N/A',
            icon: Icons.speed,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(List<FuelEntry> entries) {
    final totalSpent = entries.fold<double>(
      0.0,
      (sum, entry) => sum + (entry.getFuelRupees() ?? 0),
    );

    final totalLiters = entries.fold<double>(
      0.0,
      (sum, entry) => sum + (entry.getFuelLiters() ?? 0),
    );

    final totalDistance = entries.length > 1
        ? entries.first.odometerReading - entries.last.odometerReading
        : 0.0;

    final costPerKm = totalDistance > 0 ? totalSpent / totalDistance : 0.0;
    final avgPricePerLiter = totalLiters > 0 ? totalSpent / totalLiters : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatRow('Total Entries', '${entries.length}'),
            const Divider(),
            _StatRow('Total Spent', '₹${totalSpent.toStringAsFixed(2)}'),
            const Divider(),
            _StatRow('Total Fuel', '${totalLiters.toStringAsFixed(2)} L'),
            const Divider(),
            _StatRow('Total Distance', '${totalDistance.toStringAsFixed(0)} km'),
            const Divider(),
            _StatRow('Cost per km', '₹${costPerKm.toStringAsFixed(2)}'),
            const Divider(),
            _StatRow('Avg Price/Liter', '₹${avgPricePerLiter.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseChart extends StatelessWidget {
  final List<FuelEntry> entries;

  const _ExpenseChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    // Group entries by month
    final monthlyExpenses = <String, double>{};
    
    for (final entry in entries) {
      final monthKey = DateFormat('MMM yy').format(entry.date);
      final expense = entry.getFuelRupees() ?? 0;
      monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + expense;
    }

    if (monthlyExpenses.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No expense data')),
      );
    }

    final sortedMonths = monthlyExpenses.keys.toList();
    final maxExpense = monthlyExpenses.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxExpense * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '₹${rod.toY.toStringAsFixed(0)}',
                      const TextStyle(color: Colors.white),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= sortedMonths.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          sortedMonths[value.toInt()],
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${(value / 1000).toStringAsFixed(0)}k',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                sortedMonths.length,
                (index) => BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: monthlyExpenses[sortedMonths[index]]!,
                      color: Theme.of(context).primaryColor,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EfficiencyChart extends StatelessWidget {
  final List<FuelEntry> entries;

  const _EfficiencyChart({required this.entries});

  @override
  Widget build(BuildContext context) {
    final efficiencyData = <FlSpot>[];
    
    for (var i = entries.length - 1; i > 0; i--) {
      final current = entries[i - 1];
      final previous = entries[i];
      final efficiency = current.calculateEfficiency(previous.odometerReading);
      
      if (efficiency != null && efficiency > 0) {
        efficiencyData.add(FlSpot(
          (entries.length - i).toDouble(),
          efficiency,
        ));
      }
    }

    if (efficiencyData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('Need at least 2 entries for efficiency data')),
      );
    }

    final maxEfficiency = efficiencyData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final minEfficiency = efficiencyData.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    return SizedBox(
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              minY: minEfficiency * 0.8,
              maxY: maxEfficiency * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: efficiencyData,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.green.withOpacity(0.1),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '#${value.toInt()}',
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toStringAsFixed(0)} km/l',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

