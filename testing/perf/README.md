# StyleSync API Performance Testing with k6

This directory contains k6 load and stress testing scripts targeting the StyleSync ASP.NET Core API endpoints.

---

## 📁 Test Scripts Overview

| Script | Target Endpoint | Purpose | Load Profile / Stages | Thresholds |
|---|---|---|---|---|
| [`designers-load.js`](file:///c:/Users/Chani/Desktop/stylesync-skeleton/testing/perf/designers-load.js) | `GET /api/designers` | Load test public search & filtering with pagination | 30s → 20 VUs, 1m @ 50 VUs, 30s → 0 VUs | `http_req_failed < 1%`, `p(95) < 500ms` |
| [`designers-stress.js`](file:///c:/Users/Chani/Desktop/stylesync-skeleton/testing/perf/designers-stress.js) | `GET /api/designers` | Stress test public catalog beyond normal peak | Ramp up through 50, 100, 200 VUs | None (Stress breaking-point exploration) |
| [`requests-load.js`](file:///c:/Users/Chani/Desktop/stylesync-skeleton/testing/perf/requests-load.js) | `GET /api/requests` | Authenticated load test using Bearer JWT | `setup()` login once, 50 VUs sustained | `http_req_failed < 1%`, `p(95) < 500ms` |
| [`login-load.js`](file:///c:/Users/Chani/Desktop/stylesync-skeleton/testing/perf/login-load.js) | `POST /api/auth/login` | Authentication throughput & JWT issuance | 30s → 50 VUs, 1m @ 50 VUs, 30s → 0 VUs | `http_req_failed < 1%`, `p(95) < 500ms` |

---

## ⚙️ Environment Variables

Each script supports dynamic configuration via environment variables:

- `BASE_URL`: Base URL of the running API (Default: `http://localhost:5000`).
- `LOGIN_EMAIL`: Test user email for authentication (Default: `admin@stylesync.com`).
- `LOGIN_PASSWORD`: Test user password for authentication (Default: `Admin@StyleSync2026!`).

---

## 🚀 Execution Instructions

### Prerequisites
1. Ensure the StyleSync API backend is running (`dotnet run --project backend/src/StyleSync.Api`).
2. Ensure [k6](https://k6.io/) is installed.

### Run Individual Tests

```powershell
# 1. Designers Directory Load Test
k6 run -e BASE_URL="http://localhost:5000" testing/perf/designers-load.js

# 2. Designers Directory Stress Test
k6 run -e BASE_URL="http://localhost:5000" testing/perf/designers-stress.js

# 3. Authenticated Project Requests Load Test
k6 run -e BASE_URL="http://localhost:5000" -e LOGIN_EMAIL="admin@stylesync.com" -e LOGIN_PASSWORD="Admin@StyleSync2026!" testing/perf/requests-load.js

# 4. Authentication Login Load Test
k6 run -e BASE_URL="http://localhost:5000" testing/perf/login-load.js
```
