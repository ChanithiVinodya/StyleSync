# Project Requests & Room Uploads — Student 2

Build here:
- `Models/` — your entities (e.g. `ProjectRequest`, room details, preferences)
- `Data/` — `IEntityTypeConfiguration<T>` classes for EF Core
- `Controllers/` — your API endpoints (create request, validate, trigger AI workflow)
- `Services/` — business logic, including the call to the AI service (`ai-service`)

This component kicks off the Agentic AI workflow — see `docs/architecture.md`.

**Reminder:** add your `DbSet<T>` line to `AppDbContext.cs` under the
"Project Requests" section only.
