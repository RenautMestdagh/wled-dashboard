# WLED Control Backend API

A secure backend for managing and controlling WLED devices with preset functionality.

## Table of Contents

- [Features](#features)
- [API Endpoints](#api-endpoints)
    - [Authentication](#authentication)
    - [Instance Management](#instance-management)
    - [Preset Management](#preset-management)
    - [WLED Device Interaction](#wled-device-interaction)
- [Error Handling](#error-handling)
- [Database Schema](#database-schema)
- [Environment Variables](#environment-variables)
- [Setup](#setup)

## Features

- Secure API key authentication
- WLED instance management
- Preset creation and management
- Direct WLED device control
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
        "last_seen": "2023-05-15T14:30:00.000Z"
    }
]
```

**Notes:**
- Missing/empty names will be automatically populated from the WLED device info if possible

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
        "created_at": "2023-05-15T14:30:00.000Z",
        "instance_count": 2
    }
]
```

#### Get Preset Details

```
GET /api/presets/{id}
```

**Response:**

```json
{
    "id": 1,
    "name": "Party Mode",
    "created_at": "2023-05-15T14:30:00.000Z",
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

- `instances` (id, ip, name, last_seen)
- `presets` (id, name, created_at)
- `preset_instances` (preset_id, instance_id, instance_preset)

## Environment Variables

```
PORT=3000
DB_PATH=./data/wled-control.db
API_KEYS=your-secret-key,another-key
NODE_ENV=development
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