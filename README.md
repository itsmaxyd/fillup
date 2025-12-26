# Fillup - Fuel Tracking App

![Fillup Logo](https://img.shields.io/badge/Fillup-Fuel%20Tracker-blue?style=for-the-badge&logo=flutter)

A simple and intuitive fuel tracking app designed to help you monitor your fuel expenses and vehicle efficiency. Whether you're a daily commuter or a road trip enthusiast, Fillup makes it easy to keep track of your fuel spending and optimize your vehicle's performance.

## ✨ Key Features

### 📊 Fuel Expense Tracking
- Log every fuel purchase with ease
- Track your spending over time
- Monitor fuel costs for multiple vehicles

### ⛽ Fuel Efficiency Tracking
- Calculate your vehicle's km/l efficiency
- Track efficiency trends over time
- Identify patterns and optimize your driving habits

### 🚗 Multiple Vehicle Support
- Manage multiple vehicles in one app
- Support for different fuel types (Petrol, Diesel, CNG)
- Customize vehicle details and preferences

### 📈 Visual Reports
- Beautiful charts showing your fuel expenses
- Efficiency trends over time
- Summary statistics for quick insights

### 💰 Current Fuel Prices
- Auto-fetch current fuel prices by city
- Stay updated with the latest fuel rates
- Plan your fuel purchases smartly

### 💾 Local Storage
- All data stored locally on your device
- No cloud storage or online accounts required
- Your data stays private and secure

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or later)
- Android Studio or VS Code with Flutter extensions
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/fillup.git
   cd fillup
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Usage

1. **Setup**: Add your vehicle details and current odometer reading
2. **Log Fuel Purchases**: Enter fuel amount and cost after each fill-up
3. **View Reports**: Check your spending and efficiency trends
4. **Optimize**: Use insights to improve your fuel efficiency

## 🛡️ Privacy and Security

- **No Tracking**: Fillup does not collect any personal data or usage information
- **Local Storage**: All your data is stored locally on your device
- **Open Source**: The app is fully open-source and transparent
- **Secure Networking**: HTTPS enforced for all network requests

## 🏗️ Architecture

Fillup is built with Flutter and follows clean architecture principles:

- **State Management**: Provider pattern for reactive UI updates
- **Database**: SQLite with sqflite for local data persistence
- **Networking**: HTTP client for fuel price fetching
- **Charts**: FL Chart for beautiful data visualization

## 📦 Dependencies

All dependencies are open-source and use permissive licenses:

- `provider`: State management
- `sqflite`: SQLite database
- `http`: Networking
- `fl_chart`: Data visualization
- `intl`: Internationalization
- `path_provider`: File system access
- `csv`: Data export
- `share_plus`: Data sharing

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

Fillup is licensed under the MIT License. See [LICENSE](LICENSE) for more information.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Open source community for the wonderful packages
- F-Droid for promoting free software on mobile

## 📞 Support

For issues, feature requests, or contributions, please:

- Open an issue on GitHub
- Check the [documentation](docs/) for more details
- Join our community discussions

---

**Made with ❤️ using Flutter**
