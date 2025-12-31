# Titan Wallet Documentation

This folder contains all architectural and planning documentation for the Titan Wallet real-time payments system.

## Latest Documents (2025-12-30)

### 🎉 NEW: Welcome Back!
- **[../WELCOME_BACK.md](../WELCOME_BACK.md)** - **START HERE** 🔥
  - Quick overview of what's been built
  - 2 services complete and running
  - 5-minute test guide

- **[../PROGRESS_REPORT_2025-12-30.md](../PROGRESS_REPORT_2025-12-30.md)** - Detailed progress report
  - Complete implementation details
  - Payment Router fully built
  - Code statistics and metrics

- **[../BUILD_COMPLETE_SUMMARY.md](../BUILD_COMPLETE_SUMMARY.md)** - Final summary
  - All deliverables listed
  - Remaining work breakdown
  - Time estimates

### 🎯 Implementation Status
- **[../IMPLEMENTATION_STATUS_2025-12-30.md](../IMPLEMENTATION_STATUS_2025-12-30.md)** - **TRACK PROGRESS**
  - Real-time implementation progress (25% complete)
  - HRS Service ✅ LIVE on port 8001
  - Payment Router ✅ COMPLETE
  - Encryption package ✅ COMPLETE
  - 6 remaining services - implementation patterns ready
  - Next steps and priorities

### 📋 Current Plan
- **[TITAN_WALLET_RESTRUCTURING_PLAN_2025-12-30.md](TITAN_WALLET_RESTRUCTURING_PLAN_2025-12-30.md)** - **START HERE**
  - Final 7-repository hybrid architecture plan
  - Consumer vs Merchant app separation
  - Blnk ledger integration strategy
  - Migration timeline and team ownership

### 🏗️ Architecture Documents
- **[ARCHITECTURE_V2_CORRECTED_2025-12-30.md](ARCHITECTURE_V2_CORRECTED_2025-12-30.md)** - Most complete architecture
  - All 8+ microservices detailed
  - Handle Resolution Service (HRS) design
  - Payment Router, ACH Service, Reconciliation
  - End-to-end transaction flows

- [INTEGRATED_FLOW_ARCHITECTURE_2025-12-30.md](INTEGRATED_FLOW_ARCHITECTURE_2025-12-30.md)
  - Complete payment flow sequences
  - Integration patterns between services

- [ARCHITECTURE_2025-12-30.md](ARCHITECTURE_2025-12-30.md) - Original architecture
  - Initial design (superseded by V2)

### 🔌 API & Specifications
- [API_SPECIFICATION_2025-12-30.md](API_SPECIFICATION_2025-12-30.md)
  - REST API endpoints for all services
  - Request/response schemas
  - Webhook specifications (Trice.co, Banking providers)

### 🔒 Performance & Security
- **[ENCRYPTION_STRATEGY_2025-12-30.md](ENCRYPTION_STRATEGY_2025-12-30.md)** - ⚠️ CRITICAL - ALL DATA ENCRYPTED
  - Defense-in-depth encryption at ALL layers
  - Data at rest, in transit, and in use
  - AWS KMS key management & rotation
  - PII/financial data protection (AES-256-GCM)
  - GDPR, SOC 2, PCI DSS compliance

- [PERFORMANCE_SECURITY_2025-12-30.md](PERFORMANCE_SECURITY_2025-12-30.md)
  - Sub-10ms HRS latency requirements
  - Security patterns (JWT, authentication)
  - Fraud detection strategies
  - Idempotency and rate limiting

### 🛠️ Development Guides
- **[DOCKER_DEVELOPMENT_GUIDE_2025-12-30.md](DOCKER_DEVELOPMENT_GUIDE_2025-12-30.md)** - Complete Docker setup
  - Full docker-compose.yml configuration
  - Daily development workflow
  - Mobile app integration
  - Hot reload setup
  - Troubleshooting guide

- [PROTOTYPE_GUIDE_2025-12-30.md](PROTOTYPE_GUIDE_2025-12-30.md)
  - Quick start for building prototypes
  - Local development setup

---

## Document Evolution Timeline

| Date | Document | Purpose |
|------|----------|---------|
| 2025-12-30 | TITAN_WALLET_RESTRUCTURING_PLAN | **Repository structure & migration plan** |
| 2025-12-29 | ARCHITECTURE_V2_CORRECTED | Corrected microservices architecture |
| 2025-12-29 | INTEGRATED_FLOW_ARCHITECTURE | Payment flow integration patterns |
| 2025-12-29 | PROTOTYPE_GUIDE | Development guide for prototypes |
| 2025-12-29 | PERFORMANCE_SECURITY | Non-functional requirements |
| 2025-12-29 | API_SPECIFICATION | API contracts and schemas |
| 2025-12-29 | ARCHITECTURE | Initial architecture (superseded) |

---

## Reading Order for New Team Members

1. **[TITAN_WALLET_RESTRUCTURING_PLAN_2025-12-30.md](TITAN_WALLET_RESTRUCTURING_PLAN_2025-12-30.md)** - Understand repository structure
2. **[ARCHITECTURE_V2_CORRECTED_2025-12-30.md](ARCHITECTURE_V2_CORRECTED_2025-12-30.md)** - Deep dive into services
3. **[API_SPECIFICATION_2025-12-30.md](API_SPECIFICATION_2025-12-30.md)** - Learn the API contracts
4. **[INTEGRATED_FLOW_ARCHITECTURE_2025-12-30.md](INTEGRATED_FLOW_ARCHITECTURE_2025-12-30.md)** - See how it all fits together
5. **[PERFORMANCE_SECURITY_2025-12-30.md](PERFORMANCE_SECURITY_2025-12-30.md)** - Understand requirements

---

## Quick Reference

### Key Architectural Decisions
- **7 Repositories**: 1 backend monorepo + 4 mobile apps + 1 admin + 1 contracts
- **Backend Tech Stack**: Go microservices + Blnk ledger + PostgreSQL + Redis
- **Mobile Apps**: Native Swift (iOS) + Kotlin (Android) for both Consumer & Merchant
- **API Contracts**: OpenAPI specs with code generation for all platforms
- **RTP Provider**: Trice.co for instant bank transfers

### Core Services
1. **Handle Resolution Service (HRS)** - Sub-10ms @handle lookup
2. **Payment Router** - Orchestrates all payment types (RTP, ACH, wallet)
3. **ACH Service** - Plaid integration for bank linking
4. **Reconciliation** - Daily ledger reconciliation with Blnk
5. **Auth Service** - JWT-based authentication
6. **Notification Service** - Push notifications (APNs/FCM)
7. **User Management** - KYC and user profiles
8. **Webhook Service** - Inbound webhooks from Trice.co & banking providers

---

Last updated: 2025-12-30
