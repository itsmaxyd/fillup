import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import '../providers/vehicle_provider.dart';
import '../providers/fuel_entry_provider.dart';
import '../models/vehicle.dart';
import '../services/fuel_price_service.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportData(BuildContext context) async {
    try {
      final vehicleProvider = context.read<VehicleProvider>();
      final entryProvider = context.read<FuelEntryProvider>();
      
      if (vehicleProvider.selectedVehicle == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No vehicle selected')),
          );
        }
        return;
      }

      final entries = entryProvider.entries;
      
      if (entries.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data to export')),
          );
        }
        return;
      }

      // Prepare CSV data
      final List<List<dynamic>> csvData = [
        ['Date', 'Odometer (km)', 'Fuel (L)', 'Amount (₹)', 'Price/L', 'Efficiency (km/l)'],
      ];

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final previousEntry = i < entries.length - 1 ? entries[i + 1] : null;
        final efficiency = previousEntry != null
            ? entry.calculateEfficiency(previousEntry.odometerReading)
            : null;

        csvData.add([
          entry.date.toIso8601String().split('T')[0],
          entry.odometerReading.toStringAsFixed(0),
          entry.getFuelLiters()?.toStringAsFixed(2) ?? '',
          entry.getFuelRupees()?.toStringAsFixed(2) ?? '',
          entry.pricePerLiter?.toStringAsFixed(2) ?? '',
          efficiency?.toStringAsFixed(2) ?? '',
        ]);
      }

      // Convert to CSV string
      final csvString = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final vehicleName = vehicleProvider.selectedVehicle!.name.replaceAll(' ', '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/fillup_${vehicleName}_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csvString);

      // Share file
      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Fillup Data Export - ${vehicleProvider.selectedVehicle!.name}',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data exported successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  void _showEditVehicleDialog(BuildContext context, Vehicle vehicle) {
    final nameController = TextEditingController(text: vehicle.name);
    String selectedFuelType = vehicle.fuelType;
    String selectedCity = vehicle.city;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Vehicle'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedFuelType,
                    decoration: const InputDecoration(
                      labelText: 'Fuel Type',
                      border: OutlineInputBorder(),
                    ),
                    items: FuelPriceService.getFuelTypes().map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedFuelType = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                    items: FuelPriceService.getMajorCities().map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedCity = value);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final updatedVehicle = vehicle.copyWith(
                name: nameController.text,
                fuelType: selectedFuelType,
                city: selectedCity,
              );
              
              await context.read<VehicleProvider>().updateVehicle(updatedVehicle);
              
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteVehicleDialog(BuildContext context, Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text(
          'Are you sure you want to delete "${vehicle.name}"? This will also delete all associated fuel entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final vehicleProvider = context.read<VehicleProvider>();
              await vehicleProvider.deleteVehicle(vehicle.id!);
              
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle deleted')),
                );
              }

              // If no vehicles left, go back to setup
              if (vehicleProvider.vehicles.isEmpty && context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SetupScreen()),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<VehicleProvider>(
        builder: (context, vehicleProvider, _) {
          return ListView(
            children: [
              // Vehicles Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Vehicles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              ...vehicleProvider.vehicles.map((vehicle) {
                final isSelected = vehicleProvider.selectedVehicle?.id == vehicle.id;
                
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: isSelected 
                      ? Theme.of(context).primaryColor.withOpacity(0.1) 
                      : null,
                  child: ListTile(
                    leading: Icon(
                      Icons.directions_car,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                    title: Text(vehicle.name),
                    subtitle: Text('${vehicle.fuelType} • ${vehicle.city}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (vehicleProvider.vehicles.length > 1)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditVehicleDialog(context, vehicle);
                        } else if (value == 'delete') {
                          _showDeleteVehicleDialog(context, vehicle);
                        }
                      },
                    ),
                    onTap: () {
                      vehicleProvider.selectVehicle(vehicle);
                      context.read<FuelEntryProvider>().loadEntries(vehicle.id!);
                    },
                  ),
                );
              }),

              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SetupScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle'),
                ),
              ),

              const Divider(),

              // Data Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export Data'),
                subtitle: const Text('Export fuel entries to CSV'),
                onTap: () => _exportData(context),
              ),

              const Divider(),

              // About Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Version'),
                subtitle: Text('1.0.0'),
              ),

              const ListTile(
                leading: Icon(Icons.local_gas_station),
                title: Text('Fillup'),
                subtitle: Text('Track your fuel expenses and efficiency'),
              ),
            ],
          );
        },
      ),
    );
  }
}

