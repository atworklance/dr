# Dr.Plus — Setup & Run Guide

Dr.Plus is a dual-sided service-provider marketplace and real-time consultation
platform. This monorepo contains three applications:

| App | Path | Stack | What it is |
| --- | --- | --- | --- |
| **Backend API** | [`backend/`](backend) | Node.js · TypeScript · Express · Mongoose · Socket.io | REST + realtime API (auth, booking, escrow/wallet, chat, video tokens, admin) |
| **Admin web** | [`admin/`](admin) | React · TypeScript · Vite | Platform Control Hub (verification, commission, metrics) |
| **Mobile app** | [`mobile/`](mobile) | Flutter · BLoC · Clean Architecture | Patient + provider apps |

```
Flutter mobile ─┐
                ├─► Backend API (http://localhost:4000) ─► MongoDB
React admin web ─┘        ▲
                          └─ Socket.io (chat / call signalling) · Agora (video)
```

---

## 1. Prerequisites

| Tool | Version | Notes |
| --- | --- | --- |
| **Node.js** | ≥ 18 | Backend + admin |
| **npm** | ≥ 9 | Ships with Node |
| **MongoDB** | ≥ 6, **as a replica set** | Booking, payments, and admin verification use multi-document **transactions**, which require a replica set (or MongoDB Atlas). A standalone `mongod` will not work for those flows. |
| **Flutter SDK** | ≥ 3.19 (Dart ≥ 3.3) | Mobile app only |
| **openssl** | any | To generate the field-encryption key |
| **Agora account** | optional | Only needed for live video; without it, the video-token endpoint returns `503` and everything else works |

> **Why a replica set?** Mongoose `session.withTransaction(...)` is used to keep
> appointment + wallet (and user + provider) writes atomic. Transactions are
> only available on replica sets / sharded clusters.

### Quickest MongoDB option — single-node replica set via Docker

```bash
docker run -d --name drplus-mongo -p 27017:27017 mongo:7 --replSet rs0
docker exec -it drplus-mongo mongosh --eval "rs.initiate()"
```

Then use this connection string (note the `replicaSet` param):

```
mongodb://127.0.0.1:27017/drplus?replicaSet=rs0
```

> Prefer the cloud? Create a free **MongoDB Atlas** cluster and use its
> `mongodb+srv://...` connection string instead — transactions work out of the box.

---

## 2. Backend API (`backend/`)

```bash
cd backend

# 1. Install dependencies
npm install

# 2. Create your env file
cp .env.example .env

# 3. Generate a real 32-byte field-encryption key and paste it into .env
openssl rand -hex 32
```

Edit `backend/.env` and set at minimum:

```bash
MONGODB_URI=mongodb://127.0.0.1:27017/drplus?replicaSet=rs0   # or your Atlas URI
FIELD_ENCRYPTION_KEY=<paste the 64-char hex from openssl>
JWT_SECRET=<any long random string>

# Optional — enables live video (otherwise the video-token route returns 503)
AGORA_APP_ID=<from console.agora.io>
AGORA_APP_CERTIFICATE=<from console.agora.io>
```

Run it:

```bash
# Development (auto-reload)
npm run dev

# — or — production build + run
npm run build
npm start
```

The API listens on **http://localhost:4000** (base path `/api/v1`).
Health check: `curl http://localhost:4000/api/v1/health`

Useful checks:

```bash
npm run typecheck   # TypeScript, no emit
npm run build       # compile to dist/
```

---

## 3. Create an admin user

Registration only creates `client` / `provider` accounts, so promote one user to
`admin` once. First register a user (via the mobile app, or curl):

```bash
curl -X POST http://localhost:4000/api/v1/auth/register/client \
  -H 'Content-Type: application/json' \
  -d '{"firstName":"Admin","lastName":"User","email":"admin@drplus.app","password":"Password123"}'
```

Then promote it to admin in the database:

```bash
# Docker example; for a local mongosh just run `mongosh`
docker exec -it drplus-mongo mongosh drplus --eval \
  'db.users.updateOne({ email: "admin@drplus.app" }, { $set: { role: "admin", status: "active" } })'
```

