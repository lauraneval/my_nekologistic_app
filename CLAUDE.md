# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get                  # Install dependencies
flutter run                      # Run app (needs --dart-define vars below)
flutter test                     # Run tests
flutter analyze                  # Lint (uses flutter_lints)
flutter format lib/              # Format code
```

Running requires environment variables passed via `--dart-define`:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_KEY \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Other optional `--dart-define` keys: `ENABLE_ACTIVITY_LOGS`, `ACTIVITY_LOG_PATH`, `ACTIVITY_LOG_QUEUE_MAX_ITEMS`, `MAX_DELIVERY_DISTANCE_METERS` (default 250), `POD_BUCKET`.

## Architecture

NekoLogistic is a Flutter courier delivery app. Couriers log in, view assigned delivery bags/tasks, capture proof-of-delivery (POD) photos, and track history.

**Boot flow:** `main()` → `AppBootstrap.initialize()` (Supabase init) → `NekoLogisticApp` → `SplashPage` checks auth → authenticated users land on `MobileShellPage` (tab nav), unauthenticated on `LoginPage`.

**Feature structure** (`lib/features/`):

| Feature | Purpose |
|---|---|
| `auth/` | Supabase sign-in/sign-out, login UI |
| `splash/` | Initial auth check and routing |
| `tasks/` | Courier bag models, API client, POD service, activity log queue |
| `mobile/` | Main app shell, home, task detail, delivery proof, history, profile pages |

**Core services** (`lib/core/`):

- `core/config/app_env.dart` — reads all `--dart-define` env vars; normalizes `localhost` → `10.0.2.2` on Android emulator
- `core/network/api_client.dart` — Dio HTTP client with automatic Bearer token injection from secure storage
- `core/storage/secure_storage_service.dart` — stores/retrieves JWT tokens via `flutter_secure_storage`

**State management:** No framework. The app uses `StatefulWidget` + `setState()` + `FutureBuilder` for async data. Services are passed as constructor parameters. `MobileCourierRepository` wraps API calls for abstraction.

**Key data flow:** `MobileShellPage` → `MobileCourierRepository` → `MobileCourierApiClient` (uses `ApiClient` with auth headers) → backend REST API. POD photos are compressed via `flutter_image_compress`, uploaded to a Supabase Storage bucket (`POD_BUCKET`), and recorded via `PodService`.

## Key Dependencies

- `supabase_flutter ^2.10.1` — auth and cloud storage
- `dio ^5.9.0` — HTTP client
- `flutter_secure_storage ^9.2.4` — JWT token persistence
- `geolocator ^14.0.2` — GPS for delivery distance validation
- `camera ^0.11.2` + `image_picker ^1.2.0` — POD photo capture
- `flutter_image_compress ^2.4.0` — compress photos before upload
- `url_launcher ^6.3.2` — open Google Maps for navigation
