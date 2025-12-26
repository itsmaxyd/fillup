import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/vehicle_provider.dart';
import '../providers/fuel_entry_provider.dart';
import '../models/fuel_entry.dart';
import 'manual_entry_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vehicleProvider = context.read<VehicleProvider>();
    final entryProvider = context.read<FuelEntryProvider>();
    
    await vehicleProvider.loadVehicles();
    
    if (vehicleProvider.selectedVehicle != null) {
      await entryProvider.loadEntries(vehicleProvider.selectedVehicle!.id!);
    }
  }

  void _showAddEntryOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Manual Entry'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManualEntryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddEntryOptions,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fillup'),
        actions: [
          Consumer<VehicleProvider>(
            builder: (context, vehicleProvider, _) {
              if (vehicleProvider.vehicles.isEmpty) {
                return const SizedBox.shrink();
              }

              return PopupMenuButton<int>(
                icon: const Icon(Icons.directions_car),
                tooltip: 'Select Vehicle',
                onSelected: (vehicleId) {
                  final vehicle = vehicleProvider.vehicles
                      .firstWhere((v) => v.id == vehicleId);
                  vehicleProvider.selectVehicle(vehicle);
                  
                  // Reload entries for selected vehicle
                  context.read<FuelEntryProvider>().loadEntries(vehicleId);
                },
                itemBuilder: (context) {
                  return vehicleProvider.vehicles.map((vehicle) {
                    final isSelected = vehicleProvider.selectedVehicle?.id == vehicle.id;
                    return PopupMenuItem<int>(
                      value: vehicle.id,
                      child: Row(
                        children: [
                          if (isSelected) 
                            const Icon(Icons.check, size: 20)
                          else 
                            const SizedBox(width: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              vehicle.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList();
                },
              );
            },
          ),
        ],
      ),
      body: Consumer2<VehicleProvider, FuelEntryProvider>(
        builder: (context, vehicleProvider, entryProvider, _) {
          final selectedVehicle = vehicleProvider.selectedVehicle;
          
          if (selectedVehicle == null) {
            return const Center(
              child: Text('No vehicle selected'),
            );
          }

          if (entryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = entryProvider.entries;

          return RefreshIndicator(
            onRefresh: () => entryProvider.refresh(),
            child: Column(
              children: [
                // Vehicle Info Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedVehicle.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.local_gas_station,
                              label: selectedVehicle.fuelType,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _InfoChip(
                              icon: Icons.location_city,
                              label: selectedVehicle.city,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Quick Stats
                if (entries.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Spent',
                            value: '₹${entryProvider.getTotalSpending().toStringAsFixed(0)}',
                            icon: Icons.currency_rupee,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Avg Efficiency',
                            value: entryProvider.getAverageEfficiency() != null
                                ? '${entryProvider.getAverageEfficiency()!.toStringAsFixed(1)} km/l'
                                : 'N/A',
                            icon: Icons.speed,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Recent Entries Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        'Recent Fillups',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${entries.length} entries',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Fuel Entries List
                Expanded(
                  child: entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.local_gas_station_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No fuel entries yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap + to add your first fillup',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final previousEntry = index < entries.length - 1
                                ? entries[index + 1]
                                : null;
                             
                            return _FuelEntryCard(
                              entry: entry,
                              previousEntry: previousEntry,
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Entry'),
                                    content: const Text(
                                      'Are you sure you want to delete this fuel entry?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true && context.mounted) {
                                  await entryProvider.deleteEntry(entry.id!);
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _FuelEntryCard extends StatelessWidget {
  final FuelEntry entry;
  final FuelEntry? previousEntry;
  final VoidCallback onDelete;

  const _FuelEntryCard({
    required this.entry,
    this.previousEntry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final efficiency = previousEntry != null
        ? entry.calculateEfficiency(previousEntry!.odometerReading)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            dateFormat.format(entry.date).split(' ')[0],
          ),
        ),
        title: Row(
          children: [
            Text('₹${entry.getFuelRupees()?.toStringAsFixed(0) ?? 'N/A'}'),
            const SizedBox(width: 8),
            Text(
              '• ${entry.getFuelLiters()?.toStringAsFixed(2) ?? 'N/A'} L',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Odometer: ${entry.odometerReading.toStringAsFixed(0)} km'),
            if (efficiency != null)
              Text(
                'Efficiency: ${efficiency.toStringAsFixed(1)} km/l',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onDelete,
        ),
      ),
    );
  }
}