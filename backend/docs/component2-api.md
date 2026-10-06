# Component 2: Project Requests API

This document details the Project Requests API (Component 2), including endpoints, request parameters, common error codes, and the state machine representing request transitions.

## Endpoints

| Method | Endpoint | Description | Authorization |
|---|---|---|---|
| GET | `/requests` | Retrieve a paginated, sorted, and filtered list of project requests. | Client (own requests only) or Admin |
| POST | `/requests` | Create a new draft project request. | Client |
| GET | `/requests/{id}` | Retrieve details of a specific project request. | Client (if owner) or Admin |
| PUT | `/requests/{id}` | Update an existing draft request. | Client (owner only) |
| DELETE | `/requests/{id}` | Permanently delete a draft request and associated files. | Client (owner only) |
| POST | `/requests/{id}/images` | Upload room or moodboard images (requires multipart/form-data). | Client (owner only) |
| DELETE | `/requests/{id}/images/{imageId}` | Delete a specific room or moodboard image. | Client (owner only) |
| POST | `/requests/{id}/submit` | Validates strictly and transitions a Draft to Submitted. | Client (owner only) |
| POST | `/requests/{id}/cancel` | Cancels an active request. | Admin |
| POST | `/requests/{id}/flag` | Toggles the flagged status of a request for review. | Admin |
| GET | `/requests/analytics` | Retrieve aggregated metrics (total requests, average budget, counts by status/room type). | Admin |
| GET | `/palettes/presets` | List curated preset colour palettes. | Any Authenticated User |
| GET | `/palettes/generate` | Generate a 5-colour palette preview from a base hex colour. | Any Authenticated User |

## Query Parameters (`GET /requests`)

All parameters are optional.

- `search` (string): Text search across `ReferenceCode` and `Description`. For Admins, also searches client name/email.
- `status` (string[]): Filter by one or multiple `RequestStatus` values.
- `roomType` (string[]): Filter by one or multiple `RoomType` values.
- `minBudget` (decimal): Filter by minimum budget.
- `maxBudget` (decimal): Filter by maximum budget.
- `createdFrom` (date): Include requests created on or after this date.
- `createdTo` (date): Include requests created on or before this date.
- `isFlagged` (boolean): Filter flagged requests (Admin only).
- `sortBy` (string): Field to sort by. Allowed values: `createdAt`, `updatedAt`, `budget`, `status`, `roomSize`. (Default: `createdAt`)
- `sortDir` (string): Sort direction: `asc` or `desc`. (Default: `desc`)
- `page` (integer): Page number (1-indexed). (Default: `1`)
- `pageSize` (integer): Number of items per page. (Default: `10`, max `50`)

## Common Error Codes (Problem Details)

Validation errors are returned as a `ProblemDetails` response (HTTP 400) with a detailed `errors` array. Example `code` values include:

| Code | Description |
|---|---|
| `ROOM_TYPE_INVALID` | The provided room type enum value is not recognized. |
| `ROOM_TYPE_REQUIRED` | Room type is missing upon final submission. |
| `BUDGET_NOT_POSITIVE` | The budget must be greater than zero. |
| `BUDGET_BELOW_MIN` | Submission budget falls below the allowed threshold (e.g., 10,000). |
| `BUDGET_ABOVE_MAX` | Submission budget exceeds the maximum allowed limit. |
| `ROOM_SIZE_INVALID` | Room size must be between 1 and 10,000. |
| `DESCRIPTION_INVALID_LENGTH` | Description must be between 10 and 2000 characters. |
| `PALETTE_PRESET_UNKNOWN` | The provided preset ID does not exist in the catalogue. |
| `PALETTE_BASE_COLOUR_INVALID` | The generated base colour is not a valid 6-character hex. |
| `ROOM_PHOTO_REQUIRED` | Cannot submit without exactly one uploaded room photo. |

## Status Transitions

The request lifecycle follows a strict, enforced state machine. Status changes automatically write to the `RequestStatusHistory` and `RequestAuditLog`.

| From Status | To Status | Triggered By | Endpoint / Action |
|---|---|---|---|
| *(None)* | `Draft` | Client | `POST /requests` |
| `Draft` | `Submitted` | Client | `POST /requests/{id}/submit` |
| `Submitted` | `AIAnalysis` | System | AI Workflow (Starter) |
| `AIAnalysis` | `ProposalReady` | System | AI Workflow (Completion) |
| *Any non-terminal* | `Cancelled` | Admin | `POST /requests/{id}/cancel` |

*(Note: `Completed` and `Rejected` are terminal states. Cancellation is forbidden once a request is in a terminal state.)*
