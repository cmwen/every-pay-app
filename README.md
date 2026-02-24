# Every-Pay App

A Flutter application for payment management.

## Project Setup

### Prerequisites
- Flutter 3.10.1 or later
- Dart 3.10.1 or later
- Android SDK with API level 21+ (Android 5.0)
- Java 17 or later

### Getting Started

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Run the app**
   ```bash
   flutter run
   ```

3. **Run tests**
   ```bash
   flutter test
   ```

## Project Structure

```
├── lib/
│   ├── main.dart                 # App entry point
│   ├── screens/                  # UI screens
│   ├── services/                 # Business logic services
│   └── models/                   # Data models
├── test/
│   ├── widget_test.dart          # Widget tests
│   └── unit/                     # Unit tests
├── android/
│   ├── app/build.gradle.kts      # Android configuration
│   └── ...
└── pubspec.yaml                  # Dependencies
```

## Build

### Debug Build
```bash
flutter build apk
```

### Release Build
```bash
flutter build appbundle
```

## App Configuration

- **Package**: org.cmwen.everypay
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: Latest stable
- **Java Version**: 17

## Testing

Run tests with coverage:
```bash
flutter test --coverage
```

See [TESTING.md](TESTING.md) for detailed testing guidelines.

## Building for Release

Follow the signing guide in [SIGNING.md](SIGNING.md) to set up release signing.

## CI/CD

This project uses GitHub Actions for continuous integration and delivery. Workflows are configured in `.github/workflows/`.

- **build.yml**: Runs on every push and PR
- **release.yml**: Triggered by version tags (v*)
- **pre-release.yml**: Manual workflow for alpha/beta releases

## License

See [LICENSE](LICENSE) for details.
