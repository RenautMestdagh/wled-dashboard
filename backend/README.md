# WLED Control Backend API

A secure backend for managing and controlling WLED devices with preset functionality.

## Table of Contents

- [Features](#features)
- [API Endpoints](#api-endpoints)
    - [Authentication](#authentication)
    - [Instance Management](#instance-management)
    - [Preset Management](#preset-management)
    - [Schedule Management](#schedule-management)
    - [WLED Device Interaction](#wled-device-interaction)
- [Error Handling](#error-handling)
- [Database Schema](#database-schema)
- [Environment Variables](#environment-variables)
- [Setup](#setup)

## Features

- Secure API key authentication
- WLED instance management
- Preset creation and management
- Automated preset scheduling with cron expressions
- Direct WLED device control
- Custom ordering of instances and presets
- Input validation and error handling
- Rate limiting for API protection
- Cross-Origin Resource Sharing (CORS) configuration

## API Endpoints

### Base URL

`http://your-server-address:3000`

### Authentication

All endpoints require an API key in the `X-API-Key` header or as a query parameter `apiKey`.

### Instance Management

#### Get All Instances

```
GET /api/instances
```

**Response:**

```json
[
    {
        "id": 1,
        "ip": "192.168.1.100",
        "name": "Living Room",
        "display_order": 0,
        "last_seen": "2023-05-15T14:30:00.000Z"
    }
]
```

**Notes:**
- Missing/empty names will be automatically populated from the WLED device info if possible
- Instances are returned in order defined by their `display_order` value

#### Create Instance

```
POST /api/instances
```

**Request Body:**

```json
{
    "ip": "192.168.1.100",
    "name": "New WLED"
}
```

**Notes:**

- Verifies WLED is reachable before creating
- Validates IP address format
- Ensures the device is a proper WLED controller
- Checks for duplicate IP addresses
- New instances are assigned the next available display order value

#### Update Instance

```
PUT /api/instances/{id}
```

**Request Body (partial updates supported):**

```json
{
    "ip": "192.168.1.101",
    "name": "Updated Name"
}
```

#### Delete Instance

```
DELETE /api/instances/{id}
```

#### Reorder Instances

```
POST /api/instances/reorder
```

**Request Body:**

```json
{
    "orderedIds": [3, 1, 2, 4]
}
```

**Response:**
```json
[
    {
        "id": 3,
        "ip": "192.168.1.102",
        "name": "Kitchen",
        "display_order": 0,
        "last_seen": "2023-05-15T14:30:00.000Z"
    },
    {
        "id": 1,
        "ip": "192.168.1.100",
        "name": "Living Room",
        "display_order": 1,
        "last_seen": "2023-05-15T14:30:00.000Z"
    },
    ...
]
```

**Notes:**
- Updates the display order of instances based on the array position
- Returns all instances in their new order
- Database transactions ensure all updates succeed or fail together

### Preset Management

#### Get All Presets

```
GET /api/presets
```

**Response:**

```json
[
    {
        "id": 1,
        "name": "Party Mode",
        "display_order": 0,
        "instance_count": 2
    }
]
```

**Notes:**
- Presets are returned in order defined by their `display_order` value

#### Get Preset Details

```
GET /api/presets/{id}
```

**Response:**

```json
{
    "id": 1,
    "name": "Party Mode",
    "instances": [
        {
            "instance_id": 1,
            "instance_name": "Living Room",
            "instance_ip": "192.168.1.100",
            "instance_preset": 2
        },
        {
            "instance_id": 3,
            "instance_name": "Bedroom",
            "instance_ip": "192.168.1.102",
            "instance_preset": 4
        }
    ]
}
```

#### Create Preset

```
POST /api/presets
```

**Request Body:**

```json
{
    "name": "Relaxing",
    "instances": [
        {
            "instance_id": 1,
            "instance_preset": 1
        },
        {
            "instance_id": 2,
            "instance_preset": 0
        }
    ]
}
```

**Notes:**

- `instance_preset` can be a number (WLED preset index) or object (direct state)
- Database transactions ensure data integrity
- Name must be unique
- New presets are assigned the next available display order value

#### Update Preset

```
PUT /api/presets/{id}
```

**Request Body:**

```json
{
    "name": "Updated Preset",
    "instances": [
        {
            "instance_id": 1,
            "instance_preset": 2
        }
    ]
}
```

**Notes:**
- Transactions ensure atomicity of updates
- When updating instances, all existing associations are replaced

#### Delete Preset

```
DELETE /api/presets/{id}
```

#### Apply Preset

```
POST /api/presets/{id}/apply
```

**Response:**

```json
{
    "success": true,
    "message": "Preset \"Relaxing\" applied to 2 instances",
    "results": [
        {
            "instance_id": 1,
            "instance_name": "Living Room",
            "success": true,
            "result": {
                "state": "ok"
            }
        },
        {
            "instance_id": 2,
            "instance_name": "Bedroom",
            "success": true,
            "result": {
                "state": "ok"
            }
        }
    ]
}
```

#### Reorder Presets

```
POST /api/presets/reorder
```

**Request Body:**

```json
{
    "orderedIds": [3, 1, 2, 4]
}
```

**Response:**
```json
[
    {
        "id": 3,
        "name": "Movie Night",
        "display_order": 0,
        "instance_count": 3
    },
    {
        "id": 1,
        "name": "Party Mode",
        "display_order": 1,
        "instance_count": 2
    },
    ...
]
```

**Notes:**
- Updates the display order of presets based on the array position
- Returns all presets in their new order
- Database transactions ensure all updates succeed or fail together

### Schedule Management

#### Get All Schedules

```
GET /api/schedules
```

**Response:**

```json
[
    {
        "id": 1,
        "name": "Daily Lights On",
        "cron_expression": "0 0 8 * * *",
        "start_date": "2023-06-01",
        "stop_date": "2023-12-31",
        "enabled": 1,
        "preset_id": 1,
        "preset_name": "Morning Light"
    }
]
```

**Notes:**
- Schedules are returned ordered by ID

#### Get Schedule Details

```
GET /api/schedules/{id}
```

**Response:**

```json
{
    "id": 1,
    "name": "Daily Lights On",
    "cron_expression": "0 0 8 * * *",
    "start_date": "2023-06-01",
    "stop_date": "2023-12-31",
    "enabled": 1,
    "preset_id": 1,
    "preset_name": "Morning Light"
}
```

#### Create Schedule

```
POST /api/schedules
```

**Request Body:**

```json
{
    "name": "Daily Lights On",
    "cron_expression": "0 0 8 * * *",
    "start_date": "2023-06-01",
    "stop_date": "2023-12-31",
    "enabled": true,
    "preset_id": 1
}
```

**Notes:**

- `cron_expression` must be a valid cron string
- `start_date` and `stop_date` are optional and in YYYY-MM-DD format
- `enabled` defaults to true
- Name must be unique
- If enabled, a cron job is scheduled immediately

#### Update Schedule

```
PUT /api/schedules/{id}
```

**Request Body (partial updates supported):**

```json
{
    "name": "Updated Schedule",
    "cron_expression": "0 0 9 * * *",
    "start_date": "CLEAR",
    "stop_date": "2024-01-01",
    "enabled": false
}
```

**Notes:**
- Use "CLEAR" to remove start_date or stop_date
- Updates the cron job if enabled changes or schedule is modified

#### Delete Schedule

```
DELETE /api/schedules/{id}
```

**Notes:**
- Stops any associated cron job

### WLED Device Interaction

#### Get Device Presets

```
GET /wled/{instanceId}/presets.json
```

**Response:**

```json
{
    "1": {
        "n": "Rainbow",
        "seg": [
            {
                "fx": 4
            }
        ]
    }
}
```

#### Get Device State

```
GET /wled/{instanceId}/state
```

**Response:**

```json
{
    "on": true,
    "bri": 128,
    "seg": [
        {
            "col": [
                [
                    255,
                    0,
                    0
                ]
            ]
        }
    ]
}
```

#### Set Device State

```
POST /wled/{instanceId}/state
```

**Request Body:**

```json
{
    "on": true,
    "bri": 200,
    "seg": [
        {
            "col": [
                [
                    0,
                    255,
                    0
                ]
            ]
        }
    ]
}
```

**OR for applying a WLED preset:**

```json
{
    "ps": 1
}
```

#### Get Device Info

```
GET /wled/{instanceId}/info
```

**Response:**

```json
{
    "ver": "0.13.1",
    "vid": 2212100,
    "leds": {
        "count": 60,
        "rgbw": false,
        "wv": false
    },
    "name": "WLED Light",
    "udpport": 21324,
    "live": false,
    "fxcount": 118,
    "palcount": 71,
    "arch": "esp32",
    "core": "v2.0.6",
    "lwip": 2,
    "freeheap": 170816,
    "uptime": 9876,
    "opt": 127,
    "brand": "WLED",
    "product": "DIY Light",
    "mac": "AB:CD:EF:12:34:56",
    "ip": "192.168.1.100"
}
```

## Error Handling

| Code | Status       | Description                     |
|------|--------------|---------------------------------|
| 400  | Bad Request  | Invalid input                   |
| 401  | Unauthorized | Missing/invalid API key         |
| 404  | Not Found    | Resource not found              |
| 408  | Timeout      | Device not responding           |
| 409  | Conflict     | Resource already exists         |
| 500  | Server Error | Internal error                  |
| 502  | Bad Gateway  | WLED device communication error |

## Database Schema

**Tables:**

- `instances` (id, ip, name, display_order, last_seen)
- `presets` (id, name, display_order)
- `preset_instances` (preset_id, instance_id, instance_preset)
- `preset_schedules` (id, name, cron_expression, start_date, stop_date, enabled, preset_id)

## Environment Variables

```
PORT=3000 # filled in by Docker
NODE_ENV=production # filled in by Docker
DB_PATH=/data/database.db # filled in by Docker

# Security Configuration
# Replace with your actual API keys, comma-separated if multiple
API_KEYS=your-secure-api-key-123,backup-key-456

# CORS Configuration
ALLOWED_ORIGINS=mydomain.com
```

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Create `.env` file with your configuration

3. Start the server:
   ```bash
   node server.js
   ```

4. Access API at http://localhost:3000

5. Check server health with:
   ```
   GET /health
   ```