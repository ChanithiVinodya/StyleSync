# StyleSync Architecture & Authentication Guide

## Overview
StyleSync is a modern multi-tiered application designed for intelligent interior design styling and management.

- **Backend Web API**: .NET 8 Web API (`backend/src/StyleSync.Api`)
- **Frontend SPA**: React 18 + Vite + TypeScript (`frontend-react`)
- **AI Microservice**: FastAPI + LangGraph (`ai-service`)
- **Mobile Client**: Flutter application (`flutter-app`)

---

## Authentication Flow

### 1. Backend Authentication Architecture
- Built on JWT (JSON Web Tokens) using HMAC-SHA256 signing.
- Managed by `AuthService.cs` and `JwtService.cs`.
- Endpoints:
  - `POST /api/auth/register`: Creates a new user profile with hashed passwords.
  - `POST /api/auth/login`: Authenticates credentials and returns a signed JWT token with identity/role claims (`Admin`, `Designer`, `Client`).
  - `GET /api/auth/me`: Validates caller identity and returns the user context.

### 2. Frontend State & Route Guarding
- **`AuthContext.tsx`**: Provides centralized session state across all React components. Reads and persists JWT tokens in `localStorage`.
- **`ProtectedRoute.tsx`**: Route wrapper validating user session and role authorization. Redirects unauthorized users to `/unauthorized` or `/login`.
- **`authService.ts`**: Handles Axios API requests and interceptors, automatically attaching Bearer tokens to outbound requests.
- **`api.ts`**: Project Requests API client utilizing the token for secure multi-role access.

---

## Module Layout
- `modules/project-requests`: Client room styling request wizard, AI analysis visualization, and administrative review.
- `modules/designers`: Designer portfolio showcasing and inquiry.
- `modules/quotes-contracts`: Quotation estimation and contract management.
- `modules/project-execution`: Milestone tracking and delivery management.
