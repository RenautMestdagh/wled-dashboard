# WLED Dashboard Frontend

A Flutter-based, cross-platform app for controlling WLED LED devices via a secure backend API. Designed for iOS, Android, and web, it enables users to manage multiple devices with a single button press using presets.

## Table of Contents

- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Dependencies](#dependencies)
- [Troubleshooting](#troubleshooting)

## Features

- **One-Tap Control**: Apply presets to multiple WLED devices instantly.
- **Device Management**: Add, edit, reorder, or delete WLED instances.
- **Preset System**: Create, edit, and apply custom lighting presets.
- **Scheduling**: Automate presets with cron-based schedules.
- **Real-Time Controls**: Adjust power, brightness, colors, and CCT.
- **Device Discovery**: Auto-detect WLED devices on the local network (mobile/desktop only).
- **Responsive UI**: Material 3 design with light/dark themes and haptic feedback.
- **Performance**: Caches device states to minimize API calls.

## Screenshots

| Home Screen | Instance Control | Create Preset |
|-------------|------------------|---------------|
| ![Home Screen](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/home_screen.jpg?raw=true) | ![Instance Control](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/instance_control.jpg?raw=true) | ![Create Preset](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/preset_edit.jpg?raw=true) |

| Schedules | Settings | Reorder Interface |
|-----------|----------|-------------------|
| ![Schedules](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/schedule.jpg?raw=true) | ![Settings](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/settings.jpg?raw=true) | ![Reorder Interface](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/reorder.jpg?raw=true) |

## Installation

### Prerequisites
- Flutter SDK (3.0+ recommended).
- Dart SDK (included with Flutter).
- Android Studio/Xcode for mobile builds.
- Running [WLED Control Backend API](../backend/README.md).

### Steps
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   - Development: `flutter run` (select device/emulator).
   - Web: `flutter run -d chrome`.
   - Release: `flutter build apk` (Android) or `flutter build ios` (iOS).
4. For web builds: `flutter build web` and serve the `build/web` directory.

## Usage

1. Open the app and go to Settings to set the backend API URL (e.g., `http://your-server:3000`) and API key.
2. Add WLED devices via auto-discovery or manually in the Instances tab.
3. Create presets in the Presets tab to configure multiple devices.
4. Apply presets with a single tap or schedule them in the Schedules tab.
5. Use the Instances tab for individual device controls (power, brightness, colors).

## Configuration

- **API Settings**: Set in-app via Settings > API Configuration, stored in `shared_preferences`.
- **Theme**: Choose system, light, or dark mode in Settings.
- **Discovery**: Enabled on mobile/desktop; not available on web due to mDNS limitations.
- **Custom Colors**: Defined in `main.dart` for light/dark themes.

## Architecture

- **State Management**: Uses Provider for API, theme, and data caching.
- **Networking**: HTTP requests via the `http` package to the backend API.
- **UI Framework**: Material 3 with custom themes.
- **Key Files**:
  - `main.dart`: App entry, splash screen, providers.
  - `api_service.dart`: API communication and state handling.
  - `home_screen.dart`: Tabbed interface for navigation.
  - `instance_screen.dart`: Device control UI.
  - `presets_screen.dart`: Preset creation and management.
  - `schedule_screen.dart`: Schedule management UI.
  - `settings_screen.dart`: API and theme configuration.
  - `wled_discovery_service.dart`: mDNS device discovery.

## Dependencies

- `flutter`: Core framework.
- `provider`: State management.
- `http`: API communication.
- `shared_preferences`: Local storage.
- `flutter_native_splash`: Splash screen.
- `multicast_dns`: Device discovery.
- Full list: See `pubspec.yaml`.

Update dependencies with:
```bash
flutter pub upgrade
```

## Troubleshooting

- **API Connection**: Ensure the backend is running and the API key is correct. Check logs with `flutter run -v`.
- **Discovery Issues**: Verify devices are on the same network; mDNS may require permissions.
- **State Not Updating**: Use pull-to-refresh or the app bar refresh button.
- **Web Limitations**: No mDNS or haptic feedback; ensure CORS is configured in the backend.