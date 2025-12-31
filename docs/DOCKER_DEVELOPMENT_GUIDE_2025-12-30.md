# Docker Development Guide

**Last Updated:** 2025-12-30

## Overview

All Titan Wallet backend services run in Docker for local development. This ensures:
- **Consistent environment** across all 15+ developers
- **Fast onboarding** - New developers productive in <30 minutes
- **Easy testing** - Spin up services in isolation or all together
- **Quick reset** - Fresh start with one command
- **No local installation** - Only Docker required (no Go, PostgreSQL, Redis, etc.)
- **CI/CD match** - Same Docker images used in staging/production

---

## Architecture

### What Runs in Docker

```
Docker Compose Stack:
├── Infrastructure Layer
│   ├── PostgreSQL (port 5432)       # Blnk's database
│   ├── Redis (port 6379)            # Caching & queues
│   └── Typesense (port 8108)        # Search engine
│
├── External Services
│   └── Blnk Ledger (port 5001)      # Double-entry ledger API
│
└── Titan Microservices
    ├── HRS (port 8001)              # Handle Resolution Service
    ├── Payment Router (port 8002)    # Payment orchestration
    ├── ACH Service (port 8003)       # Plaid integration
    ├── Auth Service (port 8004)      # JWT authentication
    ├── Notification (port 8005)      # APNs/FCM push
    ├── User Management (port 8006)   # KYC & profiles
    ├── Webhook Service (port 8007)   # Inbound webhooks
    └── Reconciliation (port 8008)    # Daily reconciliation
```

### What Runs Natively

```
Native Development:
├── iOS Apps (Xcode)
│   ├── Consumer App → Connects to localhost:8004 (Docker)
│   └── Merchant App → Connects to localhost:8004 (Docker)
│
├── Android Apps (Android Studio)
│   ├── Consumer App → Connects to 10.0.2.2:8004 (Docker via emulator)
│   └── Merchant App → Connects to 10.0.2.2:8004 (Docker via emulator)
│
└── Admin Dashboard (Next.js)
    └── npm run dev → Connects to localhost:8004 (Docker)
```

---

## Complete docker-compose.yml Structure

Located at: `titan-backend-services/docker-compose.yml`

