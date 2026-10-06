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

### Run & Save Evidence Reports

The performance test outputs and summary json files can be saved directly to [testing/evidence/performance/](file:///c:/Users/Chani/Desktop/stylesync-skeleton/testing/evidence/performance/):

```powershell
# 1. Designers Directory Load Test (PF-01)
k6 run -e BASE_URL="http://localhost:5000" --summary-export=testing/evidence/performance/pf-01-summary.json testing/perf/designers-load.js | Tee-Object -FilePath testing/evidence/performance/pf-01-summary.txt

# 2. Designers Directory Stress Test (PF-02)
k6 run -e BASE_URL="http://localhost:5000" --summary-export=testing/evidence/performance/pf-02-summary.json testing/perf/designers-stress.js | Tee-Object -FilePath testing/evidence/performance/pf-02-summary.txt

# 3. Authenticated Project Requests Load Test (PF-03)
k6 run -e BASE_URL="http://localhost:5000" -e LOGIN_EMAIL="admin@stylesync.com" -e LOGIN_PASSWORD="Admin@StyleSync2026!" --summary-export=testing/evidence/performance/pf-03-summary.json testing/perf/requests-load.js | Tee-Object -FilePath testing/evidence/performance/pf-03-summary.txt

# 4. Authentication Login Load Test (PF-04)
k6 run -e BASE_URL="http://localhost:5000" --summary-export=testing/evidence/performance/pf-04-summary.json testing/perf/login-load.js | Tee-Object -FilePath testing/evidence/performance/pf-04-summary.txt
```
