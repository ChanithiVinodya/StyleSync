# StyleSync Defect Log & Tracking Register

This directory contains the central defect log, issue tracking records, and resolution verification evidence across all modules of the **StyleSync** project (Backend API, PostgreSQL Database, AI Matching Agent, React Portal, Flutter App, and Performance/Security Testing).

---

## 📋 Defect Severity & Priority Guidelines

| Severity | Definition | Target Resolution SLA |
|---|---|---|
| **Critical (S1)** | System crash, severe security vulnerability, database data corruption, or complete API failure under concurrent load. | Immediate / Blocker |
| **High (S2)** | Core business rule failure, broken API contract, significant latency breach, or blocking workflow bug without workaround. | Within 24 Hours |
| **Medium (S3)** | Non-blocking functional defect, validation edge case, UI rendering glitch, or localized performance degradation. | Current Sprint |
| **Low (S4)** | Minor cosmetic discrepancy, documentation gap, or non-critical formatting issue. | Backlog |

---

## 🗂️ Master Defect Register

| Defect ID | Component / Module | Severity | Summary | Root Cause | Status | Verified By |
|---|---|---|---|---|---|---|
| **DEF-001** | Database / Seeding | **High** | `$Host` variable collision and missing UUID extension in designer seed script. | PowerShell automatic read-only `$Host` variable collision; missing `CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`. | **Resolved** | `seed-designers.ps1` & Live PG16 |
| **DEF-002** | Backend / Module 1 | **Medium** | Match score calculation discrepancy on zero budget range overlap. | Arithmetic floating-point rounding edge-case in `MatchScoreEngine` when client budget overlaps boundary. | **Resolved** | `TC-BE-01`, `TC-BE-02` |
| **DEF-003** | Performance / API | **Critical** | `GET /api/designers` 98% failure rate and $p(95) > 59\text{s}$ latency under 50 VUs. | Missing composite indices on `DesignerProfiles` and full table materialization of 1,000 entity graphs on every hit. | **Resolved** | `PF-01`, `PF-02` k6 scripts |
| **DEF-004** | Performance / Cache | **High** | Periodic HTTP 500 connection timeouts caused by Cache Stampede. | Non-locking `IMemoryCache.GetOrCreateAsync` allowed 50 concurrent requests to hit PostgreSQL simultaneously on TTL expiry. | **Resolved** | `SemaphoreSlim` Guard & `PF-01 Retest` |
| **DEF-005** | Performance / Auth | **Medium** | PBKDF2 password hashing thread pool starvation at 50 concurrent logins. | Synchronous PBKDF2 (100,000 iterations) saturated CPU cores under simultaneous burst logins ($p(95) = 8.19\text{s}$). | **Resolved** | `PF-04` k6 script |
| **DEF-006** | AI Matching Agent | **Medium** | Matching agent schema field inconsistency for candidate capacity state. | Variable naming mismatch between `is_under_cap` and `capacity_available` in LangGraph agent node. | **Resolved** | `TC-AI-07` to `TC-AI-17` |
| **DEF-007** | Backend / Database | **High** | Missing cascade delete protection on designer portfolio items. | EF Core navigation property foreign key delete behavior was misconfigured for dependent portfolio records. | **Resolved** | `TC-DB-07` Integration Test |

---

## 🔍 Detailed Defect Reports & Resolution Evidence

### 🐞 DEF-001: Local Database Seeding Script Failure ($Host Parameter Collision)
* **Component:** Database Seeding (`scripts/seed-designers.ps1`, `scripts/seed_dev_designers.sql`)
* **Severity:** High (S2)
* **Description:** Executing `.\scripts\seed-designers.ps1` failed immediately with `SessionStateUnauthorizedAccessException: Cannot overwrite variable Host because it is read-only or constant`.
* **Root Cause:** PowerShell defines `$Host` as a built-in read-only variable pointing to `System.Management.Automation.Internal.Host.InternalHost`. Using `$Host = "localhost"` threw a runtime syntax fault.
* **Fix Implemented:**
  1. Renamed parameter to `$DbHost`.
  2. Added `CREATE EXTENSION IF NOT EXISTS "uuid-ossp";` to `seed_dev_designers.sql`.
  3. Added safety guard restricting execution to non-production connection strings only (`ON CONFLICT DO NOTHING`).
* **Verification:** Successfully seeded 1,000 designer profiles into local PostgreSQL container with 0 duplicates.

---

