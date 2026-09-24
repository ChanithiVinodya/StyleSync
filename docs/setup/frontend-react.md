# Frontend Setup — React (Vite + TypeScript)

## Prerequisites

- Node.js 20+
- npm 10+

## First-time setup

```bash
cd frontend-react
npm install
```

Copy the env template and adjust `VITE_API_BASE_URL` if your backend runs
elsewhere:

- **macOS/Linux:** `cp .env.example .env`
- **Windows (PowerShell):** `Copy-Item .env.example .env`

## Run the dev server

```bash
npm run dev
```

App runs at `http://localhost:5173` by default. Make sure the backend is
running first (`http://localhost:5000`) — see `docs/setup/backend.md`.

## Run tests

```bash
npm run test
```

## Lint

```bash
npm run lint
```

## Build for production

```bash
npm run build
```

## Adding your own component's code

Work inside `src/modules/<your-component>/`. Add API calls in that folder
using the shared `apiClient` from `src/shared/api/client.ts` — don't
duplicate base URL / auth header logic per module.
