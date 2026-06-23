# Dr.Plus — Mobile (Flutter)

Cross-platform (iOS & Android) client for the Dr.Plus marketplace, built with
**strict Clean Architecture** and **BLoC** state management.

## Architecture

Each feature is split into three independent layers with a strict dependency
rule: `presentation → domain ← data`. The **domain** layer is pure Dart (no
Flutter, no Dio, no JSON) and defines entities, repository contracts, and use
cases. The **data** layer implements those contracts over the network/cache.
The **presentation** layer holds BLoCs/Cubits only.

```
lib/
├── core/                         # cross-feature infrastructure
│   ├── di/                       # get_it service locator
│   ├── entities/                 # shared value objects (GeoPoint, PagedResult…)
│   ├── error/                    # Failure (domain) + Exception (data) types
│   ├── network/                  # Dio ApiClient, endpoints, interceptor, NetworkInfo
│   ├── storage/                  # secure JWT persistence
│   ├── usecase/                  # UseCase base contracts
│   └── utils/                    # typedefs, JSON mappers, repository helpers
└── features/
    ├── auth/                     # 1. Authentication & role selection
    │   ├── data/                 #    models · datasources · repository impl
    │   ├── domain/               #    entities · repository · usecases
    │   └── presentation/         #    AuthBloc · RoleSelectionCubit
    └── booking/                  # 2. Specialist search & live booking
        ├── data/
        ├── domain/
        └── presentation/         #    SpecialistSearchBloc · BookingBloc
```

## Error handling

Every repository method returns `Either<Failure, T>` (dartz). Data sources throw
typed `Exception`s; repositories translate them into `Failure`s via
`guardRemote` / `guardLocal`, which also short-circuit to `NetworkFailure` when
offline. BLoCs `fold` the result into discrete, equatable states.

## Backend mapping

| Use case               | Endpoint                                  |
| ---------------------- | ----------------------------------------- |
| RegisterClient         | `POST /auth/register/client`              |
| RegisterProvider       | `POST /auth/register/provider`            |
| LoginUser              | `POST /auth/login`                        |
| GetCurrentUser         | `GET  /auth/me`                           |
| SearchSpecialists      | `GET  /providers` (query filters)         |
| GetSpecialistDetails   | `GET  /providers/:id`                     |
| BookAppointment        | `POST /appointments`                      |
| PayForAppointment      | `POST /appointments/:id/pay`              |

> **Note:** `GET /providers` (specialist search) is the one endpoint the client
> consumes that is not yet implemented on the backend. The Provider model
> already carries the geo/specialty/text/rating indexes for it; wiring the
> route + controller is the matching backend follow-up.

## Live video consultation (`features/video`)

The video call follows the same Clean layering. The domain stays pure (token
entity + use cases hitting `POST /appointments/:id/video/{token,start,end}`),
while the Agora SDK is isolated behind `AgoraVideoService` (infra) and runtime
permissions behind `MediaPermissionService`. `VideoCallCubit` orchestrates the
pipeline — **request permissions → fetch token → init engine → join channel** —
and exposes call controls (mute, camera, flip, hang-up). `VideoCallPage` renders
the remote feed full-screen with a local picture-in-picture, a status/timer top
bar, and the control dock, with graceful permission-denied and error states.
Entry point: the booking confirmation dialog ("Start video consultation") for
online appointments.

### Native setup required for the SDK

The Dart layer analyses cleanly, but `agora_rtc_engine` + `permission_handler`
need platform config when the `android/` and `ios/` folders are generated
(`flutter create .`):

- **Android** — `minSdkVersion 21`; add `CAMERA`, `RECORD_AUDIO`, and
  `INTERNET` permissions to `AndroidManifest.xml`.
- **iOS** — add `NSCameraUsageDescription` and `NSMicrophoneUsageDescription`
  to `Info.plist`; set the platform to iOS 12+.

## Running

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1   # Android emulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:4000/api/v1  # iOS simulator
```

State management: `flutter_bloc`. DI: `get_it`. Networking: `dio`.
Functional errors: `dartz`. Secure storage: `flutter_secure_storage`.
Video: `agora_rtc_engine`. Permissions: `permission_handler`.
