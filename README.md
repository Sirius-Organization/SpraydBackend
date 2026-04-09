# SpraydBack

Street art cataloging API built with Vapor (Swift) + PostgreSQL.

## Running with Docker (recommended)

This is the standard way to run the app both locally and on production. Docker packages the app and PostgreSQL together — no need to install Swift or PostgreSQL on the host.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (macOS) or Docker Engine + Docker Compose plugin (Ubuntu)

### Setup

Create a `.env` file in the project root (never commit this):

```bash
DB_PASSWORD=your_secret_password
# Optional overrides (these are the defaults):
# DB_USERNAME=vapor
# DB_NAME=spraydback
# LOG_LEVEL=debug
```

### Start

```bash
docker compose up --build
```

- First run builds the image (takes a few minutes — Swift compilation).
- Subsequent starts reuse the cached image; add `--build` only when you change code.
- The API is available at `http://localhost:8080/api/v1`.
- PostgreSQL data is persisted in a Docker volume (`db_data`) and survives restarts.

### Stop

```bash
docker compose down          # stop containers, keep DB data
docker compose down -v       # stop containers AND wipe DB data
```

### Rebuild after code changes

```bash
docker compose up --build
```

### View logs

```bash
docker compose logs -f app   # app logs
docker compose logs -f db    # postgres logs
```

### Connect to the database (for debugging)

```bash
docker compose exec db psql -U vapor -d spraydback
```

---

## Production deployment (Ubuntu server)

### 1. Install Docker on the server

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in for the group change to take effect
```

### 2. Copy files to the server

From your local machine, push just the files Docker needs:

```bash
rsync -av --exclude='.build' --exclude='.git' \
  ./ user@your-server:/opt/spraydback/
```

Or clone the repo directly on the server:

```bash
git clone https://github.com/your-org/SpraydBack /opt/spraydback
```

### 3. Create the `.env` file on the server

```bash
cd /opt/spraydback
cat > .env <<EOF
DB_PASSWORD=strong_production_password
DB_USERNAME=vapor
DB_NAME=spraydback
LOG_LEVEL=info
EOF
chmod 600 .env
```

### 4. Build and start

```bash
cd /opt/spraydback
docker compose up --build -d
```

The `-d` flag runs everything in the background. The API is on port 8080.

### 5. Verify it's running

```bash
docker compose ps
curl http://localhost:8080/api/v1/art-items
```

### 6. Set up auto-start on reboot

Docker Compose services restart automatically if you add `restart: unless-stopped` to the services in `docker-compose.yml`. To add it:

```bash
# In docker-compose.yml, add under each service:
#   restart: unless-stopped
docker compose up -d
```

### 7. Deploy updates

```bash
cd /opt/spraydback
git pull
docker compose up --build -d
```

---

## Cleanup: removing the old local setup

If you were previously running Vapor and PostgreSQL directly on macOS via Homebrew, clean up as follows.

### Stop and remove PostgreSQL

```bash
brew services stop postgresql@17
brew uninstall postgresql@17
rm -rf ~/Library/Application\ Support/PostgreSQL
rm -rf /usr/local/var/postgresql@17   # Intel Mac
rm -rf /opt/homebrew/var/postgresql@17  # Apple Silicon Mac
```

### Remove the Vapor toolbox (optional)

```bash
brew uninstall vapor
```

### Remove environment variables

If you added DB_ exports to `~/.zshrc` or `~/.zprofile`, remove those lines:

```bash
# Remove lines like:
# export DB_HOST=localhost
# export DB_PORT=5432
# export DB_USERNAME=vapor
# export DB_PASSWORD=...
# export DB_NAME=spraydback
```

---

## Running locally without Docker

### Prerequisites

- Swift 6.0+ — install via [Swift.org](https://www.swift.org/download/) or `brew install swift`
- PostgreSQL — `brew install postgresql@17 && brew services start postgresql@17`

### Database setup

```bash
psql postgres
```

```sql
CREATE USER vapor WITH PASSWORD 'your_password';
CREATE DATABASE spraydback OWNER vapor;
GRANT ALL PRIVILEGES ON DATABASE spraydback TO vapor;
CREATE DATABASE spraydback_test OWNER vapor;
GRANT ALL PRIVILEGES ON DATABASE spraydback_test TO vapor;
\q
```

### Run

```bash
export DB_PASSWORD=your_password
swift run
```

The server starts on `http://localhost:8080/api/v1`. Migrations run automatically.

### Test

```bash
swift test
```

---

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/v1/art-items | All art items (with first image) |
| POST | /api/v1/art-items | Create art item |
| GET | /api/v1/art-items/:id | Single art item |
| POST | /api/v1/art-items/:id/images | Upload image for item |
| GET | /api/v1/artists | All artists |
| POST | /api/v1/artists | Create artist |
| POST | /api/v1/artists/:id/avatar | Upload artist avatar |
| GET | /api/v1/categories | All categories |
| POST | /api/v1/categories | Create category |

API requests can be tested using the Bruno collection in the `bruno/` directory.

## Links

- [Vapor Documentation](https://docs.vapor.codes)
- [Fluent Documentation](https://docs.vapor.codes/fluent/overview/)