```yaml
version: '3.8'

services:
  # ========================================
  # Infrastructure Layer
  # ========================================

  postgres:
    image: postgres:15
    container_name: titan-postgres
    environment:
      POSTGRES_DB: blnk
      POSTGRES_USER: blnk
      POSTGRES_PASSWORD: blnk_dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./scripts/init-db.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U blnk"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: titan-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  typesense:
    image: typesense/typesense:0.25.0
    container_name: titan-typesense
    ports:
      - "8108:8108"
    environment:
      TYPESENSE_API_KEY: dev_api_key_12345
      TYPESENSE_DATA_DIR: /data
    volumes:
      - typesense_data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8108/health"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ========================================
  # External Services - Blnk Ledger
  # ========================================

  blnk:
    image: blnkfinance/blnk:latest
    container_name: titan-blnk
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      typesense:
        condition: service_healthy
    ports:
      - "5001:5001"
    volumes:
      - ./config/blnk.json:/blnk.json
    environment:
      - CONFIG_FILE=/blnk.json
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # ========================================
  # Titan Microservices
  # ========================================

  hrs:
    build:
      context: .
      dockerfile: services/handle-resolution/Dockerfile
    container_name: titan-hrs
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    ports:
      - "8001:8001"
    environment:
      - SERVICE_NAME=hrs
      - PORT=8001
      - REDIS_URL=redis://redis:6379
      - POSTGRES_URL=postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable
      - LOG_LEVEL=debug
      - CACHE_TTL=300s
    volumes:
      - ./services/handle-resolution:/app  # For hot reload (optional)
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  payment-router:
    build:
      context: .
      dockerfile: services/payment-router/Dockerfile
    container_name: titan-payment-router
    depends_on:
      blnk:
        condition: service_healthy
      hrs:
        condition: service_healthy
    ports:
      - "8002:8002"
    environment:
      - SERVICE_NAME=payment-router
      - PORT=8002
      - BLNK_URL=http://blnk:5001
      - HRS_URL=http://hrs:8001
      - TRICE_API_URL=https://sandbox.trice.co/api
      - TRICE_API_KEY=${TRICE_API_KEY}
      - REDIS_URL=redis://redis:6379
      - POSTGRES_URL=postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable
      - LOG_LEVEL=debug
    volumes:
      - ./services/payment-router:/app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8002/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  ach-service:
    build:
      context: .
      dockerfile: services/ach-service/Dockerfile
    container_name: titan-ach-service
    depends_on:
      blnk:
        condition: service_healthy
      payment-router:
        condition: service_healthy
    ports:
      - "8003:8003"
    environment:
      - SERVICE_NAME=ach-service
      - PORT=8003
      - BLNK_URL=http://blnk:5001
      - PAYMENT_ROUTER_URL=http://payment-router:8002
      - PLAID_CLIENT_ID=${PLAID_CLIENT_ID}
      - PLAID_SECRET=${PLAID_SECRET}
      - PLAID_ENV=sandbox
      - REDIS_URL=redis://redis:6379
      - POSTGRES_URL=postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable
      - LOG_LEVEL=debug
    volumes:
      - ./services/ach-service:/app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8003/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  auth-service:
    build:
      context: .
      dockerfile: services/auth-service/Dockerfile
    container_name: titan-auth-service
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "8004:8004"
    environment:
      - SERVICE_NAME=auth-service
      - PORT=8004
      - JWT_SECRET=dev_secret_change_in_production_123456789
      - JWT_EXPIRY=24h
      - REFRESH_TOKEN_EXPIRY=168h
      - REDIS_URL=redis://redis:6379
      - POSTGRES_URL=postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable
      - LOG_LEVEL=debug
    volumes:
      - ./services/auth-service:/app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8004/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  notification-service:
    build:
      context: .
      dockerfile: services/notification-service/Dockerfile
    container_name: titan-notification-service
    depends_on:
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
    ports:
      - "8005:8005"
    environment:
      - SERVICE_NAME=notification-service
      - PORT=8005
      - APNS_KEY_ID=${APNS_KEY_ID}
      - APNS_TEAM_ID=${APNS_TEAM_ID}
      - APNS_BUNDLE_ID=com.titan.consumer
      - APNS_ENV=sandbox
      - FCM_SERVER_KEY=${FCM_SERVER_KEY}
      - REDIS_URL=redis://redis:6379
      - POSTGRES_URL=postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable
      - LOG_LEVEL=debug
    volumes:
      - ./services/notification-service:/app
      - ./config/apns-key.p8:/apns-key.p8  # APNs certificate
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8005/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  user-management:
    build:
      context: .
      dockerfile: services/user-management/Dockerfile
    container_name: titan-user-management
    depends_on:
      postgres:
        condition: service_healthy
      blnk:
        condition: service_healthy
    ports:
      - "8006:8006"
    environment:
      - SERVICE_NAME=user-management
      - PORT=8006
      - BLNK_URL=http://blnk:5001
      - POSTGRES_URL=postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable
      - REDIS_URL=redis://redis:6379
      - LOG_LEVEL=debug
    volumes:
      - ./services/user-management:/app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8006/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  webhook-service:
    build:
      context: .
      dockerfile: services/webhook-service/Dockerfile
    container_name: titan-webhook-service
    depends_on:
      payment-router:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "8007:8007"
    environment:
      - SERVICE_NAME=webhook-service
      - PORT=8007
      - PAYMENT_ROUTER_URL=http://payment-router:8002
      - REDIS_URL=redis://redis:6379
      - POSTGRES_URL=postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable
      - WEBHOOK_SECRET=dev_webhook_secret_change_in_production
      - LOG_LEVEL=debug
    volumes:
      - ./services/webhook-service:/app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8007/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

  reconciliation:
    build:
      context: .
      dockerfile: services/reconciliation/Dockerfile
    container_name: titan-reconciliation
    depends_on:
      blnk:
        condition: service_healthy
      postgres:
        condition: service_healthy
    ports:
      - "8008:8008"
    environment:
      - SERVICE_NAME=reconciliation
      - PORT=8008
      - BLNK_URL=http://blnk:5001
      - POSTGRES_URL=postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable
      - REDIS_URL=redis://redis:6379
      - RECONCILIATION_SCHEDULE=0 2 * * *  # 2 AM daily
      - LOG_LEVEL=debug
    volumes:
      - ./services/reconciliation:/app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8008/health"]
      interval: 10s
      timeout: 5s
      retries: 3
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
  typesense_data:

networks:
  default:
    name: titan-network
```

