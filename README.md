# WLED Dashboard

The **WLED Dashboard** is a cross-platform solution for controlling multiple WLED LED devices with ease, enabling users to manage all devices with a single button press through presets. It consists of a Flutter-based frontend app and a secure Node.js backend API, designed for seamless integration and efficient device management.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Overview

The WLED Dashboard simplifies the control of multiple WLED LED controllers. The frontend app, built with Flutter, runs on iOS, Android, and web platforms, providing a modern, intuitive interface. The backend API, built with Node.js, securely manages device communication and preset automation. The primary goal is to allow users to toggle power, adjust brightness, or apply custom lighting presets across multiple WLED devices with one action.

For detailed setup and development instructions, see:
- [Frontend README](frontend/README.md)
- [Backend README](backend/README.md)

## Features

- **One-Click Control**: Apply presets to multiple WLED devices instantly.
- **Cross-Platform App**: Manage devices from iOS, Android, or web browsers.
- **Preset Management**: Create, edit, and reorder lighting presets for grouped control.
- **Scheduling**: Automate preset application with cron-based schedules.
- **Device Discovery**: Auto-detect WLED devices on the local network (where supported).
- **Secure Communication**: Uses API keys for secure backend interaction.
- **Responsive UI**: Material 3 design with light/dark themes and haptic feedback.

## Architecture

- **Frontend**: A Flutter app with Material 3 UI, using Provider for state management and HTTP for API communication. Key components include device control, preset management, and scheduling interfaces.
- **Backend**: A Node.js API with SQLite for data storage, handling instance management, preset creation, and cron-based scheduling. Secured with API key authentication and CORS.
- **Communication**: The frontend communicates with the backend via RESTful API calls, which in turn interact with WLED devices over HTTP.

## Installation

### Prerequisites
- **Frontend**: Flutter SDK 3.0+, Dart SDK, Android Studio/Xcode (for mobile builds).
- **Backend**: Node.js 16+, npm, SQLite.
- **WLED Devices**: Running WLED firmware, accessible on the local network.

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/RenautMestdagh/wled-dashboard.git
   cd wled-dashboard
   ```
2. Set up the backend (see [Backend README](backend/README.md)).
3. Set up the frontend (see [Frontend README](frontend/README.md)).
4. Configure the frontend with the backend API URL and key in the app's Settings.

## Usage

1. Launch the backend server to manage WLED devices.
2. Open the frontend app on your device or browser.
3. In Settings, enter the backend API URL (e.g., `http://your-server:3000`) and API key.
4. Add WLED devices manually or via auto-discovery.
5. Create presets to define lighting states for multiple devices.
6. Use the Presets tab to apply configurations with a single tap.
7. Set schedules for automated preset application.

## Contributing

Contributions are welcome! Please:
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/YourFeature`).
3. Commit changes (`git commit -m 'Add YourFeature'`).
4. Push to the branch (`git push origin feature/YourFeature`).
5. Open a pull request.

Report issues or suggest features via the [GitHub Issues](https://github.com/RenautMestdagh/wled-dashboard/issues) page.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.