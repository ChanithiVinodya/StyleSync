# Backend Setup — ASP.NET Core Web API

## Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- Docker Engine/CLI (for PostgreSQL) — or a locally installed PostgreSQL 16.
- (Optional) `dotnet-ef` global tool: `dotnet tool install --global dotnet-ef`

> **Windows users:** the easiest way to get the `docker` CLI is
> [Docker Desktop](https://www.docker.com/products/docker-desktop/) with
> the **WSL2 backend** enabled (Docker Desktop will prompt you to enable
> this on first run if it's not already on). All commands below are the
> same whether you run them in PowerShell, Command Prompt, or a Linux
> terminal — `dotnet` and `docker` are cross-platform CLIs, not shell
> scripts.

## First-time setup

```bash
# From the repo root - start Postgres database via Docker Compose
docker compose up -d

cd backend
dotnet restore
```

Check `src/StyleSync.Api/appsettings.json` — the default connection
string already matches `docker-compose.yml`'s credentials, so you shouldn't
need to change anything for local dev.

**Managing the database container:**
- **Start:** `docker compose up -d`
- **Stop:** `docker compose stop` (or `docker compose down`)
- **Reset database & volume:** `docker compose down -v`
- **View DB logs:** `docker compose logs -f postgres`

## Create the initial migration (first person to do this, only once)

```bash
cd backend/src/StyleSync.Api
dotnet ef migrations add InitialCreate --output-dir Common/Persistence/Migrations
dotnet ef database update
```

> **Migration coordination rule:** only one person should have an
> in-flight, un-merged migration at a time. If you need a new migration,
> check with the team first, `git pull` the latest `main`, then run
> `dotnet ef migrations add <Name>`. This avoids two people generating
> conflicting migration files.

## Run the API

> **First time only, Windows:** if your browser complains about an
> untrusted HTTPS certificate when you open the API/Swagger URL, run:
> ```
> dotnet dev-certs https --trust
> ```
> and click "Yes" on the popup. This is a one-time step per machine.

```bash
cd backend/src/StyleSync.Api
dotnet run
```

- API: `http://localhost:5000`
- Swagger UI (dev only): `http://localhost:5000/swagger`
- Health check: `http://localhost:5000/health`

## Run tests

```bash
cd backend
dotnet test
```

## Adding your own component's code

1. Work inside your module folder only:
   `src/StyleSync.Api/Modules/<YourComponent>/`
2. Add entity configs as `IEntityTypeConfiguration<T>` classes in your
   module's `Data/` folder — `AppDbContext` auto-discovers them, so you
   normally don't need to edit `AppDbContext.cs` except to add one new
   `DbSet<T>` line.
3. Don't reformat or reorder other students' lines in shared files
   (`AppDbContext.cs`, `Program.cs`) — only add your own line.
