# Fillup - Fuel Tracking App

A minimalistic and simple fuel tracking app for Android (expandable to iOS) that helps you monitor fuel expenses and vehicle efficiency.

## Features

- 📊 **Track Fuel Expenses**: Monitor your fuel spending over time
- ⛽ **Fuel Efficiency Tracking**: Calculate and track km/l efficiency
- 🚗 **Multiple Vehicles**: Manage multiple vehicles with different fuel types
- 📸 **Odometer Scanning**: Scan odometer readings using AI-powered OCR
- 📈 **Visual Reports**: Beautiful charts showing expenses and efficiency trends
- 💰 **Current Fuel Prices**: Auto-fetch current fuel prices by city
- 💾 **Local Storage**: All data stored locally on your device

## Tech Stack

- **Framework**: Flutter (Dart)
- **Database**: SQLite (sqflite)
- **State Management**: Provider
- **Charts**: fl_chart
- **OCR**: OpenAI GPT-4o-mini Vision API
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

3. **Configure OpenAI API Key** (Required for odometer scanning):
   - Copy `lib/config/api_config.dart.example` to `lib/config/api_config.dart`
   - Get your API key from [OpenAI Platform](https://platform.openai.com/api-keys)
   - Replace `YOUR_OPENAI_API_KEY_HERE` with your actual API key
   
   Alternatively, you can directly edit `lib/services/encryption_service.dart` and replace the `_hardcodedApiKey` constant with your key.

4. Run the app:
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
- **Scan Odometer**: Capture odometer image for AI-powered reading

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
│   ├── api_service.dart
│   ├── fuel_price_service.dart
│   └── encryption_service.dart
├── providers/
│   ├── vehicle_provider.dart
│   └── fuel_entry_provider.dart
├── screens/
│   ├── setup_screen.dart
│   ├── home_screen.dart
│   ├── manual_entry_screen.dart
│   ├── scan_odometer_screen.dart
│   ├── reports_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── vehicle_card.dart
    ├── fuel_entry_card.dart
    └── chart_widgets.dart
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Author

[itsmaxyd](https://github.com/itsmaxyd)