---

## Environment Variables (.env file)

Create `.env` file in `titan-backend-services/`:

```bash
# Trice.co API (RTP Provider)
TRICE_API_KEY=sandbox_key_get_from_trice_dashboard

# Plaid (ACH Integration)
PLAID_CLIENT_ID=your_plaid_client_id
PLAID_SECRET=your_plaid_sandbox_secret

# APNs (iOS Push Notifications)
APNS_KEY_ID=your_apns_key_id
APNS_TEAM_ID=your_apple_team_id

# FCM (Android Push Notifications)
FCM_SERVER_KEY=your_firebase_server_key

# Note: Database credentials are hardcoded for local dev (not production)
```

---

## Daily Development Workflow

### 1. Start All Services (Full Stack)

```bash
cd titan-backend-services/

# Start everything
docker-compose up

# Or start in background
docker-compose up -d

# View logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f hrs
docker-compose logs -f payment-router
```

### 2. Start Specific Services Only

```bash
# Only infrastructure + Blnk
docker-compose up postgres redis typesense blnk

# Only HRS dependencies
docker-compose up postgres redis hrs

# Only payment flow
docker-compose up postgres redis typesense blnk hrs payment-router
```

### 3. Check Service Health

```bash
# Check all services status
docker-compose ps

# Expected output:
# NAME                  STATUS         PORTS
# titan-postgres        Up (healthy)   5432->5432
# titan-redis           Up (healthy)   6379->6379
# titan-blnk            Up (healthy)   5001->5001
# titan-hrs             Up (healthy)   8001->8001
# titan-payment-router  Up (healthy)   8002->8002
# ...

# Test individual endpoints
curl http://localhost:5001/health  # Blnk
curl http://localhost:8001/health  # HRS
curl http://localhost:8002/health  # Payment Router
```

### 4. View Logs

```bash
# All services
docker-compose logs

# Follow logs (real-time)
docker-compose logs -f

# Specific service
docker-compose logs -f hrs

# Last 100 lines
docker-compose logs --tail=100 payment-router

# Logs from last 5 minutes
docker-compose logs --since 5m
```

### 5. Restart After Code Changes

```bash
# Rebuild and restart specific service
docker-compose up --build hrs

# Restart without rebuild
docker-compose restart hrs

# Restart all
docker-compose restart
```

### 6. Stop Services

```bash
# Stop all (preserves data)
docker-compose stop

# Stop and remove containers (preserves data)
docker-compose down

# Nuclear option - delete all data
docker-compose down -v
```

### 7. Fresh Start (Clean Slate)

```bash
# Delete everything and start fresh
docker-compose down -v
docker-compose up --build
```

---

## Testing Workflows

### Integration Testing

```bash
# Terminal 1: Start services
docker-compose up -d

# Wait for health checks
sleep 10

# Terminal 2: Run tests
cd tests/integration/
go test -v ./...

# Cleanup
docker-compose down
```

### Load Testing HRS (Sub-10ms Target)

```bash
# Start HRS
docker-compose up -d redis postgres hrs

# Run load test
cd tests/load/
go run hrs_load_test.go

# Expected: P99 latency < 10ms
```

### Manual API Testing

```bash
# Start services
docker-compose up -d

# Create a user
curl -X POST http://localhost:8006/users \
  -H "Content-Type: application/json" \
  -d '{"phone": "+15555551234", "handle": "alice"}'

# Resolve handle
curl http://localhost:8001/handles/resolve?handle=alice

# Send payment
curl -X POST http://localhost:8002/payments \
  -H "Content-Type: application/json" \
  -d '{
    "from_handle": "alice",
    "to_handle": "bob",
    "amount": 5000,
    "currency": "USD"
  }'
```

---

## Mobile App Development

### iOS App Configuration

```swift
// TitanConsumer/Config/APIConfig.swift
struct APIConfig {
    #if DEBUG
    static let baseURL = "http://localhost:8004"  // Auth Service
    static let hrsURL = "http://localhost:8001"   // HRS
    #else
    static let baseURL = "https://api.titanwallet.com"
    #endif
}
```

