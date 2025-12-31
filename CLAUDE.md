# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

**Titan Wallet** is a real-time payments platform with a hybrid monorepo/multi-repo architecture consisting of 7 main repositories:

### Active Development Repositories (3/7 Complete)
1. ✅ **titan-backend-services/** - Go microservices monorepo (8 services) - [GitHub](https://github.com/piper5ul/titan-backend-services)
2. ✅ **admin-dashboard/** - Next.js 14 admin dashboard - [GitHub](https://github.com/piper5ul/titan-admin-dashboard)
3. ✅ **api-contracts/** - OpenAPI 3.0 specifications - [GitHub](https://github.com/piper5ul/titan-api-contracts)
4. ⏳ **titan-consumer-ios/** - Swift/SwiftUI consumer wallet app
5. ⏳ **titan-consumer-android/** - Kotlin/Jetpack Compose consumer wallet app
6. ⏳ **titan-merchant-ios/** - Swift/SwiftUI merchant payment acceptance app
7. ⏳ **titan-merchant-android/** - Kotlin/Jetpack Compose merchant payment acceptance app

### External Dependencies (Reference/Integration)
- **external_repos/blnk/** - Go-based double-entry ledger (core financial engine)
- **external_repos/stack/** - Formance Stack for ledger and payments
- **external_repos/consumer-pay-mobile-app/** - React/TypeScript reference app
- **external_repos/merchant-mobile-app/** - React/TypeScript reference app

All project files are located in `/Users/pushkar/Downloads/rtpayments/`

## Architecture

### Titan Backend Services (Go Microservices Monorepo) ✅ OPERATIONAL

The core platform consists of 8 microservices running in Docker containers:

**Services:**
1. **Handle Resolution Service (HRS)** - Port 8001 - Sub-10ms SLA for @handle resolution
2. **Payment Router** - Port 8002 - Orchestrates payment flows between services
3. **ACH Service** - Port 8003 - Plaid integration for ACH pull/push operations
4. **Auth Service** - Port 8004 - JWT authentication with Redis token management
5. **Notification Service** - Port 8005 - APNs/FCM push notifications
6. **User Management** - Port 8006 - KYC verification and user data management
7. **Webhook Service** - Port 8007 - Handles Trice.co RTP and banking webhooks
8. **Reconciliation** - Port 8008 - Daily reconciliation engine with Blnk ledger

**Shared Infrastructure:**
- PostgreSQL (localhost:5432) - Primary data store for all services
- Redis (localhost:6379) - Caching and session management
- Typesense (localhost:8108) - Search engine for handle resolution
- Blnk Ledger (localhost:5001) - Double-entry accounting system

**Technology Stack:**
- Language: Go 1.21+
- Framework: Gorilla Mux (HTTP routing)
- Database: PostgreSQL with pgx driver
- Cache: Redis
- Search: Typesense
- Deployment: Docker Compose with healthchecks

**Shared Packages (pkg/):**
- `pkg/logger` - Standardized logging (Infof, Errorf, Warnf, Fatalf)
- `pkg/database` - PostgreSQL and Redis clients
- `pkg/encryption` - AES-256-GCM encryption for PII
- `pkg/clients/blnk` - Blnk ledger HTTP client wrapper
- `pkg/models` - Shared domain models (Handle, Payment, User)
- `pkg/errors` - Standardized error handling

**Development Commands:**
```bash
cd titan-backend-services

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f [service-name]

# Check service health
curl http://localhost:8001/health  # HRS
curl http://localhost:8002/health  # Payment Router
# ... (ports 8003-8008 for other services)

# Stop all services
docker-compose down

# Rebuild specific service
docker-compose build [service-name]
docker-compose up -d [service-name]
```

**Important Notes:**
- Uses `docker-compose.override.yml` to connect to local PostgreSQL instead of Docker postgres
- All services use `host.docker.internal` to access host machine's postgres
- Blnk requires database migrations: `docker exec titan-blnk /usr/local/bin/blnk migrate up`
- Configuration managed via environment variables and `config/blnk-local.json`

**Testing HRS Service:**
```bash
cd titan-backend-services

# Option 1: Web-based test client (Interactive UI)
open services/handle-resolution/test-client.html

# Option 2: CLI test script (Automated testing)
./scripts/test-hrs.sh

# Option 3: Manual curl tests
curl http://localhost:8001/health
curl -X POST http://localhost:8001/handles \
  -H "Content-Type: application/json" \
  -d '{"handle":"alice","user_id":"user_123","account_id":"acct_456"}'
curl "http://localhost:8001/handles/resolve?handle=alice"
```

**Testing Guide:** See [docs/HRS_TESTING_GUIDE.md](docs/HRS_TESTING_GUIDE.md) for comprehensive testing instructions.

### Blnk Ledger (Go) - External Dependency
The foundational financial ledger providing:
- Double-entry accounting system
- Balance management with monitoring and snapshots
- Transaction processing (inflight, bulk, backdated, scheduled)
- Reconciliation engine with custom matching rules
- Identity management with PII tokenization
- Webhook-based event notifications

**Technology Stack:**
- Language: Go
- Database: PostgreSQL
- Cache/Queue: Redis (with Asynq for async tasks)
- Search: Typesense
- API: REST (HTTP server on port 5001 by default)

**Key Packages:**
- `cmd/` - CLI entry points (server, workers, migrations)
- `api/` - HTTP handlers and middleware
- `database/` - PostgreSQL data layer
- `model/` - Core domain models
- `internal/` - Shared utilities (cache, hooks, tokenization, search, etc.)
- `sql/` - SQL migration files

### Formance Stack (Go)
Modular platform for complex money flows:
- Formance Ledger - Programmable double-entry ledger
- Formance Payments - Unified payments API
- Formance Numscript - DSL for monetary computations

**Technology Stack:**
- Language: Go
- Database: PostgreSQL
- Messaging: Kafka/NATS
- Gateway: Traefik

### Mobile Applications (React + TypeScript)
Both consumer and merchant apps built with:
- **Framework:** Vite + React 18 + TypeScript
- **UI:** shadcn-ui components with Radix UI primitives
- **Styling:** Tailwind CSS
- **State:** Zustand (consumer app), React Hook Form
- **Routing:** React Router v6
- **Data Fetching:** TanStack Query
- **Additional:**
  - Merchant app includes Capacitor for native Android support
  - Merchant app uses Supabase backend

## Development Commands

### Blnk Ledger

```bash
cd external_repos/blnk

# Install dependencies
make init
go get ./...

# Run tests
make test
go test -short ./...

# Build
make build                  # Creates ./blnk binary
go build -o blnk ./cmd/*.go

# Run server (requires blnk.json config)
make run
./blnk start

# Run workers
make run_workers
./blnk workers

# Database migrations
make migrate_up
./blnk migrate up

make migrate_down
./blnk migrate down

# Docker (requires Docker Compose)
docker compose up           # Start all services
make docker_run            # Run pre-built image
```

**Configuration:** Requires `blnk.json` in root with PostgreSQL, Redis, and Typesense connection strings.

### Consumer Pay Mobile App

```bash
cd external_repos/consumer-pay-mobile-app

# Install dependencies
npm i

# Development server
npm run dev

# Production build
npm run build

# Development build
npm run build:dev

# Lint
npm run lint

# Preview production build
npm run preview
```

### Merchant Mobile App

```bash
cd external_repos/merchant-mobile-app

# Install dependencies
npm i

# Development server
npm run dev

# Production build
npm run build

# Development build
npm run build:dev

# Lint
npm run lint

# Preview production build
npm run preview

# Capacitor commands (for Android build)
# Run via @capacitor/cli if needed
```

### Formance Stack

```bash
cd external_repos/stack

# The stack is deployed via Kubernetes/Helm
# For cloud sandbox testing, use fctl CLI:
brew tap formancehq/tap
brew install fctl

fctl login
fctl stack create <name>
fctl ledger send world foo 100 EUR/2 --ledger=demo
fctl ui
```

## Key Concepts

### Blnk Transaction Flow
1. Create ledger(s) to organize accounts
2. Create balances within ledgers
3. Record transactions between balances
4. Transactions can be:
   - Immediate or scheduled
   - Inflight (held then committed/voided)
   - Bulk operations
   - Multi-destination (1-to-many)
   - Backdated

### Identity & Balance Linking
- Identities store PII with tokenization
- Link identities to balances for KYC/compliance
- Supports balance monitoring and webhooks

### Reconciliation
- Match external records (bank statements) to internal ledger
- Custom matching rules and strategies
- Automatic reconciliation workflows

## Testing

### Blnk
```bash
# Run all tests
go test ./...

# Run short tests (skips integration tests)
go test -short ./...

# Test specific package
go test ./database/...
go test ./api/...
```

### Mobile Apps
Both apps use ESLint for linting. No test runner configured by default.

```bash
npm run lint
```

## Project Structure Notes

### Blnk Internal Organization
- Core business logic in root `.go` files (balance.go, transaction.go, etc.)
- HTTP layer in `api/` with corresponding `*_api_test.go` files
- Database operations in `database/` package
- Models define data structures in `model/`
- Internal packages provide cross-cutting concerns

### Mobile App Structure
Both apps follow similar patterns:
- `src/components/` - React components (UI primitives in `ui/` subdirectory)
- `src/pages/` - Top-level route components
- `src/hooks/` - Custom React hooks
- `src/store/` - State management (Zustand stores)
- `src/lib/` - Utility functions

Consumer app has modular component structure with `auth/`, `modals/`, and `tabs/` subdirectories.

Merchant app has flatter structure with standalone feature components (AcceptPayment, Contacts, Profile, etc.).

## Important Patterns

### Blnk Configuration
All services require a `blnk.json` configuration file with:
- PostgreSQL connection (data_source.dns)
- Redis connection (redis.dns)
- Typesense connection (typesense.dns)
- Server port (server.port)
- Optional: TokenizationSecret for PII encryption

### API Error Handling
Blnk uses `internal/apierror` package for consistent error responses.

### Webhook Events
Blnk sends webhooks via the notification system. Register webhook URLs in configuration or via API.

### Balance Tracking
The BalanceTracker (`bt`) maintains in-memory state for concurrent balance updates, preventing race conditions.

## Additional Resources

- Blnk Documentation: https://docs.blnkfinance.com
- Formance Documentation: https://docs.formance.com
- Blnk uses Apache License 2.0
- Mobile apps built with Lovable (lovable.dev)
