# Quotes & Contracts — Student 3

Build here:
- `Models/` — your entities (e.g. `Quote`, `QuoteItem`, `Contract`)
- `Data/` — `IEntityTypeConfiguration<T>` classes for EF Core
- `Controllers/` — your API endpoints (view quote, approve, create contract)
- `Services/` — quote generation logic, contract creation logic

This component consumes the Budget/Scope Agent's output and creates the
contract only after client approval (never automatically).

**Reminder:** add your `DbSet<T>` line to `AppDbContext.cs` under the
"Quotes & Contracts" section only.