**Workflow:**
```bash
# Terminal 1: Start backend
cd titan-backend-services/
docker-compose up -d

# Terminal 2: Run iOS app
cd titan-consumer-ios/
xed .  # Opens Xcode
# Press Cmd+R to run on simulator
```

### Android App Configuration

```kotlin
// app/src/main/kotlin/com/titan/consumer/Config.kt
object APIConfig {
    const val BASE_URL = if (BuildConfig.DEBUG) {
        "http://10.0.2.2:8004"  // Android emulator host
    } else {
        "https://api.titanwallet.com"
    }
}
```

**Workflow:**
```bash
# Terminal 1: Start backend
cd titan-backend-services/
docker-compose up -d

# Terminal 2: Run Android app
cd titan-consumer-android/
./gradlew installDebug
adb shell am start -n com.titan.consumer/.MainActivity
```

### Testing on Physical Devices

```bash
# Find your computer's IP address
ifconfig | grep "inet " | grep -v 127.0.0.1

# Example output: inet 192.168.1.100

# Update mobile app config
# iOS: http://192.168.1.100:8004
# Android: http://192.168.1.100:8004
```

---

## Admin Dashboard Development

```bash
# Terminal 1: Start backend services
cd titan-backend-services/
docker-compose up -d

# Terminal 2: Start admin dashboard
cd titan-admin-dashboard/
npm install
npm run dev

# Dashboard runs on http://localhost:3000
# Connects to Docker services on localhost:8004, 8006, etc.
```

---

## Advanced: Hot Reload Development

### Option 1: Air (Go Hot Reload Tool)

Install Air:
```bash
go install github.com/cosmtrek/air@latest
```

Update `docker-compose.yml`:
```yaml
hrs:
  build: ./services/handle-resolution
  volumes:
    - ./services/handle-resolution:/app
  command: air  # Instead of compiled binary
```

Create `.air.toml` in each service:
```toml
[build]
  cmd = "go build -o ./tmp/main cmd/hrs/main.go"
  bin = "tmp/main"
  include_ext = ["go", "yaml"]
  exclude_dir = ["tmp"]
```

**Workflow:**
```bash
docker-compose up hrs

# Edit services/handle-resolution/internal/handler.go
# Air detects change, rebuilds, restarts automatically
```

### Option 2: Local Go + Docker Dependencies

```bash
# Start only infrastructure
docker-compose up postgres redis typesense blnk

# Run HRS locally with hot reload
cd services/handle-resolution/
air

# Or manually
go run cmd/hrs/main.go
```

**Benefits:**
- Faster rebuilds (no Docker layer)
- Use Go debugger (Delve)
- IDE integration works better

---

## Helper Scripts

Create these in `titan-backend-services/scripts/`:

### start.sh
```bash
#!/bin/bash
echo "Starting Titan Wallet services..."
docker-compose up -d
echo "Waiting for services to be healthy..."
sleep 10
docker-compose ps
echo "✅ All services running!"
echo "Blnk:          http://localhost:5001"
echo "HRS:           http://localhost:8001"
echo "Payment Router: http://localhost:8002"
```

### reset.sh
```bash
#!/bin/bash
echo "⚠️  Resetting all data..."
docker-compose down -v
echo "Rebuilding services..."
docker-compose up --build -d
echo "✅ Fresh start complete!"
```

### logs.sh
```bash
#!/bin/bash
if [ -z "$1" ]; then
  docker-compose logs -f
else
  docker-compose logs -f "$1"
fi
```

### test.sh
```bash
#!/bin/bash
echo "Starting test environment..."
docker-compose up -d
sleep 10

echo "Running integration tests..."
go test -v ./tests/integration/...

echo "Running load tests..."
go test -v ./tests/load/...

echo "Cleanup..."
docker-compose down
```

**Make executable:**
```bash
chmod +x scripts/*.sh
```

