# Setup Guide for Fillup

## Prerequisites

1. **Flutter SDK** (3.0.0 or higher)
   - Install from: https://docs.flutter.dev/get-started/install

2. **Android Studio** (for Android development)
   - Install from: https://developer.android.com/studio
   - Install Flutter and Dart plugins

3. **Xcode** (for iOS development - macOS only)
   - Install from Mac App Store

## API Key Configuration

The app uses OpenAI's GPT-4o-mini Vision API for odometer scanning. You need to provide your own API key:

### Option 1: Using Config File (Recommended)

1. Copy the example config file:
```bash
cp lib/config/api_config.dart.example lib/config/api_config.dart
```

2. Get your OpenAI API key:
   - Go to https://platform.openai.com/api-keys
   - Create a new API key
   - Copy the key

3. Edit `lib/config/api_config.dart`:
```dart
class ApiConfig {
  static const String openAiApiKey = 'sk-proj-YOUR-ACTUAL-KEY-HERE';
}
```

### Option 2: Direct Edit

Edit `lib/services/encryption_service.dart` and replace:
```dart
static const String _hardcodedApiKey = 'YOUR_OPENAI_API_KEY_HERE';
```

with your actual API key.

### Security Note

The API key is encrypted using device-specific identifiers before being stored locally. However, for production apps, consider using:
- Environment variables
- Backend API proxy
- Secure key management services

## Running the App

### Android

```bash
flutter run
```

### iOS (macOS only)

```bash
flutter run -d ios
```

### Build APK (Android)

```bash
flutter build apk --release
```

The APK will be available at: `build/app/outputs/flutter-apk/app-release.apk`

### Build App Bundle (Android - for Play Store)

```bash
flutter build appbundle --release
```

## Troubleshooting

### Flutter not found
- Make sure Flutter is added to your PATH
- Run `flutter doctor` to check your installation

### Dependencies issues
```bash
flutter clean
flutter pub get
```

### Android build issues
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

### Permission issues on Android
- Camera permission is needed for odometer scanning
- Storage permissions for data export

## Features Overview

- **Fuel Entry**: Manual entry or scan odometer with camera
- **Multiple Vehicles**: Track multiple vehicles with different fuel types
- **Reports**: Visual charts for expenses and efficiency
- **Fuel Prices**: Auto-fetch current prices from mypetrolprice.com
- **Data Export**: Export your data to CSV
- **Offline First**: All data stored locally on device

## Support

For issues and questions, please visit: https://github.com/itsmaxyd/fuelup/issues

