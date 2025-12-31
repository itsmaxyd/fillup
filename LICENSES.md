# Licensing Documentation for Fillup App

## Project License

The Fillup app is licensed under the **GNU General Public License version 3.0 (GPL-3.0)**. This is a copyleft open-source license that ensures the software remains free and open-source.

### GPL-3.0 License Details

- **Permission**: Commercial use, modification, distribution, and private use
- **Limitations**: Liability and warranty disclaimers
- **Conditions**: License and copyright notice must be included, source code must be made available for modified versions, derivatives must also be GPL-3.0 licensed

## Dependency Licenses

All dependencies used in the Fillup app are open-source and use licenses compatible with GPL-3.0. Below is a detailed list of all dependencies and their respective licenses:

### Production Dependencies

| Package | Version | License | Description |
|---------|---------|---------|-------------|
| flutter | SDK | BSD-3 | Flutter framework |
| provider | ^6.1.1 | MIT | State management |
| sqflite | ^2.3.0 | MIT | SQLite database plugin |
| path | ^1.8.3 | MIT | Path manipulation |
| http | ^1.1.0 | BSD-3 | HTTP client |
| html | ^0.15.4 | MIT | HTML parser |
| fl_chart | ^0.65.0 | MIT | Chart library |
| cupertino_icons | ^1.0.6 | MIT | Cupertino icons |
| intl | ^0.18.1 | BSD-3 | Internationalization |
| path_provider | ^2.1.1 | MIT | Path provider |
| csv | ^6.0.0 | MIT | CSV parsing |
| share_plus | ^7.2.1 | MIT | Sharing functionality |

### Development Dependencies

| Package | Version | License | Description |
|---------|---------|---------|-------------|
| flutter_test | SDK | BSD-3 | Flutter testing framework |
| flutter_lints | ^3.0.1 | MIT | Flutter linting rules |

## License Compatibility

All licenses used in the Fillup app are compatible with the GPL-3.0 License and F-Droid's requirements:

- **GPL-3.0 License**: Copyleft, ensures software remains free and open-source
- **MIT License**: Permissive, compatible with GPL-3.0
- **BSD-3 License**: Permissive, compatible with GPL-3.0

## F-Droid Compliance

The Fillup app is fully compliant with F-Droid's licensing requirements:

- ✅ All dependencies are open-source
- ✅ No proprietary or closed-source components
- ✅ All licenses are compatible with GPL-3.0
- ✅ GPL-3.0 is an approved copyleft license for F-Droid

## License Files

The following license files are included in the project:

- `LICENSE`: GPL-3.0 License for the Fillup app
- `android/NOTICE`: Android-specific license notices

## Third-Party Attributions

The Fillup app uses the following third-party libraries:

1. **Flutter**: BSD-3 License
2. **Provider**: MIT License
3. **Sqflite**: MIT License
4. **Path**: MIT License
5. **HTTP**: BSD-3 License
6. **HTML**: MIT License
7. **Fl_Chart**: MIT License
8. **Cupertino Icons**: MIT License
9. **Intl**: BSD-3 License
10. **Path Provider**: MIT License
11. **CSV**: MIT License
12. **Share Plus**: MIT License

## License Verification

To verify the licenses of all dependencies, you can run the following command:

```bash
flutter pub deps --prod
```

This will list all production dependencies and their respective licenses.

## Conclusion

The Fillup app is fully compliant with open-source licensing requirements and F-Droid's policies. All dependencies use licenses compatible with GPL-3.0 that allow for free use, modification, and distribution while ensuring the software remains open-source.