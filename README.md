# Fillup - Fuel Tracking App

A minimalistic and simple fuel tracking app for Android (expandable to iOS) that helps you monitor fuel expenses and vehicle efficiency.

## Features

- 📊 **Track Fuel Expenses**: Monitor your fuel spending over time
- ⛽ **Fuel Efficiency Tracking**: Calculate and track km/l efficiency
- 🚗 **Multiple Vehicles**: Manage multiple vehicles with different fuel types
- 📈 **Visual Reports**: Beautiful charts showing expenses and efficiency trends
- 💰 **Current Fuel Prices**: Auto-fetch current fuel prices by city
- 💾 **Local Storage**: All data stored locally on your device

## Tech Stack

- **Framework**: Flutter (Dart)
- **Database**: SQLite (sqflite)
- **State Management**: Provider
- **Charts**: fl_chart
- **Web Scraping**: HTML parser for fuel prices

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK for Android development
- Xcode for iOS development (macOS only)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/itsmaxyd/fuelup.git
cd fuelup
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Usage

### Initial Setup
1. Enter your vehicle name
2. Select fuel type (Petrol/Diesel/CNG)
3. Choose your city
4. Enter current odometer reading

### Adding Fuel Entries
- **Manual Entry**: Enter fuel amount in rupees or liters

### View Reports
- Monthly expense charts
- Fuel efficiency trends
- Summary statistics

## Project Structure

```
lib/
├── main.dart
├── models/
│   ├── vehicle.dart
│   ├── fuel_entry.dart
│   └── fuel_price.dart
├── services/
│   ├── database_service.dart
│   └── fuel_price_service.dart
├── providers/
│   ├── vehicle_provider.dart
│   └── fuel_entry_provider.dart
├── screens/
│   ├── setup_screen.dart
│   ├── home_screen.dart
│   ├── manual_entry_screen.dart
│   ├── reports_screen.dart
│   └── settings_screen.dart
└── utils/
    └── security_utils.dart
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Author

[itsmaxyd](https://github.com/itsmaxyd)
