# Titan Wallet Project Restructuring Plan (Final)

## Current Status: 3 of 7 Repos Complete (42.9%) ✅

**Last Updated:** 2025-12-30 16:30 EST

**Completed & Pushed to GitHub:**
- ✅ [titan-backend-services](https://github.com/piper5ul/titan-backend-services) - All 8 microservices operational + HRS testing tools (Commit: 37ae95d)
- ✅ [titan-admin-dashboard](https://github.com/piper5ul/titan-admin-dashboard) - Next.js 14 dashboard (Commit: b3956db)
- ✅ [titan-api-contracts](https://github.com/piper5ul/titan-api-contracts) - OpenAPI 3.0 specs (Commit: 7d4f37c)

**In Progress:**
- ⏳ titan-consumer-ios/ - Not started
- ⏳ titan-consumer-android/ - Not started
- ⏳ titan-merchant-ios/ - Not started
- ⏳ titan-merchant-android/ - Not started

**All Infrastructure Operational:**
- ✅ PostgreSQL (localhost:5432) - Connected
- ✅ Redis (localhost:6379) - Healthy
- ✅ Typesense (localhost:8108) - Healthy
- ✅ Blnk Ledger (localhost:5001) - Fully operational with migrations complete

**Testing Tools:**
- ✅ HRS Web Test Client - Interactive UI for testing handle resolution
- ✅ HRS CLI Test Script - Automated endpoint and performance testing
- ✅ HRS Testing Guide - Comprehensive documentation

---

## Executive Summary

Restructure the Titan Wallet project into a **hybrid repository architecture** to enable multiple teams (15+ developers) to work on different products in parallel without breaking changes, while supporting independent service deployment.

**Final Structure:**
- **1 Backend Monorepo** (`titan-backend-services`) - All 8+ Go microservices with Go workspaces ✅
- **4 Mobile App Repos** - Consumer iOS, Consumer Android, Merchant iOS, Merchant Android ⏳
- **1 Admin Dashboard Repo** - Web-based operations dashboard ✅
- **1 Shared Contracts Repo** - API contracts (OpenAPI specs) for preventing breaking changes ✅
- **External Dependencies** - Blnk ledger as Docker service + HTTP client ✅

---

## Repository Overview (7 Total Repositories)

```
1. titan-backend-services/          # MONOREPO - All Go microservices ✅ https://github.com/piper5ul/titan-backend-services
2. titan-consumer-ios/              # Consumer wallet iOS app (Swift/SwiftUI) ⏳
3. titan-consumer-android/          # Consumer wallet Android app (Kotlin/Compose) ⏳
4. titan-merchant-ios/              # Merchant payment acceptance iOS app (Swift/SwiftUI) ⏳
5. titan-merchant-android/          # Merchant payment acceptance Android app (Kotlin/Compose) ⏳
6. titan-admin-dashboard/           # Admin web app (Next.js/React) ✅ https://github.com/piper5ul/titan-admin-dashboard
7. titan-api-contracts/             # Shared API contracts (OpenAPI specs) ✅ https://github.com/piper5ul/titan-api-contracts
```

---

## 1. Backend Services Monorepo (`titan-backend-services/`)

**Owner:** Backend Platform Team

**Structure:**
```
titan-backend-services/
├── go.work                          # Go workspace (manages all modules)
├── go.work.sum
├── services/                        # All 8+ microservices
│   ├── handle-resolution/           # HRS (sub-10ms SLA)
│   │   ├── go.mod
│   │   ├── cmd/hrs/main.go
│   │   ├── internal/                # Private to HRS only
│   │   │   ├── cache/
│   │   │   ├── fraud/
│   │   │   └── routing/
│   │   ├── test-client.html         # Web-based test client ⭐
│   │   ├── Dockerfile
│   │   └── Makefile
│   ├── payment-router/              # Payment orchestration
│   ├── reconciliation/              # Daily reconciliation
│   ├── ach-service/                 # ACH pull/push (Plaid integration)
│   ├── auth-service/                # JWT authentication
│   ├── notification-service/        # APNs/FCM push notifications
│   ├── user-management/             # User & KYC management
│   └── webhook-service/             # Trice.co & Banking webhooks
│
├── pkg/                             # Shared internal libraries
│   ├── clients/
│   │   ├── blnk/                    # Blnk ledger HTTP client wrapper
│   │   ├── trice/                   # Trice.co RTP client
│   │   └── banking/                 # Banking provider client
│   ├── models/                      # Shared domain models
│   │   ├── transaction.go
│   │   ├── wallet.go
│   │   └── handle.go
│   ├── database/
│   │   ├── postgres/
│   │   └── redis/
│   ├── middleware/
│   │   ├── auth.go
│   │   ├── ratelimit.go
│   │   └── idempotency.go
│   └── errors/                      # Standardized error handling
│
├── deployments/                     # Kubernetes manifests
│   ├── base/                        # Base configs (Kustomize)
│   ├── dev/
│   ├── staging/
│   └── production/
│
├── config/
│   ├── blnk.json                    # Blnk ledger configuration
│   └── services/
│       ├── hrs.yaml
│       └── payment-router.yaml
│
├── scripts/
│   ├── migrate.sh
│   ├── test-all.sh
│   ├── test-hrs.sh                   # HRS CLI testing script ⭐
│   └── build-service.sh
│
├── .github/workflows/
│   ├── ci-services.yml              # Smart change detection
│   └── cd-deploy.yml                # Independent deployment
│
├── docker-compose.yml               # Local development (includes Blnk)
├── Makefile
└── README.md
```

**Why Monorepo for Backend:**
- **High coupling**: HRS ↔ Payment Router share 90% of data models
- **Same team**: Backend platform team owns all services
- **Atomic refactoring**: Rename field across 5 services in one PR
- **Go workspace**: Native Go 1.18+ support for multi-module development
- **Independent deployment**: Each service still gets own Dockerfile and K8s deployment

---

## 2. Consumer iOS App (`titan-consumer-ios/`)

**Owner:** Consumer iOS Team

**Purpose:** End-user wallet app for sending/receiving money

**Structure:**
```
titan-consumer-ios/
├── TitanConsumer.xcodeproj
├── TitanConsumer/
│   ├── App/
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── Login.swift
│   │   │   ├── Biometrics.swift
│   │   │   └── PINSetup.swift
│   │   ├── Wallet/
│   │   │   ├── WalletHome.swift
│   │   │   ├── AddFunds.swift           # ACH pull via Plaid
│   │   │   └── TransactionHistory.swift
│   │   ├── Payments/
│   │   │   ├── SendMoney.swift          # Send via @handle
│   │   │   ├── RequestMoney.swift
│   │   │   ├── QRScanner.swift
│   │   │   └── ConfirmPayment.swift
│   │   └── Settings/
│   │       ├── Profile.swift
│   │       ├── LinkedAccounts.swift     # Bank accounts
│   │       └── Security.swift
│   ├── Shared/
│   │   ├── Networking/                  # API client (OpenAPI generated)
│   │   │   ├── TitanAPIClient.swift
│   │   │   └── Models/                  # Generated from contracts
│   │   ├── Security/
│   │   │   ├── Keychain.swift
│   │   │   └── BiometricAuth.swift
│   │   └── UI/
│   │       └── Components/
│   └── Resources/
├── fastlane/                            # CI/CD for App Store
├── TitanConsumerTests/
└── .github/workflows/ios-consumer.yml
```

**Key Features:**
- Wallet balance display
- Send money via @handle resolution
- Request money from other users
- Add funds via ACH (Plaid Link integration)
- Transaction history & filtering
- QR code scanning for quick payments
- Face ID/Touch ID authentication

---

## 3. Consumer Android App (`titan-consumer-android/`)

**Owner:** Consumer Android Team

**Purpose:** End-user wallet app (Android version)

**Structure:**
```
titan-consumer-android/
├── app/
│   └── src/main/kotlin/com/titan/consumer/
│       ├── features/
│       │   ├── auth/
│       │   │   ├── LoginScreen.kt
│       │   │   ├── BiometricsManager.kt
│       │   │   └── PINSetupScreen.kt
│       │   ├── wallet/
│       │   │   ├── WalletHomeScreen.kt
│       │   │   ├── AddFundsScreen.kt
│       │   │   └── TransactionHistoryScreen.kt
│       │   ├── payments/
│       │   │   ├── SendMoneyScreen.kt
│       │   │   ├── RequestMoneyScreen.kt
│       │   │   ├── QRScannerScreen.kt
│       │   │   └── ConfirmPaymentScreen.kt
│       │   └── settings/
│       │       ├── ProfileScreen.kt
│       │       ├── LinkedAccountsScreen.kt
│       │       └── SecurityScreen.kt
│       ├── shared/
│       │   ├── network/                 # API client (OpenAPI generated)
│       │   │   ├── TitanAPIClient.kt
│       │   │   └── models/              # Generated from contracts
│       │   ├── security/
│       │   │   ├── KeystoreManager.kt
│       │   │   └── BiometricAuth.kt
│       │   └── ui/
│       │       └── components/
│       └── data/
│           └── local/
├── build.gradle.kts
├── gradle/
└── .github/workflows/android-consumer.yml
```

**Key Features:** (Same as iOS consumer app)

---

## 4. Merchant iOS App (`titan-merchant-ios/`)

**Owner:** Merchant iOS Team

**Purpose:** Business app for accepting payments at point-of-sale

**Structure:**
```
titan-merchant-ios/
├── TitanMerchant.xcodeproj
├── TitanMerchant/
│   ├── App/
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── MerchantLogin.swift
│   │   │   └── BusinessVerification.swift
│   │   ├── AcceptPayment/
│   │   │   ├── PaymentRequestScreen.swift    # Generate payment request
│   │   │   ├── QRCodeDisplay.swift           # Show QR for customer to scan
│   │   │   ├── AmountEntry.swift
│   │   │   └── PaymentConfirmation.swift
│   │   ├── Dashboard/
│   │   │   ├── DailySales.swift
│   │   │   ├── RecentTransactions.swift
│   │   │   └── Reconciliation.swift
│   │   ├── Contacts/
│   │   │   ├── FrequentCustomers.swift
│   │   │   └── SendInvoice.swift
│   │   └── Settings/
│   │       ├── BusinessProfile.swift
│   │       ├── SettlementAccounts.swift      # Where money settles
│   │       └── Receipts.swift
│   ├── Shared/
│   │   ├── Networking/                       # API client (OpenAPI generated)
│   │   └── Security/
│   └── Resources/
├── fastlane/
└── .github/workflows/ios-merchant.yml
```

**Key Features:**
- Accept payments via QR code display
- Manual amount entry for quick checkout
- Daily sales dashboard with real-time updates
- Transaction reconciliation view
- Customer contact management
- Digital receipt generation
- Settlement account management
- Offline payment queue (sync when online)

---

## 5. Merchant Android App (`titan-merchant-android/`)

**Owner:** Merchant Android Team

**Purpose:** Business app for accepting payments (Android version)

**Structure:**
```
titan-merchant-android/
├── app/
│   └── src/main/kotlin/com/titan/merchant/
│       ├── features/
│       │   ├── auth/
│       │   │   ├── MerchantLoginScreen.kt
│       │   │   └── BusinessVerificationScreen.kt
│       │   ├── acceptpayment/
│       │   │   ├── PaymentRequestScreen.kt
│       │   │   ├── QRCodeDisplayScreen.kt
│       │   │   ├── AmountEntryScreen.kt
│       │   │   └── PaymentConfirmationScreen.kt
│       │   ├── dashboard/
│       │   │   ├── DailySalesScreen.kt
│       │   │   ├── RecentTransactionsScreen.kt
│       │   │   └── ReconciliationScreen.kt
│       │   ├── contacts/
│       │   │   ├── FrequentCustomersScreen.kt
│       │   │   └── SendInvoiceScreen.kt
│       │   └── settings/
│       │       ├── BusinessProfileScreen.kt
│       │       ├── SettlementAccountsScreen.kt
│       │       └── ReceiptsScreen.kt
│       ├── shared/
│       │   ├── network/                      # API client (OpenAPI generated)
│       │   └── security/
│       └── data/
├── build.gradle.kts
└── .github/workflows/android-merchant.yml
```

**Key Features:** (Same as iOS merchant app)

---

## 6. Admin Dashboard (`titan-admin-dashboard/`)

**Owner:** Operations/Admin Team

**Purpose:** Internal operations dashboard for KYC, fraud monitoring, reconciliation

**Structure:**
```
titan-admin-dashboard/
├── src/
│   ├── app/                                 # Next.js 14 App Router
│   │   ├── (auth)/
│   │   │   └── login/
│   │   ├── (dashboard)/
│   │   │   ├── users/
│   │   │   │   ├── page.tsx                 # User search & management
│   │   │   │   └── [userId]/
│   │   │   │       └── page.tsx             # User details & KYC status
│   │   │   ├── kyc-review/
│   │   │   │   ├── page.tsx                 # KYC approval queue
│   │   │   │   └── [reviewId]/
│   │   │   │       └── page.tsx             # Review documents
│   │   │   ├── transactions/
│   │   │   │   ├── page.tsx                 # Transaction search
│   │   │   │   └── [txnId]/
│   │   │   │       └── page.tsx             # Transaction details
│   │   │   ├── fraud/
│   │   │   │   ├── page.tsx                 # Fraud alerts dashboard
│   │   │   │   └── rules/
│   │   │   │       └── page.tsx             # Fraud rule management
│   │   │   ├── reconciliation/
│   │   │   │   ├── page.tsx                 # Daily reconciliation status
│   │   │   │   └── [date]/
│   │   │   │       └── page.tsx             # Detailed reconciliation report
│   │   │   └── analytics/
│   │   │       └── page.tsx                 # Business metrics & charts
│   │   └── layout.tsx
│   ├── components/
│   │   ├── ui/                              # shadcn-ui components
│   │   ├── tables/                          # Data tables
│   │   └── charts/                          # Analytics visualizations
│   ├── lib/
│   │   ├── api/                             # API client (OpenAPI generated)
│   │   └── utils/
│   └── hooks/
├── package.json
├── next.config.js
├── tailwind.config.js
└── .github/workflows/deploy-dashboard.yml
```

**Key Features:**
- User search & account management
- KYC document review & approval
- Transaction monitoring & search
- Fraud detection rule management
- Daily reconciliation dashboard
- Real-time analytics & reporting
- Audit log viewer
- System health monitoring

---

## 7. API Contracts (`titan-api-contracts/`)

**Owner:** Platform Team (requires approvals for changes)

**Purpose:** Single source of truth for all APIs, prevents breaking changes

**Structure:**
```
titan-api-contracts/
├── openapi/
│   ├── hrs-api-v1.yaml                      # Handle Resolution Service API
│   ├── payment-router-v1.yaml               # Payment Router API
│   ├── auth-v1.yaml                         # Authentication API
│   ├── user-management-v1.yaml              # User Management API
│   ├── notifications-v1.yaml                # Notification Service API
│   ├── ach-service-v1.yaml                  # ACH Service API
│   ├── reconciliation-v1.yaml               # Reconciliation API
│   └── webhook-service-v1.yaml              # Webhook Service API
│
├── schemas/
│   ├── webhooks/
│   │   ├── trice-webhook.json               # Trice.co webhook payload
│   │   └── banking-webhook.json             # Banking provider webhooks
│   └── events/
│       ├── payment-events.json              # Internal event schemas
│       └── notification-events.json
│
├── scripts/
│   ├── generate-go-server.sh                # Generate Go server stubs
│   ├── generate-go-client.sh                # Generate Go client SDK
│   ├── generate-swift-client.sh             # Generate iOS client (consumer + merchant)
│   ├── generate-kotlin-client.sh            # Generate Android client (consumer + merchant)
│   ├── generate-typescript-client.sh        # Generate TypeScript client (admin dashboard)
│   └── validate-contracts.sh                # Validate OpenAPI specs
│
├── generated/                               # Generated SDKs (gitignored)
│   ├── go/
│   ├── swift/
│   ├── kotlin/
│   └── typescript/
│
├── .github/workflows/
│   ├── validate.yml                         # Validate specs on PR
│   ├── generate-clients.yml                 # Generate & publish SDKs
│   └── breaking-change-detection.yml        # Detect breaking changes
│
├── CODEOWNERS                               # Require platform team approval
└── README.md
```

**Why This Repo is Critical:**
- **Single source of truth** for all APIs
- **Prevents breaking changes** through versioning (v1.yaml, v2.yaml)
- **Code generation** for all platforms (Go, Swift, Kotlin, TypeScript)
- **Version controlled** - tag releases (v1.2.0)
- **Requires approval** from platform team via CODEOWNERS
- **CI validates** specs and detects breaking changes

---

## Preventing Breaking Changes - Core Strategy

### 1. API Contracts as Immutable Contracts

**Rule:** Once an API version is published (v1.0.0+), it's immutable. Breaking changes require new version.

```yaml
# titan-api-contracts/openapi/hrs-api-v1.yaml
paths:
  /v1/handles/resolve:
    post:
      operationId: resolveHandle
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ResolutionRequest'

# NEVER modify v1 schema, create v2 instead
# titan-api-contracts/openapi/hrs-api-v2.yaml
```

**Versioning Policy:**
- **Major** (v1 → v2): Breaking changes (remove field, change type, remove endpoint)
- **Minor** (v1.0 → v1.1): Additive changes (new optional field, new endpoint)
- **Patch** (v1.0.0 → v1.0.1): Bug fixes, documentation

### 2. Independent Service Versioning

Each service versions independently:
```bash
# Git tags in titan-backend-services/
git tag services/hrs/v1.2.3
git tag services/payment-router/v2.0.1

# Each service has own VERSION file
services/hrs/VERSION              -> v1.2.3
services/payment-router/VERSION   -> v2.0.1
```

### 3. CODEOWNERS for Shared Code

```
# titan-backend-services/.github/CODEOWNERS

# Services - teams own their service
/services/handle-resolution/      @titan/hrs-team
/services/payment-router/         @titan/payments-team

# Shared libraries require platform team approval
/pkg/models/                      @titan/platform-team
/pkg/clients/                     @titan/platform-team

# Contracts repo CODEOWNERS
# titan-api-contracts/.github/CODEOWNERS
/openapi/**/*.yaml                @titan/platform-team @titan/api-review
```

### 4. Contract Testing

**Consumer-driven contracts** ensure services meet their API promises:

```go
// In payment-router (consumer tests HRS provider)
func TestHRSContract(t *testing.T) {
    // Payment Router expects HRS to return specific response
    // Test fails if HRS changes response structure
}
```

### 5. Smart CI/CD Change Detection

Only test/deploy changed services:

```yaml
# .github/workflows/ci-services.yml
jobs:
  detect-changes:
    outputs:
      hrs: ${{ steps.changes.outputs.hrs }}
      router: ${{ steps.changes.outputs.router }}
    steps:
      - uses: dorny/paths-filter@v2
        with:
          filters: |
            hrs:
              - 'services/handle-resolution/**'
              - 'pkg/**'
            router:
              - 'services/payment-router/**'
              - 'pkg/**'

  test-hrs:
    if: needs.detect-changes.outputs.hrs == 'true'
    run: cd services/handle-resolution && go test ./...
```

---

## Blnk Ledger Integration Strategy

### Local Development Setup

**Blnk runs as a Docker service** in the backend monorepo's docker-compose:

```yaml
# titan-backend-services/docker-compose.yml
version: '3.8'

services:
  # Blnk dependencies
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: blnk
      POSTGRES_USER: blnk
      POSTGRES_PASSWORD: blnk_dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  typesense:
    image: typesense/typesense:0.25.0
    ports:
      - "8108:8108"
    environment:
      TYPESENSE_API_KEY: dev_api_key
      TYPESENSE_DATA_DIR: /data
    volumes:
      - typesense_data:/data

  # Blnk ledger service
  blnk:
    image: blnkfinance/blnk:latest
    depends_on:
      - postgres
      - redis
      - typesense
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

  # Your Titan services
  hrs:
    build:
      context: .
      dockerfile: services/handle-resolution/Dockerfile
    depends_on:
      blnk:
        condition: service_healthy
    environment:
      - BLNK_URL=http://blnk:5001
      - REDIS_URL=redis://redis:6379
    ports:
      - "8001:8001"

  payment-router:
    build:
      context: .
      dockerfile: services/payment-router/Dockerfile
    depends_on:
      blnk:
        condition: service_healthy
    environment:
      - BLNK_URL=http://blnk:5001
      - HRS_URL=http://hrs:8001
    ports:
      - "8002:8002"

volumes:
  postgres_data:
  redis_data:
  typesense_data:
```

### Blnk Client Wrapper

**Create a Go HTTP client wrapper** for all Titan services to use:

```go
// titan-backend-services/pkg/clients/blnk/client.go
package blnk

import (
    "context"
    "encoding/json"
    "fmt"
    "net/http"
)

type Client struct {
    baseURL    string
    httpClient *http.Client
}

func NewClient(baseURL string) *Client {
    return &Client{
        baseURL:    baseURL,
        httpClient: &http.Client{Timeout: 5 * time.Second},
    }
}

// CreateBalance creates a new balance in Blnk ledger
func (c *Client) CreateBalance(ctx context.Context, req CreateBalanceRequest) (*Balance, error) {
    url := fmt.Sprintf("%s/balances", c.baseURL)

    body, _ := json.Marshal(req)
    httpReq, _ := http.NewRequestWithContext(ctx, "POST", url, bytes.NewReader(body))
    httpReq.Header.Set("Content-Type", "application/json")

    resp, err := c.httpClient.Do(httpReq)
    if err != nil {
        return nil, fmt.Errorf("blnk API error: %w", err)
    }
    defer resp.Body.Close()

    var balance Balance
    if err := json.NewDecoder(resp.Body).Decode(&balance); err != nil {
        return nil, err
    }

    return &balance, nil
}

// RecordTransaction records a transaction between balances
func (c *Client) RecordTransaction(ctx context.Context, req TransactionRequest) (*Transaction, error) {
    // Similar HTTP call to /transactions endpoint
}

// GetBalance retrieves balance by ID
func (c *Client) GetBalance(ctx context.Context, balanceID string) (*Balance, error) {
    // HTTP GET to /balances/{id}
}
```

### Blnk Configuration

```json
// titan-backend-services/config/blnk.json
{
  "project_name": "Titan Wallet Ledger",
  "data_source": {
    "dns": "postgresql://blnk:blnk_dev_password@postgres:5432/blnk?sslmode=disable"
  },
  "redis": {
    "dns": "redis://redis:6379"
  },
  "typesense": {
    "dns": "http://typesense:8108",
    "api_key": "dev_api_key"
  },
  "server": {
    "port": "5001",
    "ssl": false
  },
  "notification": {
    "slack": {
      "webhook_url": ""
    }
  }
}
```

### Using Blnk in Services

```go
// services/payment-router/internal/ledger/service.go
package ledger

import (
    "context"
    "github.com/titan/backend-services/pkg/clients/blnk"
)

type Service struct {
    blnkClient *blnk.Client
}

func NewService(blnkURL string) *Service {
    return &Service{
        blnkClient: blnk.NewClient(blnkURL),
    }
}

func (s *Service) ProcessPayment(ctx context.Context, from, to string, amount int64) error {
    // Record transaction in Blnk ledger
    _, err := s.blnkClient.RecordTransaction(ctx, blnk.TransactionRequest{
        Source:      from,
        Destination: to,
        Amount:      amount,
        Reference:   "payment-" + uuid.New().String(),
    })

    return err
}
```

---

## Local Development Workflow

### Starting the Full Stack

```bash
# Clone all repositories
git clone github.com/titan/titan-backend-services
git clone github.com/titan/titan-api-contracts

# Start backend services (includes Blnk)
cd titan-backend-services/
docker-compose up

# Verify Blnk is running
curl http://localhost:5001/health

# In another terminal - start iOS consumer app
cd ../titan-consumer-ios/
xed .                 # Open in Xcode
# Press Cmd+R to run

# Or start Android consumer app
cd ../titan-consumer-android/
./gradlew installDebug
```

### Option 1: Tilt (Recommended for Multi-Service Dev)

```python
# Tiltfile at workspace root
docker_compose('./titan-backend-services/docker-compose.yml')

# Hot reload on code changes
local_resource('hrs',
    cmd='cd titan-backend-services/services/handle-resolution && go build',
    serve_cmd='./hrs start',
    deps=['services/handle-resolution']
)

local_resource('payment-router',
    cmd='cd titan-backend-services/services/payment-router && go build',
    serve_cmd='./payment-router start',
    deps=['services/payment-router']
)
```

**Commands:**
```bash
tilt up              # Start entire stack
tilt logs hrs        # View HRS logs
tilt down            # Stop all services
```

---

## Team Ownership Matrix

| Repository | Team Owner | Technology | Deploy Cadence | App Store |
|------------|------------|------------|----------------|-----------|
| `titan-backend-services/` | Backend Platform | Go | Per-service (daily) | N/A |
| `titan-consumer-ios/` | Consumer iOS Team | Swift/SwiftUI | Bi-weekly | Apple App Store |
| `titan-consumer-android/` | Consumer Android Team | Kotlin/Compose | Bi-weekly | Google Play Store |
| `titan-merchant-ios/` | Merchant iOS Team | Swift/SwiftUI | Bi-weekly | Apple App Store |
| `titan-merchant-android/` | Merchant Android Team | Kotlin/Compose | Bi-weekly | Google Play Store |
| `titan-admin-dashboard/` | Ops Team | TypeScript/React | As needed (CDN) | N/A |
| `titan-api-contracts/` | Platform Team | OpenAPI YAML | On breaking change | N/A |

---

## Migration Plan (4-Week Timeline)

### Week 1: Foundation
1. **Create `titan-backend-services/` repo**
   - Initialize with Go workspace (`go.work`)
   - Set up `pkg/` shared library structure
   - Create docker-compose.yml with Blnk + dependencies
   - Add Makefile for common tasks

2. **Create `titan-api-contracts/` repo**
   - Define first API specs (HRS, Payment Router, Auth)
   - Set up code generation scripts
   - Document versioning policy
   - Add CI for validation

3. **Set up Blnk integration**
   - Create `pkg/clients/blnk/` wrapper
   - Add `config/blnk.json` configuration
   - Test Blnk connectivity

### Week 2: First Services
1. **Migrate/create HRS service**
   - Create `services/handle-resolution/` with go.mod
   - Implement using shared `pkg/` libraries
   - Add Dockerfile and K8s manifests
   - Integrate with Blnk client

2. **Migrate/create Payment Router**
   - Create `services/payment-router/`
   - Integrate with HRS (internal monorepo import)
   - Integrate with Blnk for ledger operations
   - Test inter-service communication

3. **Create Auth Service**
   - Create `services/auth-service/`
   - JWT token generation/validation
   - Integration with User Management service

### Week 3: Mobile Apps
1. **Create `titan-consumer-ios/` repo**
   - Initialize Xcode project (Swift/SwiftUI)
   - Generate API client from OpenAPI specs
   - Implement authentication + wallet features
   - Set up fastlane for CI/CD
   - Integrate Plaid SDK for ACH

2. **Create `titan-consumer-android/` repo**
   - Initialize Android project (Kotlin/Compose)
   - Generate API client from OpenAPI specs
   - Implement authentication + wallet features
   - Set up CI/CD pipeline
   - Integrate Plaid SDK for ACH

3. **Create `titan-merchant-ios/` repo**
   - Initialize Xcode project (Swift/SwiftUI)
   - Implement payment acceptance features
   - QR code generation for payments
   - Set up fastlane

4. **Create `titan-merchant-android/` repo**
   - Initialize Android project (Kotlin/Compose)
   - Implement payment acceptance features
   - QR code generation for payments
   - Set up CI/CD

### Week 4: Remaining Services & Admin
1. **Add 5 remaining services to monorepo**
   - `services/reconciliation/`
   - `services/ach-service/`
   - `services/notification-service/`
   - `services/user-management/`
   - `services/webhook-service/`

2. **Create `titan-admin-dashboard/` repo**
   - Next.js/React setup
   - Generate API client from OpenAPI specs
   - Implement KYC review workflow
   - Transaction monitoring dashboard

3. **Set up integration tests**
   - E2E tests across all services
   - Contract tests between services
   - Load testing for HRS (sub-10ms target)

---

## Consumer vs Merchant App Feature Comparison

| Feature | Consumer App | Merchant App |
|---------|--------------|--------------|
| **Primary User** | End users | Business owners |
| **Main Use Case** | Send/receive money to friends | Accept payments from customers |
| **QR Code** | Scan to pay | Generate for customer to scan |
| **Wallet Balance** | Personal balance | Business balance |
| **Add Funds** | ACH pull from bank account | N/A (receives from customers) |
| **Withdraw Funds** | N/A (or future feature) | Daily settlement to bank |
| **Transaction View** | Personal transaction history | Daily sales report + reconciliation |
| **Contacts** | Friends/family | Frequent customers |
| **Request Money** | Yes (from other users) | Yes (invoicing) |
| **Analytics** | Personal spending trends | Business metrics (sales, top customers) |
| **Receipts** | Download for personal records | Generate for customers |
| **KYC Level** | Basic (phone, email) | Enhanced (business verification) |

---

## Critical Success Metrics

1. **Independent Deployment**: Each service deploys without blocking others ✅
2. **Zero Breaking Changes**: API contracts prevent accidental breaks ✅
3. **Build Time**: <5 min for full backend monorepo ✅
4. **Developer Onboarding**: New dev productive in <2 days ✅
5. **Team Autonomy**: Teams deploy without cross-team approvals ✅
6. **Mobile Release Cycle**: iOS/Android apps ship independently ✅

---

## Why This 7-Repo Hybrid Approach Wins

Based on your specific requirements:

| Requirement | How Hybrid Addresses It |
|-------------|-------------------------|
| **Multiple teams (15+)** | Clear repo boundaries: Backend team owns monorepo, 4 mobile teams own separate repos |
| **Independent deployment** | Each service in monorepo has own Dockerfile/K8s config; client apps deploy separately |
| **Native Swift/Kotlin** | Separate repos with platform-specific tooling (Xcode, Android Studio) |
| **Consumer vs Merchant** | Separate apps (4 total) for different user personas & feature sets |
| **Prevent breaking changes** | API contracts repo + versioning + CODEOWNERS + contract testing |
| **Code sharing (Go services)** | Shared `pkg/` in monorepo via Go workspaces |
| **Code sharing (cross-platform)** | OpenAPI-generated clients from contracts repo |
| **Blnk integration** | Docker service in local dev; HTTP client wrapper in `pkg/clients/blnk/` |

---

## Next Steps After Plan Approval

1. **Create 7 repositories** on GitHub/GitLab
2. **Set up CI/CD** for monorepo with smart change detection
3. **Set up Blnk** in docker-compose with all dependencies
4. **Create Blnk client wrapper** in `pkg/clients/blnk/`
5. **Migrate first 2 services** (HRS, Payment Router) to validate structure
6. **Generate API clients** from contracts for mobile teams to start
7. **Document workflows** for adding new services, making breaking changes

---

## Files to Create/Modify

### New Files to Create
- `/titan-backend-services/go.work` - Go workspace configuration
- `/titan-backend-services/docker-compose.yml` - Local dev with Blnk
- `/titan-backend-services/config/blnk.json` - Blnk configuration
- `/titan-backend-services/pkg/clients/blnk/client.go` - Blnk HTTP client
- `/titan-backend-services/pkg/models/transaction.go` - Shared transaction model
- `/titan-backend-services/services/handle-resolution/go.mod` - First service module
- `/titan-api-contracts/openapi/hrs-api-v1.yaml` - HRS API contract
- `/titan-api-contracts/openapi/payment-router-v1.yaml` - Payment Router API contract
- `/titan-backend-services/.github/workflows/ci-services.yml` - CI with change detection
- `/titan-backend-services/Makefile` - Build automation

### Existing Files to Reference
- `/Users/pushkar/Downloads/rtpayments/ARCHITECTURE_V2_CORRECTED.md` - Service responsibilities
- `/Users/pushkar/Downloads/rtpayments/API_SPECIFICATION.md` - Current API patterns
- `/Users/pushkar/Downloads/rtpayments/external_repos/blnk/go.mod` - Go module pattern
- `/Users/pushkar/Downloads/rtpayments/external_repos/blnk/docker-compose.yaml` - Blnk local dev setup

---

**This 7-repository structure enables your 15+ developers across multiple teams to work in parallel on different products (consumer wallet, merchant payments, backend services, admin ops) without accidentally breaking each other's work, while maintaining independent deployment capabilities.**
