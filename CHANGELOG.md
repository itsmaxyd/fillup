# Changelog for Fillup App

## Version 1.0.0 (2025-12-26)

### New Features
- **Fuel Expense Tracking**: Monitor fuel spending over time with detailed logs
- **Fuel Efficiency Tracking**: Calculate and track km/l efficiency for your vehicles
- **Multiple Vehicle Support**: Manage multiple vehicles with different fuel types
- **Visual Reports**: Beautiful charts showing expenses and efficiency trends
- **Current Fuel Prices**: Auto-fetch current fuel prices by city
- **Local Storage**: All data stored locally on your device

### Security Improvements
- **Input Validation**: Comprehensive validation for all user inputs
- **Network Security**: HTTPS enforced for all network requests
- **Database Security**: Parameterized queries and input sanitization
- **Error Handling**: Improved error handling and sanitization
- **Security Utilities**: Centralized security functions for consistent protection

### Optimizations
- **Performance**: Optimized database queries and network requests
- **Code Quality**: Improved code structure and maintainability
- **User Experience**: Enhanced input validation and error messages

### Removed Features
- **OCR Odometer Scanning**: Removed proprietary OpenAI GPT-4o-mini Vision API integration
- **OpenAI API Configuration**: Removed API key configuration files

### Bug Fixes
- Fixed input validation issues in setup screen
- Improved error handling in fuel price service
- Enhanced database error handling

### Dependencies
- Updated all dependencies to latest stable versions
- Verified all dependencies are FOSS-compatible

### Compliance
- **F-Droid Compliance**: Removed all proprietary dependencies
- **No Tracking**: No analytics, crash reporting, or telemetry
- **Privacy**: All data stored locally on device

### Licensing
- **Project License**: MIT License
- **Dependencies**: All dependencies use permissive open-source licenses (MIT, BSD-3)

### Known Issues
- None

### Future Enhancements
- SQLite database encryption
- Certificate pinning for API endpoints
- Rate limiting for form submissions
- Input validation for manual entry screen
- Proper data backup with encryption