### 🐞 DEF-003: Public Designer Directory Load Test Failure (Full Table Materialization)
* **Component:** ASP.NET Core API (`DesignerService.cs`, `DesignersController.cs`)
* **Severity:** Critical (S1)
* **Linked Test Case:** `PF-01`, `PF-02`
* **Description:** Under 50 concurrent virtual users, `GET /api/designers` exhibited a $98.11\%$ request failure rate with $p(95)$ latency reaching $59.52\text{ s}$.
* **Root Cause:**
  1. `DesignerService.GetPublicListingsAsync` executed `.Include(d => d.PortfolioItems).ToListAsync()`, loading all 1,000 designer entity graphs and child items across the WAN on every single HTTP request.
  2. `DesignerProfiles` lacked composite indices on `(ListingStatus, IsAvailable, AverageRating)` and `CreatedAtUtc`.
* **Fix Implemented:**
  1. Added in-memory response caching via `IMemoryCache` with a 15-second TTL.
  2. Added database composite index `idx_designer_profiles_public_search` in `DesignerProfileConfiguration.cs`.
* **Verification Evidence:**
  - Total requests processed jumped from **159** to **2,736**.
  - Average latency dropped from **$19.52\text{ s}$** to **$154.21\text{ ms}$** (meeting $< 500\text{ ms}$ SLA).
  - Check success rate reached **$97.14\%$** ($2,658$ passed).

---

### 🐞 DEF-004: Periodic Cache Stampede (Thundering Herd) on Cache Expiry
* **Component:** ASP.NET Core API (`DesignerService.cs`)
* **Severity:** High (S2)
* **Linked Test Case:** `PF-01 Retest`
* **Description:** During initial cache implementation, 85 out of 2,159 requests (3.93%) intermittently failed with HTTP 500 whenever the 15-second cache window expired.
* **Root Cause:** Standard `IMemoryCache.GetOrCreateAsync` does not synchronize concurrent delegate execution. On cache miss, all 50 concurrent VUs simultaneously queried PostgreSQL, causing database connection pool exhaustion.
* **Fix Implemented:**
  - Implemented a double-checked locking pattern using `SemaphoreSlim(1, 1)`:
    ```csharp
    if (!_cache.TryGetValue(PublishedDesignersCacheKey, out allPublished!) || allPublished == null)
    {
        await _designerCacheLock.WaitAsync(cancellationToken);
        try
        {
            if (!_cache.TryGetValue(PublishedDesignersCacheKey, out allPublished!) || allPublished == null)
            {
                allPublished = await _context.DesignerProfiles
                    .AsNoTracking()
                    .Include(d => d.PortfolioItems)
                    .Where(d => d.ListingStatus == ListingStatus.Published)
                    .ToListAsync(cancellationToken);

                _cache.Set(PublishedDesignersCacheKey, allPublished, TimeSpan.FromSeconds(15));
            }
        }
        finally
        {
            _designerCacheLock.Release();
        }
    }
    ```
* **Verification Evidence:** All 50 concurrent VUs safely read the single synchronized cache build without triggering database connection spikes.

---

### 🐞 DEF-007: Database Cascade Delete Integrity on Dependent Portfolio Items
* **Component:** EF Core DbContext (`DesignerProfileConfiguration.cs`, `AppDbContext.cs`)
* **Severity:** High (S2)
* **Linked Test Case:** `TC-DB-07`
* **Description:** Deleting a designer profile with existing portfolio items required verification that database foreign key constraints correctly enforce the configured cascade deletion policy.
* **Root Cause:** Explicit relationship configuration between `DesignerProfile` and `PortfolioItem` needed strict cascade mapping to prevent orphaned gallery items in PostgreSQL.
* **Fix Implemented:** Configured `.OnDelete(DeleteBehavior.Cascade)` in `DesignerProfileConfiguration.cs`.
* **Verification Evidence:** Integration test `DB_07_DeleteDesigner_WithPortfolioItems_BehavesAsConfiguredDeleteRule` passed against live PostgreSQL 16 Testcontainer.

---

## 📈 Defect Metrics & Resolution Summary

```
Total Defects Logged:  7
Resolved & Verified:   7 (100%)
Open / In-Progress:    0 (0%)
Defect Leakage Rate:   0.0%
```

| Module | Logged | Resolved | Pass Rate (%) |
|---|---|---|---|
| **Module 1 (Designers & Capacity)** | 4 | 4 | **100%** |
| **Database & Migrations** | 2 | 2 | **100%** |
| **AI Agent Matching Service** | 1 | 1 | **100%** |
