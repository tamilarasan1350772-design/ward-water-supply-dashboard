# Ward Water Supply Measurement and Equity Dashboard

A comprehensive, production-quality Flutter application designed for local municipal telemetry monitoring. This application is designed with an **offline-first architecture** to manage local ward-wise water supply readings, compute statistics on equity distributions, highlight critical system faults or flow extremes, and synchronize readings safely with a mock server once cellular or Wi-Fi network connectivity is recovered.

## Features

- **Material 3 Modern UI**: Professional typography, light/dark mode theme support, fluid responsive layout for both standard mobile and tablet devices.
- **Offline-First Architecture**: Powered by a robust SQLite (`sqflite`) layer. Telemetry is saved instantly locally and synchronized with background intelligence.
- **Auto-Sync Network Simulation**: Toggle offline modes instantly using the persistent state bar. Auto-sync uploads pending items the second network comes online.
- **Seeding Panel**: Instantly populate the application with **40 sample records** containing:
  - Healthy readings
  - Missing/Null values
  - Extreme flow burst readings (>5000 Litres)
  - Faulty stuck readings from devices
- **Rich KPI Indicators**: Real-time calculated dashboard with Metrics for total readings, pending queues, todays count, average flows, highest/lowest flow locations, and faulty occurrences.
- **Charts and Graphs**: Beautiful and lightweight bar charts utilizing the `fl_chart` package to visualize ward distribution equity.
- **Advanced Search & Filter Suite**: Easily find historical telemetry by filtering specific wards, valve configurations, device IDs, or relative time ranges (Today, Last 7 Days, Last 30 Days, All).
- **Live Simulator Module**: Turn on live telemetry simulations to generate realistic and randomized network telemetry reading entries directly into local database queues.

## Architecture

The application adopts a rigid **Repository Pattern** and **State Management with Riverpod** to ensure testability and isolation.

```
┌────────────────────────────────────────────────────────┐
│                        VIEW LAYER                      │
│        (DashboardScreen, CaptureScreen, SearchScreen)  │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│                    PROVIDERS (Riverpod)                │
│    (StateNotifier, ChangeNotifier, StreamProviders)     │
└───────────────────────────┬────────────────────────────┘
                            ▼
┌────────────────────────────────────────────────────────┐
│                  REPOSITORIES & SERVICES               │
│  (WaterReadingRepository, SyncService, MockApiService)  │
└──────────────┬──────────────────────────┬──────────────┘
               ▼                          ▼
┌─────────────────────────────┐ ┌────────────────────────┐
│       LOCAL STORAGE         │ │     REMOTE MOCK API    │
│     (SQLite Database)       │ │     (In-Memory Server) │
└─────────────────────────────┘ └────────────────────────┘
```

## Folder Structure

```
lib/
 ├── constants/       # Theme, color variables, system constants
 ├── database/        # DatabaseHelper configurations (SQLite)
 ├── models/          # Telemetry and Dashboard stats models
 ├── providers/       # Riverpod Providers & StateNotifiers
 ├── repositories/    # Repository patterns for data manipulation
 ├── screens/         # Dashboard, Capture, Search, and Simulator Screens
 ├── services/        # Connection state, Mock API, Sync Service
 ├── utils/           # Seeding helpers
 └── widgets/         # Charts, Cards, custom Tiles
```

## Database Schema

Table name: `water_readings`

| Column | Type | Description |
| :--- | :--- | :--- |
| `reading_id` | TEXT (PK) | Unique UUID generated on creation. |
| `ward` | TEXT | Target ward location. |
| `flow_litres` | REAL | Recorded flow rate in Litres (Nullable). |
| `valve_state` | TEXT | Operating valve state (`OPEN`, `CLOSED`, `HALF-OPEN`). |
| `recorded_at` | TEXT | ISO-8601 Timestamp of reading. |
| `device_id` | TEXT | Node hardware identification. |
| `sync_status` | TEXT | Sync flags (`pending`, `synced`, `failed`). |

## Installation & How to Run

1. Clone this repository.
2. Ensure Flutter is installed (`flutter doctor`).
3. Run `flutter pub get` from the root project directory.
4. Run standard launch commands:
   - For web: `flutter run -d chrome`
   - For mobile: `flutter run`
5. Click **"Seed 40 Sample Records"** on the empty state screen to instantly visualize statistics, charts, and telemetry.

## Testing

Comprehensive instructions for testing can be found in the [TESTING.md](TESTING.md) file, covering:
- Normal case testing
- Offline flow simulation
- Extreme bursts and fault flagging
- Network connection recovery retries
- Duplicate prevention mechanisms
