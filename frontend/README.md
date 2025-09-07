# WLED Controller Flutter App

A modern, cross-platform mobile and web app for managing WLED LED controllers through a secure backend API. Built with Flutter for seamless performance across iOS, Android, and web platforms.

![App Banner](https://github.com/RenautMestdagh/wled-dashboard/blob/main/frontend/assets/images/wled.png?raw=true)

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Architecture](#architecture)
- [Dependencies](#dependencies)
- [Troubleshooting](#troubleshooting)

## Overview

This Flutter application serves as the frontend for the WLED Control Backend API. It allows users to manage multiple WLED devices, create and apply presets, schedule automations, and customize settings. The app emphasizes a clean, intuitive UI with Material 3 design principles, supporting both light and dark themes.

Key highlights:
- **Cross-Platform**: Runs on iOS, Android, and web browsers.
- **Real-Time Control**: Toggle power, adjust brightness, colors, and CCT for individual or grouped devices.
- **Preset Management**: Create, edit, reorder, and apply presets across devices.
- **Scheduling**: Set up cron-based schedules for automated preset application.
- **Discovery**: Auto-discover WLED devices on the local network (where supported).
- **Secure**: Communicates with the backend via API keys.

The app connects to the [WLED Control Backend API](https://github.com/RenautMestdagh/wled-dashboard/blob/main/backend/README.md) for all operations, ensuring secure and efficient device management.

## Features

- **Instance Management**:
    - Add, edit, delete, and reorder WLED devices.
    - Real-time status monitoring (online/offline, power state).
    - Support for RGB, white, and CCT controls.

- **Preset System**:
    - Create presets with per-device configurations (presets or direct states).
    - Apply presets instantly to multiple devices.
    - Reorder and manage presets via drag-and-drop.

- **Scheduling**:
    - Create cron-based schedules for presets.
    - Enable/disable schedules, set start/end dates.
    - View and edit schedule details.

- **Device Controls**:
    - Power toggle (individual and global).
    - Brightness slider.
    - Color picker for RGB segments.
    - CCT (Correlated Color Temperature) slider for white channels.
    - Apply device-specific presets.

- **Settings**:
    - Configure backend API URL and key.
    - Theme switching (light, dark, system).
    - Auto-discovery of WLED devices via mDNS (on supported platforms).
    - Reorder tabs for instances and presets.

- **UI/UX Enhancements**:
    - Refresh indicators for data loading.
    - Error handling with snackbars.
    - Haptic feedback on interactions (mobile).
    - Responsive design for phones, tablets, and web.

- **Performance**:
    - Caching for device states to reduce API calls.
    - Background refreshing for up-to-date info.

## Screenshots

Here are some placeholder screenshots showcasing the app's interface. Replace these with actual images in your repository.

![Home Screen](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/home_screen.jpg?raw=true)
*Home screen with tab navigation for presets, instances, and settings.*

![Instance Control](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/instance_control.jpg?raw=true)
*Detailed control screen for a single WLED instance, including color picker and presets.*

![Create Preset](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/preset_edit.jpg?raw=true)
*Presets creation screen.*

![Schedules](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/schedule.jpg?raw=true)
*Schedules screen for automating preset applications.*

![Settings](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/settings.jpg?raw=true)
*Settings screen for API configuration, theme, and reordering.*

![Reorder Interface](https://github.com/RenautMestdagh/wled-dashboard/blob/main/.github/pictures/reorder.jpg?raw=true)
*Drag-and-drop reordering for instances or presets.*

## Installation

### Prerequisites
- Flutter SDK (version 3.0+ recommended).
- Dart SDK (included with Flutter).
- A running instance of the [WLED Control Backend API](https://github.com/RenautMestdagh/wled-dashboard/blob/main/backend/README.md).
- For mobile: Android Studio or Xcode for building APKs/IPAs.
- For web: Chrome for testing.

### Steps
1. Clone the repository:
   ```
   git clone https://github.com/RenautMestdagh/wled-dashboard.git
   cd frontend
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Configure the backend API (see [Configuration](#configuration) below).

4. Run the app:
    - For development: `flutter run` (select device/emulator).
    - For web: `flutter run -d chrome`.
    - For release build: `flutter build apk` (Android) or `flutter build ios` (iOS).

5. (Optional) Build for web: `flutter build web` and serve the `build/web` directory.

## Usage

1. Launch the app and navigate to Settings to enter your backend API URL (e.g., `http://your-server:3000`) and API key.
2. The app will connect and fetch instances/presets. If no data, add instances via autodiscovery or manually.
3. Use the bottom tabs to switch between Presets, individual Instances, and Settings.
4. Create presets by assigning device-specific states or presets.
5. Schedule automations in the Schedules section.
6. Toggle global power or refresh data from the app bar.

For detailed API interactions, refer to the backend's [API Endpoints](https://github.com/RenautMestdagh/wled-dashboard/blob/main/backend/README.md#api-endpoints).

## Configuration

- **API Settings**: Stored in `shared_preferences`. Edit in-app via Settings > API Configuration.
- **Theme**: System, light, or dark mode via Settings.
- **Discovery**: Enabled on mobile/desktop; not on web due to mDNS limitations.
- **Environment Variables**: For web builds, configure CORS in the backend to allow your app's origin.

Custom colors are defined in `main.dart` for light/dark themes. Adjust as needed.

## Architecture

- **State Management**: Provider for API service, theme, and data caching.
- **Networking**: HTTP requests via `http` package to backend endpoints.
- **UI Framework**: Material 3 with custom themes.
- **Key Files**:
    - `main.dart`: Entry point, splash screen, providers.
    - `api_service.dart`: Handles all API calls and state.
    - `home_screen.dart`: Main tabbed interface.
    - `instance_screen.dart`: Device control UI.
    - `presets_screen.dart`: Preset management.
    - `schedule_screen.dart`: Scheduling UI.
    - `settings_screen.dart`: Configuration and discovery.
    - `reorder_screen.dart`: Drag-and-drop reordering.
    - `wled_discovery_service.dart`: mDNS-based device discovery.

The app follows MVC patterns with services for separation of concerns.

## Dependencies

- `flutter`: Core framework.
- `provider`: State management.
- `http`: API requests.
- `shared_preferences`: Local storage.
- `flutter_native_splash`: Splash screen.
- `multicast_dns`: Device discovery.
- Other minor packages: See `pubspec.yaml`.

To update: `flutter pub upgrade`.

## Troubleshooting

- **API Connection Issues**: Verify backend is running and API key is correct. Check console for errors.
- **Discovery Not Working**: Ensure devices are on the same network; mDNS may require permissions.
- **State Not Updating**: Refresh via pull-to-refresh or app bar button.
- **Web Limitations**: No mDNS; some features like haptics are mobile-only.
- **Errors**: Snackbars show messages; check Flutter logs with `flutter run -v`.