You can now sign in to the admin dashboard with `admin@drplus.app` / `Password123`.

---

## 4. Admin web dashboard (`admin/`)

```bash
cd admin

# 1. Install dependencies
npm install

# 2. (Optional) point at a non-default API
cp .env.example .env
# .env -> VITE_API_BASE_URL=http://localhost:4000/api/v1   (this is the default)

# 3. Run the dev server
npm run dev
```

Open **http://localhost:5173** and sign in with the admin account from step 3.

Production build:

```bash
npm run build       # tsc --noEmit && vite build  ->  dist/
npm run preview     # serve the built dist/ locally
```

---

## 5. Flutter mobile app (`mobile/`)

The repo ships the Dart source (`lib/`) only, so generate the platform folders
first, then fetch packages.

```bash
cd mobile

# 1. Generate android/ ios/ platform folders (keeps lib/ and pubspec.yaml)
flutter create .

# 2. Fetch dependencies
flutter pub get

# 3. Static analysis (optional but recommended)
flutter analyze
```

### Native config required for video + permissions

`agora_rtc_engine` and `permission_handler` need platform setup after
`flutter create .`:

- **Android** — in `android/app/build.gradle` set `minSdkVersion 21`; add to
  `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-permission android:name="android.permission.RECORD_AUDIO"/>
  ```
- **iOS** — set platform to iOS 12 in `ios/Podfile` (`platform :ios, '12.0'`) and
  add to `ios/Runner/Info.plist`:
  ```xml
  <key>NSCameraUsageDescription</key><string>For video consultations.</string>
  <key>NSMicrophoneUsageDescription</key><string>For video consultations.</string>
  ```

### Run

Point the app at your backend with `--dart-define`. The Socket.io URL is derived
from the API origin automatically.

```bash
# Android emulator (10.0.2.2 = host loopback)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api/v1

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:4000/api/v1

# Physical device — use your machine's LAN IP, e.g.
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:4000/api/v1
```

Register as a **patient** or **provider** in-app; the app routes providers to the
provider shell (availability, incoming calls, earnings) and patients to search →
book → pay → video → chat.

---

## 6. Ports & URLs

| Service | URL |
| --- | --- |
| Backend API | http://localhost:4000/api/v1 |
| Backend health | http://localhost:4000/api/v1/health |
| Socket.io | ws://localhost:4000 (path `/socket.io`) |
| Admin web | http://localhost:5173 |
| MongoDB | mongodb://127.0.0.1:27017 |

---

## 7. Recommended boot order

1. **MongoDB** (replica set up and initiated).
2. **Backend** — `cd backend && npm run dev`.
3. **Promote an admin user** (one-time, step 3).
4. **Admin web** — `cd admin && npm run dev`.
5. **Mobile** — `cd mobile && flutter run --dart-define=API_BASE_URL=...`.

---

## 8. Troubleshooting

| Symptom | Cause / Fix |
| --- | --- |
| `Transaction numbers are only allowed on a replica set member or mongos` | MongoDB is standalone. Use the replica-set Docker command above, or Atlas, and add `?replicaSet=rs0` to `MONGODB_URI`. |
| `FIELD_ENCRYPTION_KEY must decode to 32 bytes` | Set a real key: `openssl rand -hex 32`. |
| Video token request returns `503` | `AGORA_APP_ID` / `AGORA_APP_CERTIFICATE` not set. Add them to `backend/.env` (or skip — everything else works). |
| Admin login: "Admin access is required" | The user's `role` is not `admin`. Promote it (step 3). |
| Mobile can't reach the API | Use `10.0.2.2` on Android emulator, `127.0.0.1` on iOS simulator, or your LAN IP on a physical device — not `localhost`. |
| `MissingPluginException` / camera not working on mobile | Native config from step 5 not applied, or app not restarted after `flutter create .`. |

---

## 9. Verifying each app compiles

```bash
# Backend
cd backend && npm run typecheck

# Admin web
cd admin && npm run build

# Mobile
cd mobile && flutter analyze
```
