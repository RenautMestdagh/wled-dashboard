# WLED Dashboard

The **WLED Dashboard** is a cross-platform tool for managing multiple WLED LED controllers. It allows one-tap control via presets, automating lighting across devices. The Flutter frontend provides an intuitive UI for mobile and web, while the Node.js backend handles secure API interactions and scheduling.

## Features

- **Preset-Based Control**: Group device states (e.g., power, brightness, colors) into presets for instant application to multiple WLED devices.
- **Scheduling Automation**: Use cron expressions to trigger presets at specific times or intervals.
- **Device Management**: Discover, add, reorder, and control WLED instances with real-time feedback.
- **Cross-Platform Support**: Runs on iOS, Android, web, with responsive Material 3 design and theme options.
- **Security**: API key authentication ensures protected communication between frontend and backend.

## Architecture

The project separates concerns for scalability:
- **Frontend**: Handles user interactions, state caching, and API calls (via `http` package). It renders controls for instances, presets, and schedules.
- **Backend**: Manages database (SQLite) for storing instances/presets/schedules, communicates with WLED devices via HTTP, and runs cron jobs for automation.
- **Integration**: Frontend sends REST requests to the backend (e.g., `/api/presets/{id}/apply`), which proxies commands to WLED IPs.


```mermaid
graph TD
    A[User] --> B[Flutter Frontend]
    B --> C[Node.js Backend API]
    C --> D[SQLite DB]
    C --> E[WLED Devices]
    subgraph "Frontend Functionalities"
    B1[Device Discovery (mDNS)]
    B2[Preset/Schedule UI]
    B3[Real-Time Controls]
    B --> B1 & B2 & B3
    end
    subgraph "Backend Functionalities"
    C1[API Endpoints]
    C2[Cron Scheduling]
    C3[Device Proxy]
    C --> C1 & C2 & C3
    end
```

## Quick Start

1. Clone the repo: `git clone https://github.com/RenautMestdagh/wled-dashboard.git`.
2. Set up backend: See [Backend README](backend/README.md).
3. Set up frontend: See [Frontend README](frontend/README.md).
4. Launch backend: `node backend/server.js`.
5. Run frontend: `flutter run` in `/frontend`.
6. Configure API URL/key in app settings.

## Usage

- Add WLED devices in the app (manual or auto-discovery).
- Create presets to define group states.
- Apply presets or schedule them via cron.
- Monitor/control individual devices in real-time.

For detailed usage, refer to sub-READMEs.