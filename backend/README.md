# WLED Control Backend API

A secure Node.js backend API for managing and controlling multiple WLED LED devices, enabling one-click control through presets.

## Table of Contents

- [Features](#features)
- [API Endpoints](#api-endpoints)
- [Error Handling](#error-handling)
- [Database Schema](#database-schema)
- [Environment Variables](#environment-variables)
- [Setup](#setup)

## Features

- **One-Click Control**: Apply presets to multiple WLED devices via a single API call.
- **Instance Management**: Add, update, reorder, or delete WLED devices.
- **Preset Management**: Create, edit, and apply lighting presets.
- **Scheduling**: Automate presets with cron-based schedules.
- **Security**: API key authentication and CORS configuration.
- **Reliability**: Input validation, rate limiting, and transaction-based database updates.

## API Endpoints

### Base URL
`http://your-server:3000`

### Authentication
All endpoints require an `X-API-Key` header or `apiKey` query parameter.

### Instance Management
- **Get All Instances**: `GET /api/instances`
  - Returns: List of instances sorted by `display_order`.
- **Create Instance**: `POST /api/instances`
  - Body: `{ "ip": "192.168.1.100", "name": "Living Room" }`
  - Validates IP and checks for WLED compatibility.
- **Update Instance**: `PUT /api/instances/{id}`
  - Body: Partial updates for `ip` or `name`.
- **Delete Instance**: `DELETE /api/instances/{id}`
- **Reorder Instances**: `POST /api/instances/reorder`
  - Body: `{ "orderedIds": [3, 1, 2] }`
  - Updates `display_order` for instances.

### Preset Management
- **Get All Presets**: `GET /api/presets`
  - Returns: List of presets sorted by `display_order`.
- **Get Preset Details**: `GET /api/presets/{id}`
  - Returns: Preset with associated instances and settings.
- **Create Preset**: `POST /api/presets`
  - Body: `{ "name": "Relaxing", "instances": [{ "instance_id": 1, "instance_preset": 1 }] }`
  - Ensures unique name and valid instances.
- **Update Preset**: `PUT /api/presets/{id}`
  - Body: Updates name or instance associations.
- **Delete Preset**: `DELETE /api/presets/{id}`
- **Apply Preset**: `POST /api/presets/{id}/apply`
  - Applies preset to associated devices.
- **Reorder Presets**: `POST /api/presets/reorder`
  - Body: `{ "orderedIds": [3, 1, 2] }`

### Schedule Management
- **Get All Schedules**: `GET /api/schedules`
  - Returns: List of schedules with preset details.
- **Get Schedule Details**: `GET /api/schedules/{id}`
- **Create Schedule**: `POST /api/schedules`
  - Body: `{ "name": "Daily Lights", "cron_expression": "0 0 8 * * *", "preset_id": 1 }`
  - Validates cron expression.
- **Update Schedule**: `PUT /api/schedules/{id}`
  - Body: Partial updates; use `"CLEAR"` for optional fields.
- **Delete Schedule**: `DELETE /api/schedules/{id}`
  - Stops associated cron job.

### WLED Device Interaction
- **Get Device Presets**: `GET /wled/{instanceId}/presets.json`
- **Get Device State**: `GET /wled/{instanceId}/state`
- **Set Device State**: `POST /wled/{instanceId}/state`
  - Body: `{ "on": true, "bri": 200 }` or `{ "ps": 1 }`
- **Get Device Info**: `GET /wled/{instanceId}/info`

## Error Handling

| Code | Status       | Description                     |
|------|--------------|---------------------------------|
| 400  | Bad Request  | Invalid input                   |
| 401  | Unauthorized | Invalid/missing API key         |
| 404  | Not Found    | Resource not found              |
| 408  | Timeout      | Device not responding           |
| 409  | Conflict     | Resource already exists         |
| 500  | Server Error | Internal error                  |
| 502  | Bad Gateway  | WLED communication error        |

## Database Schema

- **instances**: `(id, ip, name, display_order, last_seen)`
- **presets**: `(id, name, display_order)`
- **preset_instances**: `(preset_id, instance_id, instance_preset)`
- **preset_schedules**: `(id, name, cron_expression, start_date, stop_date, enabled, preset_id)`

## Environment Variables

```bash
PORT=3000
NODE_ENV=production
DB_PATH=/data/database.db
API_KEYS=your-secure-api-key-123
ALLOWED_ORIGINS=mydomain.com
```

## Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a `.env` file with the above variables.
4. Start the server:
   ```bash
   node server.js
   ```
5. Verify with: `GET /health`