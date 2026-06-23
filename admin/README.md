# Dr.Plus — Admin (Platform Control Hub)

Web dashboard for platform administrators, built with **React + TypeScript +
Vite**. Consumes the `/api/v1/admin/*` endpoints (all `admin`-role guarded).

## Features

1. **Provider verification** — review pending providers and their submitted
   documents, then approve (activates the account, marks documents reviewed) or
   reject. Filter by verification status.
2. **Commission controls** — set the platform-wide default commission, and set
   or clear per-provider overrides from each provider's profile.
3. **System metrics** — gross transaction volume, commission earned, platform
   wallet balances (available / pending / escrow + lifetime), and distributions
   for providers, users, appointments, payments, and withdrawal settlements.

## Architecture

```
src/
├── api/         # typed fetch client (JWT) + auth & admin endpoint wrappers
├── auth/        # AuthContext (admin-only sign-in, token persistence)
├── components/  # Layout (sidebar/topbar) + shared UI (cards, badges, panels)
├── pages/       # Login, Metrics, Providers (list), ProviderDetail, Commission
├── types/       # types aligned with the Node/Mongoose data layer
└── util/        # money/percent/date formatting
```

Money is handled in integer **minor units** (cents) end-to-end, matching the
backend wallet/appointment schemas.

## Running

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # tsc --noEmit && vite build
```

Configure the API base via `.env` (see `.env.example`); defaults to
`http://localhost:4000/api/v1`. Sign in with a user whose `role` is `admin`.
