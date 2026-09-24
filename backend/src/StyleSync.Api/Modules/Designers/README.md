# Designer Portfolios & Listings — Student 1

Build here:
- `Models/` — your entities (e.g. `DesignerProfile`, portfolio items, styles, pricing)
- `Data/` — `IEntityTypeConfiguration<T>` classes for EF Core (auto-discovered by `AppDbContext`)
- `Controllers/` — your API endpoints (search/filter/sort/pagination, CRUD)
- `Services/` — business logic that doesn't belong directly in a controller

See `docs/architecture.md` and the project PRD for what this component needs to do.

**Reminder:** after adding an entity, add ONE `DbSet<T>` line to
`Common/Persistence/AppDbContext.cs` under the "Designers" section — don't
touch anyone else's lines.