**Usage:**
```bash
./scripts/start.sh
./scripts/logs.sh hrs
./scripts/reset.sh
./scripts/test.sh
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/integration-tests.yml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Set up Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'

      - name: Start Docker services
        run: docker-compose up -d

      - name: Wait for services
        run: |
          for i in {1..30}; do
            if curl -f http://localhost:8001/health; then
              echo "Services ready!"
              break
            fi
            echo "Waiting for services..."
            sleep 2
          done

      - name: Run integration tests
        run: go test -v ./tests/integration/...

      - name: Run load tests
        run: go test -v ./tests/load/...

      - name: Show logs on failure
        if: failure()
        run: docker-compose logs

      - name: Cleanup
        run: docker-compose down -v
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
docker --version

# Check for port conflicts
lsof -i :5432  # PostgreSQL
lsof -i :6379  # Redis
lsof -i :8001  # HRS

# Kill conflicting processes
kill -9 <PID>

# Clean Docker state
docker-compose down -v
docker system prune -a --volumes
```

### Service Stuck in "Starting"

```bash
# Check logs
docker-compose logs <service-name>

# Common issues:
# 1. Missing environment variable
# 2. Dependency not healthy
# 3. Port already in use

# Restart specific service
docker-compose restart <service-name>
```

### Database Connection Errors

```bash
# Verify PostgreSQL is running
docker-compose ps postgres

# Test connection
docker-compose exec postgres psql -U blnk -d blnk -c "SELECT 1;"

# Reset database
docker-compose down -v
docker-compose up -d postgres
```

### "Out of Memory" Errors

```bash
# Increase Docker memory limit
# Docker Desktop → Settings → Resources → Memory: 8GB

# Or limit services
docker-compose up postgres redis blnk hrs payment-router
```

### Hot Reload Not Working

```bash
# Check volume mounts
docker-compose config | grep volumes

# Restart with build
docker-compose up --build <service-name>

# Or use local development instead
docker-compose up postgres redis blnk
cd services/hrs && go run cmd/hrs/main.go
```

---

## Performance Optimization

### Faster Startup Times

```yaml
# Use BuildKit for faster builds
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Multi-stage builds in Dockerfile
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY . .
RUN go build -o hrs cmd/hrs/main.go

FROM alpine:latest
COPY --from=builder /app/hrs /usr/local/bin/
CMD ["hrs"]
```

### Reduce Rebuild Time

```yaml
# Cache Go modules
services:
  hrs:
    volumes:
      - go-mod-cache:/go/pkg/mod

volumes:
  go-mod-cache:
```

---

## Security Notes

### Development vs Production

**Development (docker-compose.yml):**
- ✅ Hardcoded passwords (blnk_dev_password)
- ✅ All ports exposed
- ✅ Debug logging enabled
- ✅ No TLS/SSL
- ✅ Permissive CORS

**Production (Kubernetes):**
- 🔒 Secrets from vault
- 🔒 Internal networking only
- 🔒 Minimal logging
- 🔒 TLS everywhere
- 🔒 Strict CORS

### Never Commit

```bash
# .gitignore
.env
config/*.p8        # APNs certificates
config/*.json      # Blnk config with credentials
docker-compose.override.yml
```

---

## Summary

### Quick Commands Reference

| Task | Command |
|------|---------|
| Start all services | `docker-compose up -d` |
| View logs | `docker-compose logs -f` |
| View specific logs | `docker-compose logs -f hrs` |
| Restart service | `docker-compose restart hrs` |
| Rebuild service | `docker-compose up --build hrs` |
| Stop all | `docker-compose stop` |
| Delete everything | `docker-compose down -v` |
| Check status | `docker-compose ps` |
| Test endpoint | `curl http://localhost:8001/health` |

### Port Reference

| Service | Port | URL |
|---------|------|-----|
| PostgreSQL | 5432 | postgresql://localhost:5432 |
| Redis | 6379 | redis://localhost:6379 |
| Typesense | 8108 | http://localhost:8108 |
| Blnk Ledger | 5001 | http://localhost:5001 |
| HRS | 8001 | http://localhost:8001 |
| Payment Router | 8002 | http://localhost:8002 |
| ACH Service | 8003 | http://localhost:8003 |
| Auth Service | 8004 | http://localhost:8004 |
| Notification | 8005 | http://localhost:8005 |
| User Management | 8006 | http://localhost:8006 |
| Webhook Service | 8007 | http://localhost:8007 |
| Reconciliation | 8008 | http://localhost:8008 |

---

**With this Docker setup, your entire team can be productive on day one with just `docker-compose up`!**
