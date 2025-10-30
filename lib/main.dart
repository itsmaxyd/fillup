import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/vehicle_provider.dart';
import 'providers/fuel_entry_provider.dart';
import 'services/database_service.dart';
import 'services/encryption_service.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize encryption service and API key
  await EncryptionService.instance.initializeApiKey();
  
  runApp(const FillupApp());
}

class FillupApp extends StatelessWidget {
  const FillupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VehicleProvider()),
        ChangeNotifierProvider(create: (_) => FuelEntryProvider()),
      ],
      child: MaterialApp(
        title: 'Fillup',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize database
      final db = DatabaseService.instance;
      await db.database;
      
      // Load vehicles
      final vehicleProvider = context.read<VehicleProvider>();
      await vehicleProvider.initialize();
      
      // Small delay for splash screen
      await Future.delayed(const Duration(seconds: 1));
      
      // Check if we have vehicles
      final hasVehicles = await db.hasVehicles();
      
      if (mounted) {
        if (hasVehicles) {
          // Go to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          // Go to setup screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SetupScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Show error and go to setup
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization error: $e')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_gas_station,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Fillup',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your fuel expenses',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

