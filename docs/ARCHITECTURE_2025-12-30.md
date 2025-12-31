# Real-Time Payments Wallet - Architecture & Design Document

**Version:** 1.0
**Date:** December 29, 2025
**Status:** Design Phase

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture Overview](#system-architecture-overview)
3. [Technology Stack](#technology-stack)
4. [Ledger System: Blnk](#ledger-system-blnk)
5. [Handle Resolution Service](#handle-resolution-service)
6. [Payment Flow Designs](#payment-flow-designs)
7. [Multi-Currency Support](#multi-currency-support)
8. [Cryptocurrency Support](#cryptocurrency-support)
9. [FBO Account Structure](#fbo-account-structure)
10. [Security & Compliance](#security--compliance)
11. [Fraud Detection & Risk Management](#fraud-detection--risk-management)
12. [Deployment Architecture](#deployment-architecture)
13. [API Specifications](#api-specifications)
14. [Future Roadmap](#future-roadmap)

---

## Executive Summary

### Vision
Build a modern real-time payments wallet supporting fiat currencies, cryptocurrencies, and P2P transfers with a UPI/NPCI-inspired handle system for privacy and ease of use.

### Core Components
- **Blnk Ledger**: Double-entry accounting system for all balances and transactions
- **Handle Resolution Service (HRS)**: Privacy-preserving handle-to-wallet mapping with fraud detection
- **Mobile Apps**: Consumer and merchant-facing React/TypeScript applications
- **RTP Integration**: Real-time payment network connectivity
- **FBO Account**: For Benefit Of account structure for regulatory compliance

### Key Features
- ✅ P2P transfers via handles (e.g., @emily)
- ✅ Multi-currency support (fiat + crypto)
- ✅ Real-time settlements
- ✅ Built-in fraud detection
- ✅ Merchant payments (NFC/QR)
- ✅ Cross-network routing

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOBILE APPS                               │
│  ┌──────────────────────┐  ┌──────────────────────────────┐    │
│  │  Consumer Pay App    │  │   Merchant Mobile App        │    │
│  │  - P2P Transfers     │  │   - Accept Payments          │    │
│  │  - QR/NFC Pay        │  │   - Transaction History      │    │
│  │  - Multi-Currency    │  │   - Settlement Management    │    │
│  └──────────────────────┘  └──────────────────────────────┘    │
│         (React + TypeScript + Vite + shadcn-ui)                 │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       │ HTTPS/REST
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    API GATEWAY & SERVICES                        │
│  ┌────────────────────────────────────────────────────────┐    │
│  │  Transaction Orchestrator                              │    │
│  │  - Request validation                                  │    │
│  │  - Handle resolution                                   │    │
│  │  - Routing decisions                                   │    │
│  └────────────────┬───────────────────────────────────────┘    │
└────────────────────┼────────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────────┐
│    Handle    │ │     Blnk     │ │  RTP Integration │
│  Resolution  │ │    Ledger    │ │   - Provider API │
│   Service    │ │  - Balances  │ │   - Webhooks     │
│  (HRS)       │ │  - Txns      │ │   - Settlement   │
│              │ │  - Recon     │ │                  │
└──────┬───────┘ └──────┬───────┘ └──────────────────┘
       │                │
       │  PostgreSQL    │  PostgreSQL + Redis + Typesense
       ▼                ▼
┌──────────────┐ ┌──────────────┐
│  Handle DB   │ │  Blnk DB     │
│  - Registry  │ │  - Ledgers   │
│  - Risk      │ │  - Balances  │
│  - Limits    │ │  - Txns      │
└──────────────┘ └──────────────┘
```

---

## Technology Stack

### Backend Ledger
- **Blnk** (Go)
  - PostgreSQL for data persistence
  - Redis for caching and async job queues (Asynq)
  - Typesense for search
  - OpenTelemetry for tracing

### Handle Resolution Service
- **Language**: Go or Node.js/TypeScript
- **Database**: PostgreSQL (handle registry, risk profiles)
- **Cache**: Redis (handle lookups, rate limiting)
- **Messaging**: Kafka (event streaming for fraud detection)
- **ML Engine**: Python (fraud/risk scoring)

### Mobile Applications
- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite
- **UI Components**: shadcn-ui (Radix UI primitives)
- **Styling**: Tailwind CSS
- **State Management**:
  - Consumer App: Zustand
  - Merchant App: React Hook Form
- **Data Fetching**: TanStack Query
- **Routing**: React Router v6
- **Mobile**: Capacitor (Android for merchant app)

### Infrastructure
- **Deployment**: Docker Compose (dev), Kubernetes (production)
- **API Gateway**: Traefik or Kong
- **Monitoring**: Jaeger (tracing), Prometheus + Grafana (metrics)
- **CI/CD**: GitHub Actions

---

## Ledger System: Blnk

### Why Blnk?

#### Decision Matrix

| Requirement | Blnk | Formance | Decision |
|-------------|------|----------|----------|
| Time to Market | ✅ Days/Weeks | ⚠️ Weeks/Months | **Blnk** |
| FBO Reconciliation | ✅ Built-in | ⚠️ Separate service | **Blnk** |
| Multi-Currency | ✅ Native | ✅ Native | Tie |
| Crypto Support | ✅ Arbitrary precision | ✅ Supported | Tie |
| Infrastructure | ✅ Docker Compose | ❌ Kubernetes required | **Blnk** |
| Identity/KYC | ✅ Built-in PII tokenization | ⚠️ External needed | **Blnk** |
| Team Size | ✅ < 10 engineers | ⚠️ Needs DevOps | **Blnk** |

**Conclusion**: Start with Blnk for MVP. Evaluate Formance for multi-provider orchestration in Phase 2.

### Blnk Features Utilized

1. **Double-Entry Ledger**
   - All transactions follow accounting principles
   - Audit trail for compliance
   - Balance snapshots for historical reporting

2. **Multi-Currency with Exchange Rates**
   ```go
   transaction := {
     source: "user-a-usd",
     destination: "user-b-ngn",
     amount: 100.00,
     rate: 1500,  // 1 USD = 1500 NGN
     currency: "USD",
     precision: 100  // 2 decimal places
   }
   // Result: User A -$100, User B +150,000 NGN
   ```

3. **Inflight Transactions**
   - Perfect for pending RTP confirmations
   - Hold funds, then commit or void based on webhook
   ```go
   // Create inflight transaction
   txn := blnk.RecordTransaction({
     inflight: true,
     source: "user-wallet",
     destination: "external-rtp"
   })

   // On RTP success webhook
   blnk.CommitInflightTransaction(txn.ID)

   // On RTP failure
   blnk.VoidInflightTransaction(txn.ID)
   ```

4. **Identity Management**
   - PII tokenization (encrypt sensitive data)
   - Link identities to balances for KYC
   - Metadata for compliance fields

5. **Reconciliation Engine**
   - Match bank statements to ledger entries
   - Custom matching rules
   - Critical for FBO account compliance

6. **Precision Handling**
   - Uses Go's `big.Int` for arbitrary precision
   - Supports crypto (18 decimals for ETH)
   - No floating-point rounding errors

### Blnk Development Commands

```bash
cd external_repos/blnk

# Install dependencies
make init

# Run tests
make test

# Build binary
make build

# Run server (requires blnk.json config)
./blnk start

# Run workers (async job processing)
./blnk workers

# Database migrations
./blnk migrate up
./blnk migrate down

# Docker
docker compose up
```

### Blnk Configuration

```json
{
  "project_name": "TitanWallet",
  "data_source": {
    "dns": "postgres://user:pass@localhost:5432/blnk?sslmode=disable"
  },
  "redis": {
    "dns": "redis:6379"
  },
  "typesense": {
    "dns": "http://typesense:8108"
  },
  "server": {
    "port": "5001"
  },
  "tokenization_secret": "<32-byte-secret-key>"
}
```

---

## Handle Resolution Service

### Architecture (UPI/NPCI-Inspired)

The Handle Resolution Service (HRS) is a **separate microservice** that provides:
- Privacy-preserving handle-to-wallet mapping
- Fraud detection and risk scoring
- Transaction limits and velocity checks
- Cross-network routing
- AML/sanctions screening

### Why Separate from Blnk?

| Reason | Benefit |
|--------|---------|
| **Scale Independently** | Handle lookups >> transactions (10:1 ratio) |
| **Security Layer** | Never expose wallet IDs in client apps |
| **Centralized Fraud** | Single point for risk assessment |
| **Multi-Network** | Route to external wallets without touching ledger |
| **Compliance** | Centralized AML/KYC checks |
| **Future-Proof** | Add new networks without ledger changes |

### Database Schema

```sql
-- Handle Registry
CREATE TABLE handles (
    handle_id UUID PRIMARY KEY,
    handle VARCHAR(255) UNIQUE NOT NULL,           -- "emily"
    full_handle VARCHAR(255) UNIQUE NOT NULL,      -- "@emily"
    handle_type VARCHAR(50) NOT NULL,              -- 'user', 'merchant'
    network_id VARCHAR(100) NOT NULL,              -- 'titan-wallet', 'phonepe'

    -- Encrypted mapping (AES-256)
    wallet_id_encrypted BYTEA NOT NULL,            -- Encrypted Blnk balance_id
    identity_id_encrypted BYTEA,                   -- Encrypted Blnk identity_id

    -- Status & Lifecycle
    status VARCHAR(50) NOT NULL DEFAULT 'active',  -- 'active', 'suspended', 'blocked'
    verified BOOLEAN DEFAULT false,
    verification_method VARCHAR(50),               -- 'phone', 'email', 'kyc'

    -- Metadata
    display_name VARCHAR(255),
    profile_image_url TEXT,

    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,                          -- For temporary handles

    CONSTRAINT handle_format CHECK (full_handle ~ '^@[a-z0-9_.-]+$')
);

CREATE INDEX idx_handles_handle ON handles(handle);
CREATE INDEX idx_handles_network ON handles(network_id);
CREATE INDEX idx_handles_status ON handles(status);

-- Transaction Limits per Handle
CREATE TABLE handle_limits (
    limit_id UUID PRIMARY KEY,
    handle_id UUID REFERENCES handles(handle_id),

    -- Transaction Limits
    max_transaction_amount BIGINT NOT NULL,        -- In smallest unit (cents, satoshis)
    daily_transaction_limit BIGINT NOT NULL,
    monthly_transaction_limit BIGINT NOT NULL,

    -- Velocity Limits
    max_transactions_per_hour INT DEFAULT 10,
    max_transactions_per_day INT DEFAULT 50,
    max_transactions_per_month INT DEFAULT 500,

    -- Current Usage (reset daily/monthly)
    daily_amount_used BIGINT DEFAULT 0,
    monthly_amount_used BIGINT DEFAULT 0,
    transactions_today INT DEFAULT 0,
    transactions_this_month INT DEFAULT 0,

    -- Reset timestamps
    daily_reset_at TIMESTAMP,
    monthly_reset_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Activity Log (for fraud detection ML)
CREATE TABLE handle_activity (
    activity_id UUID PRIMARY KEY,
    handle_id UUID REFERENCES handles(handle_id),

    -- Transaction Context
    transaction_type VARCHAR(50),                  -- 'send', 'receive', 'request'
    amount BIGINT,
    currency VARCHAR(10),
    counterparty_handle VARCHAR(255),

    -- Risk Signals
    risk_score DECIMAL(5,2),                       -- 0-100
    risk_factors JSONB,                            -- ["new_device", "unusual_amount"]

    -- Context Metadata
    ip_address INET,
    device_fingerprint VARCHAR(255),
    location GEOGRAPHY(POINT),
    user_agent TEXT,

    -- Result
    status VARCHAR(50),                            -- 'approved', 'declined', 'flagged'
    decline_reason TEXT,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_activity_handle ON handle_activity(handle_id);
CREATE INDEX idx_activity_created ON handle_activity(created_at DESC);
CREATE INDEX idx_activity_risk ON handle_activity(risk_score DESC);

-- Risk Profiles (ML-generated)
CREATE TABLE handle_risk_profiles (
    handle_id UUID PRIMARY KEY REFERENCES handles(handle_id),

    -- Risk Metrics
    overall_risk_score DECIMAL(5,2) DEFAULT 0,
    trust_score DECIMAL(5,2) DEFAULT 50,           -- Increases with good behavior

    -- Behavioral Patterns (for anomaly detection)
    avg_transaction_amount BIGINT,
    typical_transaction_times JSONB,               -- ["09:00-12:00", "18:00-22:00"]
    common_recipients JSONB,                       -- ["@bob", "@store1"]

    -- Fraud Indicators
    suspicious_activity_count INT DEFAULT 0,
    chargebacks_count INT DEFAULT 0,
    reported_by_users_count INT DEFAULT 0,

    -- KYC/AML
    kyc_level VARCHAR(50),                         -- 'basic', 'intermediate', 'full'
    aml_screening_status VARCHAR(50),
    sanctions_check_status VARCHAR(50),
    last_aml_check_at TIMESTAMP,

    -- Account Age & Usage
    first_transaction_at TIMESTAMP,
    total_transactions_count INT DEFAULT 0,
    total_volume_lifetime BIGINT DEFAULT 0,

    updated_at TIMESTAMP DEFAULT NOW()
);

-- Payment Networks (for cross-network routing)
CREATE TABLE payment_networks (
    network_id VARCHAR(100) PRIMARY KEY,
    network_name VARCHAR(255) NOT NULL,
    network_type VARCHAR(50),                      -- 'internal', 'rtp', 'upi', 'swift'

    -- Routing Configuration
    routing_endpoint TEXT,
    api_credentials_encrypted BYTEA,

    -- Network Metadata
    supported_currencies JSONB,
    settlement_time_mins INT,
    fee_structure JSONB,

    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Handle Aliases (multiple handles -> same wallet)
CREATE TABLE handle_aliases (
    alias_id UUID PRIMARY KEY,
    primary_handle_id UUID REFERENCES handles(handle_id),
    alias_handle VARCHAR(255) UNIQUE NOT NULL,

    created_at TIMESTAMP DEFAULT NOW()
);
```

### Handle Service API

```typescript
interface HandleResolutionRequest {
  handle: string;                    // "@emily"
  amount?: number;                   // For fraud check
  currency?: string;
  source_handle?: string;            // Who's sending
  transaction_type: 'send' | 'receive' | 'request';
  context: {
    ip_address: string;
    device_fingerprint: string;
    location?: {lat: number, lng: number};
    user_agent: string;
  };
}

interface HandleResolutionResponse {
  handle: string;
  resolved: boolean;

  // Wallet Details (encrypted in transit)
  wallet_id?: string;               // Blnk balance_id
  identity_id?: string;             // Blnk identity_id
  display_name?: string;

  // Routing
  network: 'internal' | 'rtp' | 'external';
  network_id: string;
  routing_details?: {
    endpoint: string;
    method: 'direct' | 'rtp' | 'bridge';
  };

  // Fraud & Risk
  risk_assessment: {
    risk_score: number;             // 0-100
    risk_level: 'low' | 'medium' | 'high' | 'blocked';
    risk_factors: string[];
    recommendation: 'approve' | 'challenge' | 'decline';
  };

  // Limits
  limits: {
    can_transact: boolean;
    available_daily_limit: number;
    available_monthly_limit: number;
    max_single_transaction: number;
    limit_exceeded?: string;
  };

  // Verification
  verification: {
    verified: boolean;
    kyc_level: 'basic' | 'intermediate' | 'full';
    verification_required: boolean;
  };
}
```

### Fraud Detection Rules

```typescript
class RiskEngine {
  async assessRisk(params: {
    handle_id: string;
    amount?: number;
    source_handle?: string;
    context: RequestContext;
  }): Promise<RiskAssessment> {
    const riskFactors = [];
    let riskScore = 0;

    // 1. Velocity Check (too many transactions)
    const last1Hour = await this.getActivityCount(handle_id, '1 hour');
    if (last1Hour > 10) {
      riskFactors.push('high_velocity');
      riskScore += 30;
    }

    // 2. Unusual Amount
    const avgAmount = await this.getAverageAmount(handle_id);
    if (amount > avgAmount * 10) {
      riskFactors.push('unusual_amount');
      riskScore += 20;
    }

    // 3. New Device
    const knownDevices = await this.getKnownDevices(handle_id);
    if (!knownDevices.includes(context.device_fingerprint)) {
      riskFactors.push('new_device');
      riskScore += 15;
    }

    // 4. Unusual Time
    const typicalHours = await this.getTypicalHours(handle_id);
    const currentHour = new Date().getHours();
    if (!typicalHours.includes(currentHour)) {
      riskFactors.push('unusual_time');
      riskScore += 10;
    }

    // 5. Location Anomaly
    const lastLocation = await this.getLastLocation(handle_id);
    const distance = this.calculateDistance(lastLocation, context.location);
    if (distance > 500) {  // km
      riskFactors.push('location_anomaly');
      riskScore += 25;
    }

    // 6. Sanctions/Blacklist
    const sanctionsCheck = await this.checkSanctions(handle_id);
    if (sanctionsCheck.hit) {
      riskFactors.push('sanctions_list');
      riskScore = 100;  // Auto-block
    }

    // 7. Round-Tripping Detection
    const roundTrips = await this.detectRoundTripping(handle_id, source_handle);
    if (roundTrips > 3) {
      riskFactors.push('round_tripping');
      riskScore += 30;
    }

    // 8. Structuring Detection (multiple txns just below limit)
    const structuring = await this.detectStructuring(handle_id);
    if (structuring) {
      riskFactors.push('possible_structuring');
      riskScore += 40;
    }

    // Adjust based on trust score
    const profile = await this.getRiskProfile(handle_id);
    riskScore -= profile.trust_score * 0.3;
    riskScore = Math.max(0, Math.min(100, riskScore));

    // Determine recommendation
    let recommendation: 'approve' | 'challenge' | 'decline';
    if (riskScore >= 80) {
      recommendation = 'decline';
    } else if (riskScore >= 50) {
      recommendation = 'challenge';  // Require 2FA
    } else {
      recommendation = 'approve';
    }

    return {
      risk_score: riskScore,
      risk_level: this.getRiskLevel(riskScore),
      risk_factors: riskFactors,
      recommendation: recommendation
    };
  }
}
```

### Handle Service Endpoints

```
POST   /api/v1/handles/register          - Register new handle
GET    /api/v1/handles/:handle/resolve   - Resolve handle to wallet
POST   /api/v1/handles/:handle/verify    - Verify handle ownership
PUT    /api/v1/handles/:handle/limits    - Update transaction limits
GET    /api/v1/handles/:handle/risk      - Get risk profile
POST   /api/v1/handles/:handle/suspend   - Suspend handle
POST   /api/v1/handles/:handle/activate  - Reactivate handle
GET    /api/v1/handles/:handle/activity  - Get activity history
POST   /api/v1/handles/transaction       - Record transaction (update counters)
```

---

## Payment Flow Designs

### 1. P2P Transfer (Same Network)

**Scenario**: Jane (@jane) sends $100 to Emily (@emily), both on Titan Wallet

```
┌────────────┐
│ Jane's App │
└─────┬──────┘
      │ 1. Send $100 to @emily
      ▼
┌────────────────────┐
│ Transaction API    │
└─────┬──────────────┘
      │ 2. Resolve @emily
      ▼
┌────────────────────┐
│ Handle Service     │
│ - Lookup @emily    │
│ - Risk check       │
│ - Verify limits    │
└─────┬──────────────┘
      │ 3. Returns {wallet_id, network: 'internal', risk: 'low'}
      ▼
┌────────────────────┐
│ Transaction API    │
│ - Resolve @jane    │
└─────┬──────────────┘
      │ 4. Both internal -> Use Blnk
      ▼
┌────────────────────┐
│ Blnk Ledger        │
│ RecordTransaction: │
│  Source: jane-bal  │
│  Dest: emily-bal   │
│  Amount: $100      │
└─────┬──────────────┘
      │ 5. Transaction committed (instant)
      ▼
┌────────────────────┐
│ Notification       │
│ - Push to Emily    │
│ - Update Jane      │
└────────────────────┘
```

**Key Points**:
- ✅ No external RTP needed (same network)
- ✅ Instant settlement in Blnk
- ✅ Zero transaction fees (internal)
- ✅ Handle service prevents fraud
- ✅ Privacy preserved (wallet IDs hidden)

### 2. P2P Transfer (Cross-Network)

**Scenario**: Jane (@jane on Titan) sends $100 to Bob (@bob on PhonePe)

```
┌────────────┐
│ Jane's App │
└─────┬──────┘
      │ 1. Send $100 to @bob
      ▼
┌────────────────────┐
│ Transaction API    │
└─────┬──────────────┘
      │ 2. Resolve @bob
      ▼
┌────────────────────┐
│ Handle Service     │
│ - Lookup @bob      │
│ - Found: PhonePe   │
└─────┬──────────────┘
      │ 3. Returns {network: 'external', network_id: 'phonepe'}
      ▼
┌────────────────────┐
│ Transaction API    │
│ - Create INFLIGHT  │
│   transaction      │
└─────┬──────────────┘
      │ 4. Create inflight in Blnk (hold Jane's funds)
      ▼
┌────────────────────┐
│ Blnk Ledger        │
│ CreateInflight:    │
│  Source: jane-bal  │
│  Dest: fbo-master  │
│  Amount: $100      │
└─────┬──────────────┘
      │ 5. Funds held
      ▼
┌────────────────────┐
│ RTP Provider       │
│ - Send RTP to      │
│   PhonePe network  │
└─────┬──────────────┘
      │ 6. RTP sent
      │
      │ 7a. Success webhook
      ▼
┌────────────────────┐
│ Blnk Ledger        │
│ CommitInflight     │
└────────────────────┘
      │
      │ 7b. Failure webhook
      ▼
┌────────────────────┐
│ Blnk Ledger        │
│ VoidInflight       │
│ (Refund Jane)      │
└────────────────────┘
```

**Key Points**:
- ✅ Inflight protects against RTP failures
- ✅ Cross-network routing via Handle Service
- ✅ Reconciliation with RTP confirmations
- ⚠️ Settlement time depends on RTP network (seconds to minutes)
- 💰 RTP fees may apply

### 3. Incoming RTP (Load Wallet)

**Scenario**: User receives $500 via RTP to their Titan Wallet

```
┌──────────────────┐
│ User's Bank      │
└─────┬────────────┘
      │ RTP Transfer to virtual account
      ▼
┌──────────────────┐
│ Partner Bank     │
│ FBO Account      │
└─────┬────────────┘
      │ Webhook: RTP received
      ▼
┌──────────────────┐
│ RTP Handler API  │
│ - Parse webhook  │
│ - Map virtual    │
│   account to user│
└─────┬────────────┘
      │ Lookup user by virtual account
      ▼
┌──────────────────┐
│ Handle Service   │
│ - Map virtual    │
│   acct -> handle │
└─────┬────────────┘
      │ Returns {wallet_id: "user-usd-balance"}
      ▼
┌──────────────────┐
│ Blnk Ledger      │
│ RecordTxn:       │
│  Source: fbo-usd │
│  Dest: user-usd  │
│  Amount: $500    │
│  Ref: RTP-TXN-ID │
└─────┬────────────┘
      │ Balance updated
      ▼
┌──────────────────┐
│ Reconciliation   │
│ - Match RTP txn  │
│   to Blnk entry  │
└─────┬────────────┘
      │
      ▼
┌──────────────────┐
│ Push Notification│
│ "You received    │
│  $500"           │
└──────────────────┘
```

### 4. Merchant Payment (QR Code)

**Scenario**: Customer pays merchant $50 via QR code scan

```
┌────────────────┐
│ Merchant POS   │
│ - Generate QR  │
│ - Amount: $50  │
└─────┬──────────┘
      │ QR: titan-pay://merchant123/50
      ▼
┌────────────────┐
│ Customer Scans │
│ (Mobile App)   │
└─────┬──────────┘
      │ Parse QR -> merchant_id + amount
      ▼
┌────────────────┐
│ Transaction API│
│ - Resolve      │
│   merchant123  │
└─────┬──────────┘
      │
      ▼
┌────────────────┐
│ Handle Service │
│ - Lookup       │
│   merchant     │
│ - Verify active│
└─────┬──────────┘
      │ Returns {wallet_id: "merchant-usd"}
      ▼
┌────────────────┐
│ Blnk Ledger    │
│ RecordTxn:     │
│  Src: customer │
│  Dst: merchant │
│  Amount: $50   │
└─────┬──────────┘
      │ Instant settlement
      ▼
┌────────────────┐
│ Notifications  │
│ - Customer:    │
│   "Paid $50"   │
│ - Merchant:    │
│   "Received"   │
└────────────────┘
```

---

## Multi-Currency Support

### Currency Configuration in Blnk

```typescript
// Create multi-currency balances for a user

interface CurrencyConfig {
  currency: string;
  precision: number;  // 10^n for decimal places
  symbol: string;
}

const SUPPORTED_CURRENCIES: CurrencyConfig[] = [
  { currency: 'USD', precision: 100, symbol: '$' },        // 2 decimals
  { currency: 'NGN', precision: 100, symbol: '₦' },        // 2 decimals
  { currency: 'EUR', precision: 100, symbol: '€' },        // 2 decimals
  { currency: 'GBP', precision: 100, symbol: '£' },        // 2 decimals
  { currency: 'INR', precision: 100, symbol: '₹' },        // 2 decimals
  { currency: 'BTC', precision: 100000000, symbol: '₿' },  // 8 decimals
  { currency: 'ETH', precision: 1e18, symbol: 'Ξ' },       // 18 decimals
  { currency: 'USDT', precision: 1000000, symbol: '$' },   // 6 decimals
];

async function createMultiCurrencyWallet(userId: string): Promise<Wallet> {
  const balances = [];

  for (const config of SUPPORTED_CURRENCIES) {
    const balance = await blnk.createBalance({
      ledger_id: 'main-ledger',
      identity_id: userId,
      currency: config.currency,
      precision: config.precision,
      meta_data: {
        user_id: userId,
        currency_symbol: config.symbol
      }
    });

    balances.push(balance);
  }

  return { userId, balances };
}
```

### Currency Conversion

```typescript
// Example: User converts USD to NGN

async function convertCurrency(params: {
  user_id: string;
  from_currency: string;
  to_currency: string;
  amount: number;
}): Promise<Transaction> {

  // Step 1: Get current exchange rate
  const rate = await exchangeRateService.getRate(
    params.from_currency,
    params.to_currency
  );
  // Example: 1 USD = 1500 NGN

  // Step 2: Get user's balances
  const sourceBalance = await blnk.getBalanceByIndicator(
    `@user-${params.user_id}`,
    params.from_currency
  );

  const destBalance = await blnk.getBalanceByIndicator(
    `@user-${params.user_id}`,
    params.to_currency
  );

  // Step 3: Create transaction with rate
  const transaction = await blnk.recordTransaction({
    source: sourceBalance.balance_id,
    destination: destBalance.balance_id,
    amount: params.amount,
    rate: rate,  // Blnk handles the conversion
    currency: params.from_currency,
    precision: getCurrencyPrecision(params.from_currency),
    reference: `currency-swap-${uuidv4()}`,
    meta_data: {
      exchange_rate: rate,
      from_currency: params.from_currency,
      to_currency: params.to_currency
    }
  });

  return transaction;
}

// Example call:
// convertCurrency({
//   user_id: "user123",
//   from_currency: "USD",
//   to_currency: "NGN",
//   amount: 100
// })
// Result: User loses $100 USD, gains 150,000 NGN
```

### Exchange Rate Provider

```typescript
// Integration with external rate provider

interface ExchangeRateProvider {
  getRate(from: string, to: string): Promise<number>;
  getRates(base: string): Promise<Record<string, number>>;
}

class CoinGeckoProvider implements ExchangeRateProvider {
  private apiKey: string;
  private cache: Map<string, {rate: number, expiry: number}>;

  constructor(apiKey: string) {
    this.apiKey = apiKey;
    this.cache = new Map();
  }

  async getRate(from: string, to: string): Promise<number> {
    const cacheKey = `${from}-${to}`;
    const cached = this.cache.get(cacheKey);

    // Return cached if not expired (5 min cache)
    if (cached && cached.expiry > Date.now()) {
      return cached.rate;
    }

    // Fetch fresh rate
    const response = await fetch(
      `https://api.coingecko.com/api/v3/simple/price?ids=${from}&vs_currencies=${to}`,
      { headers: { 'Authorization': `Bearer ${this.apiKey}` } }
    );

    const data = await response.json();
    const rate = data[from.toLowerCase()][to.toLowerCase()];

    // Cache for 5 minutes
    this.cache.set(cacheKey, {
      rate,
      expiry: Date.now() + 5 * 60 * 1000
    });

    return rate;
  }

  async getRates(base: string): Promise<Record<string, number>> {
    const response = await fetch(
      `https://api.coingecko.com/api/v3/simple/price?ids=${base}&vs_currencies=usd,ngn,eur,gbp,btc,eth`,
      { headers: { 'Authorization': `Bearer ${this.apiKey}` } }
    );

    return await response.json();
  }
}
```

---

## Cryptocurrency Support

### Supported Cryptocurrencies

```typescript
const CRYPTO_CONFIGS = {
  BTC: {
    name: 'Bitcoin',
    decimals: 8,
    precision: 100000000,      // 10^8
    smallest_unit: 'satoshi',
    network: 'bitcoin',
    confirmations_required: 6
  },
  ETH: {
    name: 'Ethereum',
    decimals: 18,
    precision: 1e18,           // 10^18
    smallest_unit: 'wei',
    network: 'ethereum',
    confirmations_required: 12
  },
  USDT: {
    name: 'Tether',
    decimals: 6,
    precision: 1000000,        // 10^6
    smallest_unit: 'micro-USDT',
    network: 'ethereum',       // ERC-20
    contract_address: '0xdac17f958d2ee523a2206206994597c13d831ec7',
    confirmations_required: 12
  },
  USDC: {
    name: 'USD Coin',
    decimals: 6,
    precision: 1000000,
    smallest_unit: 'micro-USDC',
    network: 'ethereum',
    contract_address: '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48',
    confirmations_required: 12
  }
};
```

### Crypto Wallet Integration

```
┌─────────────────────────────────────────────────────────────┐
│                   YOUR APPLICATION                           │
│  ┌────────────────┐  ┌────────────────┐                     │
│  │  Blnk Ledger   │  │  Handle Service│                     │
│  │  (Accounting)  │  │  (Privacy)     │                     │
│  └────────┬───────┘  └────────────────┘                     │
└───────────┼──────────────────────────────────────────────────┘
            │
            │ Internal Ledger Only
            │
┌───────────┼──────────────────────────────────────────────────┐
│           ▼                                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │       WALLET CUSTODY SERVICE                           │ │
│  │  (Fireblocks / BitGo / AWS KMS / Self-Hosted)          │ │
│  │  - Key Management                                      │ │
│  │  - Transaction Signing                                 │ │
│  │  - Address Generation                                  │ │
│  └────────┬───────────────────────────────────────────────┘ │
└───────────┼───────────────────────────────────────────────────┘
            │
            │ Blockchain Transactions
            ▼
┌──────────────────────────────────────────────────────────────┐
│               BLOCKCHAIN NETWORKS                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │   Bitcoin    │  │   Ethereum   │  │   Polygon    │       │
│  │   Network    │  │   Network    │  │   Network    │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└───────────▲──────────────────────────────────────────────────┘
            │
            │ Monitoring & Webhooks
            │
┌───────────┴──────────────────────────────────────────────────┐
│  ┌────────────────────────────────────────────────────────┐ │
│  │     BLOCKCHAIN MONITORING SERVICE                      │ │
│  │  (Alchemy / Infura / QuickNode / Self-Hosted)          │ │
│  │  - Deposit Detection                                   │ │
│  │  - Confirmation Tracking                               │ │
│  │  - Webhook Notifications                               │ │
│  └────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### Crypto Deposit Flow

```typescript
// 1. Generate deposit address for user

async function generateDepositAddress(userId: string, crypto: string): Promise<string> {
  // Generate address via custody service
  const address = await walletCustodyService.generateAddress({
    user_id: userId,
    currency: crypto,
    network: CRYPTO_CONFIGS[crypto].network
  });

  // Store mapping in database
  await db.query(`
    INSERT INTO crypto_addresses (user_id, currency, address, created_at)
    VALUES ($1, $2, $3, NOW())
  `, [userId, crypto, address]);

  // Setup webhook monitoring
  await blockchainMonitor.watchAddress(address, crypto);

  return address;
}

// 2. Handle incoming deposit (webhook from blockchain monitor)

async function handleCryptoDeposit(webhook: {
  tx_hash: string;
  from_address: string;
  to_address: string;
  amount: string;        // In smallest unit (satoshis, wei)
  currency: string;
  confirmations: number;
  network: string;
}) {
  const config = CRYPTO_CONFIGS[webhook.currency];

  // Lookup user by deposit address
  const user = await db.query(`
    SELECT user_id, handle FROM crypto_addresses
    WHERE address = $1 AND currency = $2
  `, [webhook.to_address, webhook.currency]);

  if (!user.rows.length) {
    console.error('Unknown deposit address:', webhook.to_address);
    return;
  }

  const userId = user.rows[0].user_id;

  // Get user's crypto balance in Blnk
  const balance = await blnk.getBalanceByIndicator(
    `@user-${userId}`,
    webhook.currency
  );

  // Check if we've already processed this deposit
  const existing = await db.query(`
    SELECT * FROM crypto_deposits WHERE tx_hash = $1
  `, [webhook.tx_hash]);

  if (existing.rows.length) {
    // Update confirmations
    if (webhook.confirmations >= config.confirmations_required) {
      await db.query(`
        UPDATE crypto_deposits
        SET confirmations = $1, status = 'confirmed'
        WHERE tx_hash = $2
      `, [webhook.confirmations, webhook.tx_hash]);

      // If was pending, commit the inflight transaction
      const depositRecord = existing.rows[0];
      if (depositRecord.blnk_txn_id && depositRecord.status === 'pending') {
        await blnk.commitInflightTransaction(depositRecord.blnk_txn_id);
      }
    }
    return;
  }

  // New deposit
  if (webhook.confirmations < config.confirmations_required) {
    // Create INFLIGHT transaction (pending confirmations)
    const transaction = await blnk.recordTransaction({
      source: `master-hot-wallet-${webhook.currency}`,
      destination: balance.balance_id,
      amount: parseFloat(webhook.amount) / config.precision,
      precision: config.precision,
      currency: webhook.currency,
      inflight: true,
      reference: `crypto-deposit-${webhook.tx_hash}`,
      meta_data: {
        tx_hash: webhook.tx_hash,
        from_address: webhook.from_address,
        network: webhook.network,
        confirmations: webhook.confirmations,
        required_confirmations: config.confirmations_required
      }
    });

    // Record in deposits table
    await db.query(`
      INSERT INTO crypto_deposits
        (tx_hash, user_id, currency, amount, confirmations, status, blnk_txn_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [
      webhook.tx_hash,
      userId,
      webhook.currency,
      webhook.amount,
      webhook.confirmations,
      'pending',
      transaction.transaction_id
    ]);

    // Notify user (pending)
    await sendNotification(userId, {
      title: 'Deposit Pending',
      message: `${webhook.amount / config.precision} ${webhook.currency} deposit pending (${webhook.confirmations}/${config.confirmations_required} confirmations)`
    });

  } else {
    // Sufficient confirmations - direct credit
    const transaction = await blnk.recordTransaction({
      source: `master-hot-wallet-${webhook.currency}`,
      destination: balance.balance_id,
      amount: parseFloat(webhook.amount) / config.precision,
      precision: config.precision,
      currency: webhook.currency,
      reference: `crypto-deposit-${webhook.tx_hash}`,
      meta_data: {
        tx_hash: webhook.tx_hash,
        from_address: webhook.from_address,
        network: webhook.network,
        confirmations: webhook.confirmations
      }
    });

    await db.query(`
      INSERT INTO crypto_deposits
        (tx_hash, user_id, currency, amount, confirmations, status, blnk_txn_id)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [
      webhook.tx_hash,
      userId,
      webhook.currency,
      webhook.amount,
      webhook.confirmations,
      'confirmed',
      transaction.transaction_id
    ]);

    // Notify user (confirmed)
    await sendNotification(userId, {
      title: 'Deposit Confirmed',
      message: `${webhook.amount / config.precision} ${webhook.currency} has been added to your wallet`
    });
  }
}
```

### Crypto Withdrawal Flow

```typescript
async function withdrawCrypto(params: {
  user_id: string;
  currency: string;
  amount: number;
  to_address: string;
  network?: string;
}): Promise<{txn_id: string, blockchain_tx?: string}> {

  const config = CRYPTO_CONFIGS[params.currency];

  // Step 1: Get user's balance
  const balance = await blnk.getBalanceByIndicator(
    `@user-${params.user_id}`,
    params.currency
  );

  // Step 2: Validate address
  const isValid = await walletCustodyService.validateAddress(
    params.to_address,
    params.currency
  );

  if (!isValid) {
    throw new Error('Invalid withdrawal address');
  }

  // Step 3: Calculate gas fee
  const gasFee = await walletCustodyService.estimateGas({
    currency: params.currency,
    amount: params.amount,
    network: params.network || config.network
  });

  const totalAmount = params.amount + gasFee;

  // Step 4: Create INFLIGHT transaction in Blnk
  const transaction = await blnk.recordTransaction({
    source: balance.balance_id,
    destination: `master-hot-wallet-${params.currency}`,
    amount: totalAmount,
    precision: config.precision,
    currency: params.currency,
    inflight: true,
    reference: `crypto-withdrawal-${uuidv4()}`,
    meta_data: {
      to_address: params.to_address,
      network: params.network || config.network,
      withdrawal_amount: params.amount,
      gas_fee: gasFee,
      status: 'pending_blockchain'
    }
  });

  try {
    // Step 5: Send blockchain transaction
    const blockchainTx = await walletCustodyService.sendTransaction({
      currency: params.currency,
      amount: params.amount * config.precision,  // Convert to smallest unit
      to_address: params.to_address,
      network: params.network || config.network
    });

    // Step 6: Commit inflight transaction
    await blnk.commitInflightTransaction(transaction.transaction_id);

    // Step 7: Record withdrawal
    await db.query(`
      INSERT INTO crypto_withdrawals
        (blnk_txn_id, user_id, currency, amount, to_address, blockchain_tx_hash, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
    `, [
      transaction.transaction_id,
      params.user_id,
      params.currency,
      params.amount,
      params.to_address,
      blockchainTx.tx_hash,
      'pending'
    ]);

    // Step 8: Monitor confirmation
    await blockchainMonitor.watchTransaction(
      blockchainTx.tx_hash,
      params.currency
    );

    return {
      txn_id: transaction.transaction_id,
      blockchain_tx: blockchainTx.tx_hash
    };

  } catch (error) {
    // Blockchain transaction failed - void the inflight
    await blnk.voidInflightTransaction(transaction.transaction_id);

    throw new Error(`Withdrawal failed: ${error.message}`);
  }
}
```

---

## FBO Account Structure

### What is an FBO Account?

**For Benefit Of (FBO)** account is a master bank account held by your company that pools all user funds. Individual user balances are tracked in the ledger (Blnk), not as separate bank accounts.

### Regulatory Requirements

- **Know Your Customer (KYC)**: Verify all user identities
- **Anti-Money Laundering (AML)**: Screen for sanctions, monitor for suspicious activity
- **Reconciliation**: Daily matching of bank statements to ledger
- **Reserve Requirements**: Hold percentage of deposits in reserve (varies by jurisdiction)
- **Audit Trail**: Complete transaction history for regulatory audits

### FBO Structure in Blnk

```
Blnk Ledger Hierarchy:

Main Ledger: "titan-wallet-ledger"
│
├─ FBO Master Accounts (Actual Bank Balances)
│  ├─ fbo-master-usd        ← Actual balance at partner bank
│  ├─ fbo-master-ngn        ← Actual balance at partner bank
│  ├─ fbo-master-eur        ← Actual balance at partner bank
│  └─ fbo-master-btc        ← Hot wallet balance
│
├─ User Virtual Balances (Ledger Entries)
│  ├─ user-001-usd
│  ├─ user-001-ngn
│  ├─ user-001-btc
│  ├─ user-002-usd
│  └─ ... (thousands of user balances)
│
├─ Reserve Balances (Regulatory Requirement)
│  ├─ reserve-usd           ← 10-20% of total user deposits
│  ├─ reserve-ngn
│  └─ reserve-btc
│
├─ Fee Income Balances
│  ├─ fee-income-usd
│  ├─ fee-income-ngn
│  └─ gas-fees-collected-btc
│
└─ Operational Balances
   ├─ pending-settlements   ← For RTP in-flight
   └─ float-account        ← Working capital
```

### Reconciliation Process

```typescript
// Daily reconciliation: Match bank statement to Blnk ledger

async function reconcileFBO(date: Date, currency: string) {
  // Step 1: Get bank statement from partner bank
  const bankStatement = await partnerBank.getStatement({
    account: 'FBO_ACCOUNT',
    currency: currency,
    date: date
  });

  // Step 2: Get Blnk transactions for the day
  const blnkTransactions = await blnk.getTransactions({
    from: date,
    to: date,
    currency: currency,
    balance_id: `fbo-master-${currency.toLowerCase()}`
  });

  // Step 3: Use Blnk's reconciliation engine
  const reconciliation = await blnk.createReconciliation({
    strategy: 'one_to_one',  // Each bank entry matches one ledger entry
    source: 'bank_statement',
    upload: bankStatement,
    matching_rules: [
      {
        criteria: 'reference',
        field: 'reference'
      },
      {
        criteria: 'amount',
        field: 'amount'
      },
      {
        criteria: 'date',
        field: 'date',
        threshold: '1 day'  // Allow 1 day difference
      }
    ]
  });

  // Step 4: Review matches and exceptions
  const results = await blnk.getReconciliationResults(reconciliation.id);

  // Matched transactions
  console.log(`Matched: ${results.matched.length}`);

  // Unmatched in bank (may be pending in Blnk)
  console.log(`Unmatched in bank: ${results.bank_only.length}`);

  // Unmatched in ledger (may be RTP failures)
  console.log(`Unmatched in ledger: ${results.ledger_only.length}`);

  // Step 5: Investigate exceptions
  for (const exception of results.ledger_only) {
    // Check if RTP failed
    const rtpStatus = await checkRTPStatus(exception.reference);

    if (rtpStatus === 'failed') {
      // Void the inflight transaction
      await blnk.voidInflightTransaction(exception.transaction_id);
    }
  }

  // Step 6: Calculate expected vs actual balance
  const expectedBalance = await blnk.getBalance(`fbo-master-${currency.toLowerCase()}`);
  const actualBalance = bankStatement.ending_balance;

  const variance = Math.abs(expectedBalance.balance - actualBalance);

  if (variance > 100) {  // More than $1 variance (in cents)
    await alertOps({
      severity: 'high',
      message: `FBO ${currency} reconciliation variance: $${variance / 100}`,
      expected: expectedBalance.balance / 100,
      actual: actualBalance / 100
    });
  }

  // Step 7: Generate reconciliation report
  return {
    date: date,
    currency: currency,
    matched: results.matched.length,
    exceptions: results.bank_only.length + results.ledger_only.length,
    variance: variance / 100,
    status: variance < 100 ? 'passed' : 'review_required'
  };
}

// Run daily
cron.schedule('0 2 * * *', () => {  // 2 AM daily
  reconcileFBO(new Date(), 'USD');
  reconcileFBO(new Date(), 'NGN');
  reconcileFBO(new Date(), 'EUR');
});
```

### Reserve Calculations

```typescript
// Calculate required reserves based on regulatory requirements

async function calculateReserveRequirement(currency: string): Promise<{
  total_user_deposits: number;
  required_reserve: number;
  current_reserve: number;
  shortfall: number;
}> {

  // Step 1: Sum all user balances
  const userBalances = await blnk.getBalances({
    currency: currency,
    ledger_id: 'titan-wallet-ledger'
  });

  const totalUserDeposits = userBalances.reduce((sum, bal) => {
    // Only count positive balances (deposits)
    if (bal.balance > 0 && !bal.balance_id.startsWith('fbo-')) {
      return sum + bal.balance;
    }
    return sum;
  }, 0);

  // Step 2: Calculate required reserve (e.g., 15%)
  const RESERVE_PERCENTAGE = 0.15;  // 15% reserve requirement
  const requiredReserve = totalUserDeposits * RESERVE_PERCENTAGE;

  // Step 3: Get current reserve balance
  const reserveBalance = await blnk.getBalance(`reserve-${currency.toLowerCase()}`);
  const currentReserve = reserveBalance.balance;

  // Step 4: Calculate shortfall
  const shortfall = Math.max(0, requiredReserve - currentReserve);

  return {
    total_user_deposits: totalUserDeposits / 100,  // Convert to dollars
    required_reserve: requiredReserve / 100,
    current_reserve: currentReserve / 100,
    shortfall: shortfall / 100
  };
}

// Monitor reserves hourly
cron.schedule('0 * * * *', async () => {
  const usdReserve = await calculateReserveRequirement('USD');

  if (usdReserve.shortfall > 1000) {  // $1000 shortfall
    await alertOps({
      severity: 'critical',
      message: `USD reserve shortfall: $${usdReserve.shortfall}`,
      required: usdReserve.required_reserve,
      current: usdReserve.current_reserve
    });
  }
});
```

---

## Security & Compliance

### Data Encryption

#### At Rest
- **Blnk Identity PII**: Encrypted via Blnk's tokenization service
- **Handle Service**: Wallet IDs encrypted with AES-256
- **Database**: PostgreSQL with encryption enabled
- **Backups**: Encrypted with separate keys

#### In Transit
- **TLS 1.3** for all API communications
- **Certificate pinning** in mobile apps
- **API keys** rotated every 90 days

### Authentication & Authorization

```typescript
// Multi-factor authentication flow

interface AuthRequest {
  phone: string;
  device_fingerprint: string;
}

interface AuthResponse {
  session_token?: string;
  requires_2fa: boolean;
  challenge_id?: string;
}

async function authenticate(request: AuthRequest): Promise<AuthResponse> {
  // Step 1: Verify phone number
  const user = await db.query('SELECT * FROM users WHERE phone = $1', [request.phone]);

  if (!user.rows.length) {
    throw new Error('User not found');
  }

  // Step 2: Check device
  const knownDevice = await db.query(
    'SELECT * FROM known_devices WHERE user_id = $1 AND fingerprint = $2',
    [user.rows[0].id, request.device_fingerprint]
  );

  if (!knownDevice.rows.length) {
    // New device - require 2FA
    const otpCode = generateOTP();
    await sendSMS(request.phone, `Your verification code: ${otpCode}`);

    const challengeId = uuidv4();
    await redis.setex(`otp:${challengeId}`, 300, otpCode);  // 5 min expiry

    return {
      requires_2fa: true,
      challenge_id: challengeId
    };
  }

  // Known device - create session
  const sessionToken = jwt.sign(
    { user_id: user.rows[0].id, phone: request.phone },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );

  return {
    session_token: sessionToken,
    requires_2fa: false
  };
}

async function verify2FA(challengeId: string, code: string): Promise<AuthResponse> {
  const storedCode = await redis.get(`otp:${challengeId}`);

  if (!storedCode || storedCode !== code) {
    throw new Error('Invalid or expired code');
  }

  // ... create session
}
```

### KYC Levels

```typescript
enum KYCLevel {
  NONE = 0,        // No verification - $100 limit
  BASIC = 1,       // Phone verified - $1,000 limit
  INTERMEDIATE = 2,// Email + ID - $10,000 limit
  FULL = 3         // Video KYC + proof of address - Unlimited
}

interface KYCLimits {
  kyc_level: KYCLevel;
  daily_limit: number;
  monthly_limit: number;
  single_transaction_limit: number;
}

const KYC_LIMITS: Record<KYCLevel, KYCLimits> = {
  [KYCLevel.NONE]: {
    kyc_level: KYCLevel.NONE,
    daily_limit: 10000,      // $100
    monthly_limit: 50000,    // $500
    single_transaction_limit: 5000  // $50
  },
  [KYCLevel.BASIC]: {
    kyc_level: KYCLevel.BASIC,
    daily_limit: 100000,     // $1,000
    monthly_limit: 500000,   // $5,000
    single_transaction_limit: 50000  // $500
  },
  [KYCLevel.INTERMEDIATE]: {
    kyc_level: KYCLevel.INTERMEDIATE,
    daily_limit: 1000000,    // $10,000
    monthly_limit: 5000000,  // $50,000
    single_transaction_limit: 500000  // $5,000
  },
  [KYCLevel.FULL]: {
    kyc_level: KYCLevel.FULL,
    daily_limit: Number.MAX_SAFE_INTEGER,
    monthly_limit: Number.MAX_SAFE_INTEGER,
    single_transaction_limit: 10000000  // $100,000
  }
};
```

### AML Screening

```typescript
// Sanctions screening using OFAC lists

async function screenForSanctions(params: {
  name: string;
  country: string;
  date_of_birth?: string;
}): Promise<{
  hit: boolean;
  matches: any[];
  risk_level: 'clear' | 'potential' | 'confirmed';
}> {

  // Query sanctions database (OFAC SDN list)
  const response = await fetch('https://api.sanctions-screening.com/search', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.SANCTIONS_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      name: params.name,
      country: params.country,
      dob: params.date_of_birth
    })
  });

  const results = await response.json();

  if (results.exact_match) {
    return {
      hit: true,
      matches: results.matches,
      risk_level: 'confirmed'
    };
  }

  if (results.fuzzy_matches.length > 0) {
    return {
      hit: true,
      matches: results.fuzzy_matches,
      risk_level: 'potential'
    };
  }

  return {
    hit: false,
    matches: [],
    risk_level: 'clear'
  };
}

// Run on user registration and periodically
async function performAMLCheck(userId: string): Promise<void> {
  const user = await db.query('SELECT * FROM users WHERE id = $1', [userId]);

  const sanctionsCheck = await screenForSanctions({
    name: `${user.first_name} ${user.last_name}`,
    country: user.country,
    date_of_birth: user.dob
  });

  await db.query(`
    UPDATE handle_risk_profiles
    SET sanctions_check_status = $1, last_aml_check_at = NOW()
    WHERE handle_id = (SELECT handle_id FROM handles WHERE identity_id_encrypted = $2)
  `, [sanctionsCheck.risk_level, user.identity_id]);

  if (sanctionsCheck.risk_level === 'confirmed') {
    // Suspend account immediately
    await handleService.suspendHandle(user.handle, 'OFAC sanctions hit');

    // Alert compliance team
    await alertCompliance({
      severity: 'critical',
      user_id: userId,
      reason: 'OFAC sanctions match',
      matches: sanctionsCheck.matches
    });
  }
}
```

---

## Deployment Architecture

### Production Infrastructure

```
                        ┌─────────────────┐
                        │   CloudFlare    │
                        │   (CDN + DDoS)  │
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │  Load Balancer  │
                        │   (NGINX/HAProxy)│
                        └────────┬────────┘
                                 │
                ┌────────────────┼────────────────┐
                ▼                ▼                ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │  API Server  │ │  API Server  │ │  API Server  │
        │   Instance1  │ │   Instance2  │ │   Instance3  │
        └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
               │                │                │
               └────────────────┼────────────────┘
                                │
                ┌───────────────┼───────────────┐
                ▼               ▼               ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │   Handle     │ │     Blnk     │ │    Redis     │
        │   Service    │ │    Ledger    │ │   Cluster    │
        │  (3 nodes)   │ │  (3 nodes)   │ │  (Primary +  │
        │              │ │              │ │   2 Replicas)│
        └──────┬───────┘ └──────┬───────┘ └──────────────┘
               │                │
               │                │
        ┌──────▼───────┐ ┌──────▼───────┐
        │  PostgreSQL  │ │  PostgreSQL  │
        │   (Handle)   │ │    (Blnk)    │
        │  Primary +   │ │  Primary +   │
        │  2 Replicas  │ │  2 Replicas  │
        └──────────────┘ └──────────────┘
```

### Kubernetes Deployment (Recommended for Scale)

```yaml
# blnk-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: blnk-ledger
spec:
  replicas: 3
  selector:
    matchLabels:
      app: blnk
  template:
    metadata:
      labels:
        app: blnk
    spec:
      containers:
      - name: blnk
        image: blnk:latest
        ports:
        - containerPort: 5001
        env:
        - name: POSTGRES_URL
          valueFrom:
            secretKeyRef:
              name: blnk-secrets
              key: postgres-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: blnk-secrets
              key: redis-url
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "2000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 5001
          initialDelaySeconds: 10
          periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: blnk-service
spec:
  selector:
    app: blnk
  ports:
  - protocol: TCP
    port: 5001
    targetPort: 5001
  type: ClusterIP
```

### Monitoring & Observability

```typescript
// OpenTelemetry tracing (already in Blnk)

import { trace, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('handle-service');

async function resolveHandle(handle: string) {
  const span = tracer.startSpan('resolve_handle');
  span.setAttribute('handle', handle);

  try {
    // ... resolution logic

    span.setStatus({ code: SpanStatusCode.OK });
    return result;
  } catch (error) {
    span.setStatus({
      code: SpanStatusCode.ERROR,
      message: error.message
    });
    span.recordException(error);
    throw error;
  } finally {
    span.end();
  }
}

// Prometheus metrics

import { Counter, Histogram, register } from 'prom-client';

const handleResolutionCounter = new Counter({
  name: 'handle_resolution_total',
  help: 'Total handle resolution requests',
  labelNames: ['status', 'network']
});

const handleResolutionDuration = new Histogram({
  name: 'handle_resolution_duration_seconds',
  help: 'Handle resolution duration',
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5]
});

// Track metrics
handleResolutionCounter.inc({ status: 'success', network: 'internal' });
handleResolutionDuration.observe(0.123);

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

---

## API Specifications

### Handle Service API

```
Base URL: https://api.titanwallet.com/v1/handles

Authentication: Bearer token in Authorization header
```

#### Endpoints

**1. Register Handle**
```
POST /register

Request:
{
  "desired_handle": "emily",
  "wallet_id": "bal_abc123",
  "identity_id": "id_xyz789",
  "verification": {
    "phone": "+1234567890",
    "email": "emily@example.com"
  }
}

Response:
{
  "handle_id": "hdl_123456",
  "full_handle": "@emily",
  "status": "pending_verification",
  "verification_sent_to": "phone"
}
```

**2. Resolve Handle**
```
POST /resolve

Request:
{
  "handle": "@emily",
  "amount": 100.00,
  "currency": "USD",
  "source_handle": "@jane",
  "transaction_type": "send",
  "context": {
    "ip_address": "192.168.1.1",
    "device_fingerprint": "abc123",
    "user_agent": "TitanWallet/1.0"
  }
}

Response:
{
  "handle": "@emily",
  "resolved": true,
  "wallet_id": "bal_xyz789",
  "identity_id": "id_abc123",
  "display_name": "Emily Chen",
  "network": "internal",
  "network_id": "titan-wallet",
  "risk_assessment": {
    "risk_score": 15.5,
    "risk_level": "low",
    "risk_factors": [],
    "recommendation": "approve"
  },
  "limits": {
    "can_transact": true,
    "available_daily_limit": 9900.00,
    "available_monthly_limit": 49500.00,
    "max_single_transaction": 5000.00
  },
  "verification": {
    "verified": true,
    "kyc_level": "intermediate",
    "verification_required": false
  }
}
```

**3. Record Transaction**
```
POST /:handle/transaction

Request:
{
  "amount": 100.00,
  "transaction_type": "send"
}

Response:
{
  "success": true,
  "limits_updated": true,
  "remaining_daily_limit": 9800.00
}
```

### Blnk API Integration

```
Base URL: http://localhost:5001  (or deployed URL)
```

**Key Endpoints Used:**

```
# Identity Management
POST   /identities                    - Create identity
GET    /identities/:id                - Get identity
PUT    /identities/:id                - Update identity

# Balance Management
POST   /balances                      - Create balance
GET    /balances/:id                  - Get balance
GET    /balances                      - List balances

# Transactions
POST   /transactions                  - Record transaction
POST   /transactions/inflight/commit  - Commit inflight
POST   /transactions/inflight/void    - Void inflight
GET    /transactions/:id              - Get transaction

# Reconciliation
POST   /reconciliation                - Create reconciliation
GET    /reconciliation/:id/results    - Get results
```

---

## Future Roadmap

### Phase 1: MVP (Months 1-3)
- ✅ Blnk ledger setup
- ✅ Handle Resolution Service
- ✅ P2P transfers (internal only)
- ✅ Multi-currency (USD, NGN)
- ✅ Basic fraud detection
- ✅ Mobile apps (consumer + merchant)

### Phase 2: Network Expansion (Months 4-6)
- Cross-network routing (RTP integration)
- QR/NFC merchant payments
- Crypto support (BTC, ETH, USDT)
- Advanced fraud ML models
- Bulk payments API for businesses

### Phase 3: Scale (Months 7-9)
- International expansion
- White-label solution for partners
- Merchant dashboard & analytics
- Loyalty/rewards program integration
- API for third-party developers

### Phase 4: Advanced Features (Months 10-12)
- Savings products (interest-bearing accounts)
- Lending/credit features
- Investment products integration
- Bill payments & recurring transfers
- Cross-border remittances

---

## Appendix

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Blnk over Formance** | Faster time to market, built-in reconciliation, simpler infrastructure for MVP |
| **Separate Handle Service** | Security, scalability, centralized fraud detection, future multi-network support |
| **FBO Account Model** | Regulatory compliance, capital efficiency, easier user onboarding |
| **Inflight Transactions** | Perfect for RTP confirmations, crypto confirmations, and reversible operations |
| **React + TypeScript** | Type safety, excellent ecosystem, team expertise |
| **PostgreSQL** | ACID compliance, excellent for financial data, Blnk's native DB |

### External Dependencies

| Service | Purpose | Alternatives |
|---------|---------|--------------|
| **RTP Provider** | Real-time payment network | FedNow, TCH RTP, NPCI UPI |
| **Wallet Custody** | Crypto key management | Fireblocks, BitGo, AWS KMS |
| **Blockchain Monitor** | Deposit detection | Alchemy, Infura, QuickNode |
| **Exchange Rates** | Currency conversion | CoinGecko, CoinMarketCap, Fixer.io |
| **SMS Provider** | 2FA/OTP | Twilio, AWS SNS |
| **KYC Provider** | Identity verification | Jumio, Onfido, Persona |
| **AML Screening** | Sanctions check | ComplyAdvantage, Chainalysis |

### Glossary

- **FBO**: For Benefit Of - master account holding pooled user funds
- **RTP**: Real-Time Payments - instant payment network
- **Inflight**: Transaction held in pending state before commit/void
- **Handle**: Privacy-preserving user identifier (@username)
- **HRS**: Handle Resolution Service
- **Satoshi**: Smallest unit of Bitcoin (0.00000001 BTC)
- **Wei**: Smallest unit of Ethereum (10^-18 ETH)
- **AML**: Anti-Money Laundering
- **KYC**: Know Your Customer
- **OFAC**: Office of Foreign Assets Control (US sanctions)

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Dec 29, 2025 | Architecture Team | Initial comprehensive design |

---

**Next Steps**

1. Review and approve architecture
2. Set up development environment
3. Deploy Blnk ledger (dev)
4. Build Handle Service prototype
5. Integrate mobile apps with APIs
6. Begin Phase 1 implementation

---

*For questions or updates to this document, contact the architecture team.*
