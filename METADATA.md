# F-Droid Metadata for Fillup App

## App Information

- **App Name**: Fillup
- **Package ID**: com.fillup.fillup
- **Version**: 1.0.0
- **Version Code**: 1
- **Release Date**: 2025-12-26
- **License**: MIT
- **Author**: itsmaxyd
- **Web Site**: https://github.com/itsmaxyd/fuelup
- **Source Code**: https://github.com/itsmaxyd/fuelup
- **Issue Tracker**: https://github.com/itsmaxyd/fuelup/issues
- **Donate**: None
- **Bitcoin**: None

## Description

Fillup is a simple and intuitive fuel tracking app designed to help you monitor your fuel expenses and vehicle efficiency. Whether you're a daily commuter or a road trip enthusiast, Fillup makes it easy to keep track of your fuel spending and optimize your vehicle's performance.

## Categories

- Money
- Office
- Science & Education

## Features

- Track fuel expenses over time
- Calculate and monitor fuel efficiency (km/l)
- Manage multiple vehicles with different fuel types
- View visual reports with beautiful charts
- Auto-fetch current fuel prices by city
- Store all data locally on your device

## Screenshots

None

## Permissions

- **android.permission.INTERNET**: Required for fetching current fuel prices from mypetrolprice.com

## Build Metadata

- **Build Version**: 1.0.0+1
- **Min SDK Version**: 21
- **Target SDK Version**: 33
- **Build Tools Version**: 33.0.0

## Dependencies

All dependencies are open-source and use permissive licenses:

- flutter (BSD-3)
- provider (MIT)
- sqflite (MIT)
- path (MIT)
- http (BSD-3)
- html (MIT)
- fl_chart (MIT)
- cupertino_icons (MIT)
- intl (BSD-3)
- path_provider (MIT)
- csv (MIT)
- share_plus (MIT)

## Compliance

- **F-Droid Compliance**: ✅ Fully Compliant
- **No Tracking**: ✅ No analytics, crash reporting, or telemetry
- **Privacy**: ✅ All data stored locally on device
- **Open Source**: ✅ All source code available under MIT license
- **No Proprietary Dependencies**: ✅ All dependencies are open-source

## Changelog

### Version 1.0.0 (2025-12-26)

- Initial release
- Fuel expense tracking
- Fuel efficiency tracking
- Multiple vehicle support
- Visual reports
- Current fuel prices
- Local storage

## Security

- **Input Validation**: Comprehensive validation for all user inputs
- **Network Security**: HTTPS enforced for all network requests
- **Database Security**: Parameterized queries and input sanitization
- **Error Handling**: Improved error handling and sanitization
- **Security Utilities**: Centralized security functions for consistent protection

## Privacy Policy

Fillup does not collect any personal data or usage information. All data is stored locally on your device and is not transmitted to any external servers except for fetching current fuel prices from mypetrolprice.com.

## Translations

- English (en)

## Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/itsmaxyd/fuelup.git
   cd fuelup
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Build the APK:
   ```bash
   flutter build apk
   ```

## Verification

To verify the build:

1. Check dependencies:
   ```bash
   flutter pub deps --prod
   ```

2. Verify no tracking mechanisms:
   ```bash
   grep -r "analytics\|tracking\|telemetry" lib/
   ```

## Conclusion

The Fillup app is fully compliant with F-Droid's requirements and is ready for submission. All dependencies are open-source, and the app does not contain any tracking mechanisms or proprietary components.