# SpraydBack

Street art cataloging API built with Vapor (Swift) + PostgreSQL.

## Prerequisites

### Swift

Install Swift via the [Swift.org downloads page](https://www.swift.org/download/) or using Homebrew:

```bash
brew install swift
```

Requires Swift 6.0+. Verify your installation:

```bash
swift --version
```

### Vapor Toolbox (optional)

```bash
brew install vapor
```

### PostgreSQL

Install PostgreSQL via Homebrew:

```bash
brew install postgresql@17
brew services start postgresql@17
```

Create the database and user:

```bash
psql postgres
```

```sql
CREATE USER vapor WITH PASSWORD 'your_password';
CREATE DATABASE spraydback OWNER vapor;
GRANT ALL PRIVILEGES ON DATABASE spraydback TO vapor;
\q
```

## Configuration

Set the following environment variables before running:

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USERNAME=vapor
export DB_PASSWORD=your_password
export DB_NAME=spraydback
```

## Build & Run

```bash
swift build
swift run
```

The server starts on `http://localhost:8080`. Migrations run automatically on startup.

## Testing

```bash
swift test
```

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /art-items | All art items (with first image) |
| POST | /art-items | Create art item |
| GET | /art-items/:id | Single art item |
| POST | /art-items/:id/images | Upload image for item |
| GET | /artists | All artists |
| POST | /artists | Create artist |
| POST | /artists/:id/avatar | Upload artist avatar |
| GET | /categories | All categories |
| POST | /categories | Create category |

API requests can be tested using the Bruno collection in the `bruno/` directory.

## Links

- [Vapor Documentation](https://docs.vapor.codes)
- [Fluent Documentation](https://docs.vapor.codes/fluent/overview/)
