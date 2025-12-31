# iOS Wallet App Analysis - Solid Banking Platform

**Document Date:** 2025-12-30
**Location:** `/external_repos/ios-wallet-app/`
**Total Swift Files:** 236
**Total Lines of Code:** ~42,000
**Architecture:** UIKit with Storyboards
**Minimum iOS:** 14.0+

---

## Executive Summary

The `ios-wallet-app` is a **production-ready, feature-complete banking wallet application** built for Solid.fi's banking platform. This app provides an excellent foundation for Titan Wallet's consumer and merchant iOS applications, with comprehensive features including authentication, KYC/KYB, bank accounts, cards, payments, and more.

## ✅ Monitoring Stack Complete

Before analyzing the iOS app, the monitoring infrastructure was successfully completed:

**Created Files:**
- `docker-compose.monitoring.yml` - Full monitoring stack configuration
- `monitoring/prometheus/prometheus.yml` - Metrics collection config
- `monitoring/prometheus/alerts.yml` - 20+ alert rules including HRS sub-10ms SLA
- `monitoring/grafana/provisioning/` - Auto-provisioned datasources and dashboards
- `monitoring/grafana/dashboards/titan-overview.json` - Main service overview dashboard
- `monitoring/loki/loki-config.yml` - Log aggregation with 30-day retention
- `monitoring/promtail/promtail-config.yml` - Log shipping configuration
- `monitoring/alertmanager/alertmanager.yml` - Alert routing with team-based notifications
- `monitoring/README.md` - Complete monitoring documentation

**To start monitoring:**
```bash
cd titan-backend-services
docker-compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d

# Access dashboards:
# Grafana: http://localhost:3001 (admin/admin)
# Prometheus: http://localhost:9090
# AlertManager: http://localhost:9093
```

---

## Architecture Overview

### Technology Stack

**Language & Framework:**
- Swift 5.0+
- UIKit (Storyboard-based, NOT SwiftUI)
- iOS 14.0+ target
- CocoaPods for dependency management

**Key Dependencies:**
- **Plaid** - ACH linking and bank account verification
- **GooglePlaces** - Address autocomplete
- **Auth0** - Passwordless authentication
- **VGS (Very Good Security)** - PCI-compliant card data tokenization
- **Firebase** - Analytics and Crashlytics
- **Alamofire** - HTTP networking
- **MercariQRScanner** - QR code scanning
- **RNCryptor** - Local encryption
- **SwiftKeychainWrapper** - Secure storage
- **SDWebImage** - Image loading and caching
- **SkeletonView** - Loading state animations
- **Analytics (Segment)** - Product analytics

### Project Structure

```
Solid/
├── App/                           # App delegate, Info.plist
├── Resources/                     # Assets, localization
├── Storyboards/                   # 13 storyboard files
│   ├── Auth.storyboard           # Login/signup flows
│   ├── KYC.storyboard            # Personal KYC verification
│   ├── KYB.storyboard            # Business KYB verification
│   ├── Dashboard.storyboard      # Main home screen
│   ├── Account.storyboard        # Bank account management
│   ├── Card.storyboard           # Card details & management
│   ├── CardManagement.storyboard # Card controls & settings
│   ├── Transaction.storyboard    # Transaction history
│   ├── Contact.storyboard        # Contacts management
│   ├── Pay.storyboard            # Send money flows
│   ├── Funds.storyboard          # Add funds (ACH pull)
│   ├── RCD.storyboard            # Receive money
│   └── LaunchScreen.storyboard
│
└── Source/Classes/
    ├── Account Origination/
    │   ├── Auth/                 # Auth0 passwordless login
    │   ├── KYC/                  # Personal identity verification
    │   ├── KYB/                  # Business verification
    │   ├── Account/              # Account creation
    │   └── ProgramConfig/        # App configuration
    │
    ├── Post Origination/
    │   ├── Home/                 # Dashboard/home screen
    │   ├── Cards/                # Card management & Apple Wallet provisioning
    │   ├── Transaction/          # Transaction history & details
    │   ├── Send/                 # Payment sending (ACH, wire, check, Visa)
    │   ├── Contact/              # Contacts & payees
    │   ├── Fund/                 # Add funds via ACH/Plaid
    │   ├── RCD/                  # Receive money flows
    │   └── AdditionalAccount/    # Multiple account support
    │
    ├── Networking/
    │   ├── APIManager.swift      # Alamofire-based API client
    │   ├── EndpointType.swift    # API endpoint definitions
    │   └── EndpointItem.swift    # ~350 lines of endpoint mappings
    │
    ├── Components/
    │   └── Base Class/           # Reusable UI components
    │
    ├── Helper/                    # Utility classes
    ├── JailBroken/               # Security - jailbreak detection
    │
    └── Utilities/
        ├── App Utils/            # AppMetaData.json config
        ├── Constants/            # Config.swift, API keys
        ├── Customisation/        # Theming & branding
        └── Extensions/           # Swift extensions
```

---

## Feature Inventory

### ✅ Account Origination (Onboarding)

1. **Authentication**
   - Auth0 passwordless authentication (SMS OTP)
   - Biometric authentication (Face ID / Touch ID)
   - Token-based API authentication
   - Session management

2. **KYC (Know Your Customer) - Personal**
   - Personal information collection
   - Persona Inquiry integration for identity verification
   - Government ID verification
   - SSN collection and encryption
   - Address verification with Google Places
   - Employment information
   - Beneficial ownership disclosure

3. **KYB (Know Your Business) - Business**
   - Business entity creation
   - Business information collection
   - NAICS code selection
   - EIN verification
   - Business address verification
   - Ownership disclosure generation
   - Business projection/financials
   - Multi-member/owner support

4. **Account Creation**
   - Programmatic bank account creation
   - Multiple account types support
   - Account nickname customization

### ✅ Post-Origination Features

1. **Dashboard (Home)**
   - Account balance display
   - Recent transactions list
   - Quick actions (Send, Add Funds, etc.)
   - Account switcher (multiple accounts)
   - Cards overview

2. **Bank Accounts**
   - View account details
   - Account statements (PDF download)
   - Account routing/account number display
   - Close account functionality
   - Additional account creation

3. **Debit Cards**
   - Virtual and physical card management
   - Card details (masked PAN, CVV via VGS)
   - **Apple Wallet provisioning** (In-app provisioning)
   - Card activation
   - Card controls:
     - Lock/unlock card
     - Set spending limits
     - Transaction categories (online, ATM, international)
   - Card replacement (lost/stolen)
   - View card PIN
   - Order physical card with shipping address

4. **Payments (Send Money)**
   - **ACH transfers** (internal and external)
   - **Domestic wire transfers**
   - **Check payments** (mail physical check)
   - **Visa Direct** (send to debit card)
   - **Intra-bank transfers** (between own accounts)
   - QR code scanning for payment requests
   - Contact-based payments (saved payees)
   - Scheduled/recurring payments
   - Payment confirmation and receipts

5. **Receive Money (RCD)**
   - Generate payment QR codes
   - Share account/routing details
   - Direct deposit information

6. **Add Funds (Pull)**
   - **Plaid integration** for bank linking
   - ACH pull from external accounts
   - Deposit check (mobile check deposit)
   - Transfer from another account

7. **Contacts & Payees**
   - Save payment recipients
   - Contact management
   - Quick pay from contacts
   - Recent payees

8. **Transactions**
   - Transaction history with infinite scroll
   - Search and filter transactions
   - Transaction details (date, amount, status, memo)
   - Transaction receipts
   - Export transactions
   - Pending vs. settled transactions

### 🔒 Security Features

- **Jailbreak Detection** - Prevents app usage on compromised devices
- **Keychain Storage** - Secure token and credential storage
- **PII Encryption** - Local encryption for sensitive data (RNCryptor)
- **VGS Tokenization** - PCI-compliant card data handling
- **Biometric Authentication** - Face ID / Touch ID
- **SSL Pinning** (if configured in Alamofire)

### 🎨 Customization & Configuration

**AppMetaData.json** allows extensive white-labeling:
- Brand colors (light and dark mode)
- Feature toggles:
  - Enable/disable pull funds
  - Enable/disable specific payment types
  - Enable/disable card mailing
  - Enable/disable Apple Wallet
- Environment configuration (prod/test)
- Auth0 credentials
- Segment analytics key
- Support email and help center URLs
- Terms of service and privacy policy links
- Supported countries list

---

## API Integration

### Endpoint Coverage

The app includes API integrations for:

1. **Person Management**
   - Create/update person profile
   - KYC submission
   - Persona hosted URL for identity verification

2. **Business Management**
   - Create/update business
   - KYB submission
   - Ownership disclosure
   - NAICS code lookup
   - Business projections

3. **Account Management**
   - Create accounts
   - List accounts
   - Get account details
   - Account statements

4. **Card Management**
   - List cards
   - Get card details (VGS integration)
   - Update card status (lock/unlock)
   - Set card controls
   - Apple Wallet provisioning

5. **Transaction Management**
   - List transactions
   - Get transaction details
   - Search/filter transactions

6. **Payment Initiation**
   - ACH transfers
   - Wire transfers
   - Check payments
   - Visa Direct

7. **Contacts**
   - Create/update contacts
   - List contacts

8. **Authentication**
   - Auth0 token exchange
   - Token refresh

---

## Adaptation Plan for Titan Wallet

### Option 1: Fork & Rebrand (Fastest - 2-3 weeks)

**Pros:**
- Production-ready codebase with 42K+ lines
- All major banking features already implemented
- Proven architecture and security
- Immediate feature completeness

**Cons:**
- UIKit/Storyboard architecture (not modern SwiftUI)
- Tightly coupled to Solid.fi API structure
- Heavy dependency list (CocoaPods)
- Requires API endpoint remapping

**Steps:**
1. Fork the repository into `titan-consumer-ios`
2. Update branding in `AppMetaData.json`
3. Remap API endpoints from Solid.fi to Titan backend services
4. Replace Auth0 with Titan Auth Service (port 8004)
5. Update Plaid integration for Titan ACH Service (port 8003)
6. Remove VGS, integrate with Titan's encryption
7. Update Firebase project
8. Test all flows end-to-end

**Timeline:** 2-3 weeks for consumer app

### Option 2: Hybrid Approach (Recommended - 4-6 weeks)

**Extract core components and rebuild with SwiftUI:**

**Phase 1: Extract Reusable Components (1 week)**
- Networking layer (`APIManager.swift`, endpoint definitions)
- Security utilities (jailbreak detection, keychain, encryption)
- Data models
- Helper utilities and extensions

**Phase 2: Build SwiftUI Shell (1 week)**
- Modern SwiftUI navigation
- MVVM architecture
- Combine framework for reactive programming
- Clean separation of concerns

**Phase 3: Port Features (2-3 weeks)**
- Auth flow (prioritize)
- Dashboard/Home
- Accounts view
- Send/receive payments
- Transaction history
- Cards (if needed)

**Phase 4: Integration & Testing (1 week)**
- Connect to Titan backend services
- End-to-end testing
- Security audit
- Performance optimization

**Pros:**
- Modern SwiftUI codebase
- Easier to maintain and extend
- Better performance
- Cleaner architecture
- Reuse proven logic and security

**Cons:**
- Longer development time
- Requires rebuilding UI
- More testing required

### Option 3: Start from Scratch with Reference (8-12 weeks)

Build completely new SwiftUI app using ios-wallet-app as **reference only**.

**Pros:**
- Full control over architecture
- Modern SwiftUI from day one
- Clean codebase tailored to Titan
- Minimal technical debt

**Cons:**
- Longest timeline
- Must reimplement all features
- Higher risk of bugs
- Recreating security features

---

## Recommended Approach: **Option 1 (Fork & Rebrand) for MVP**

### Why Fork First?

1. **Speed to Market:** Get a functional app in 2-3 weeks vs. 2-3 months
2. **Feature Complete:** All banking features already built and tested
3. **Proven Security:** Security measures (jailbreak detection, encryption, VGS) already implemented
4. **De-risk Development:** Use working code as foundation, refactor later
5. **Learn the Domain:** Understand banking app complexity through working code

### Titan-Specific Adaptations Required

#### 1. Backend Integration

**Replace Solid.fi APIs with Titan services:**

| Solid.fi Endpoint | Titan Service | Port | Notes |
|-------------------|---------------|------|-------|
| `/auth/*` | Auth Service | 8004 | Replace Auth0 with Titan JWT |
| `/person/*` | User Management | 8006 | KYC integration |
| `/business/*` | User Management | 8006 | KYB integration |
| `/account/*` | Blnk Ledger | 5001 | Map to ledger balances |
| `/card/*` | Payment Router | 8002 | Card management via router |
| `/transaction/*` | Payment Router | 8002 | Transaction history |
| `/ach/*` | ACH Service | 8003 | Plaid integration |
| `/wire/*` | Payment Router | 8002 | Wire transfer orchestration |

#### 2. Handle Resolution

**Add Titan's @handle feature:**
- Integrate HRS service (port 8001) for `@username` resolution
- Update Send flow to support @handles alongside account/routing numbers
- Add handle search in Contacts

#### 3. Real-Time Payments

**Integrate Trice.co RTP:**
- Connect to Webhook Service (port 8007) for RTP notifications
- Add instant payment confirmation UI
- Handle RTP request/response flows

#### 4. Authentication Changes

**Replace Auth0 with Titan Auth Service:**
- Update login flow to call `http://localhost:8004/auth/login`
- Implement JWT token management with Redis
- Store tokens in Keychain
- Add token refresh logic

#### 5. Ledger Integration

**Map Solid accounts to Blnk ledger:**
- Create ledger accounts via Blnk API (port 5001)
- Fetch balances from ledger
- Record transactions in double-entry format
- Implement reconciliation hooks

#### 6. Remove/Replace Dependencies

| Dependency | Action | Reason |
|------------|--------|--------|
| Auth0 | Remove | Using Titan Auth Service |
| VGS | Remove | Titan has own encryption (`pkg/encryption`) |
| Solid.fi SDK | Remove | Not needed |
| Firebase | Optional | Keep for analytics/crashlytics |
| Segment | Optional | Replace with custom analytics if needed |
| Plaid | **Keep** | ACH Service uses Plaid |
| GooglePlaces | **Keep** | Address autocomplete useful |

---

## Feature Mapping: Consumer vs. Merchant Apps

### Consumer App (Priority 1)

**Core Features from ios-wallet-app:**
- ✅ Auth (simplified - no KYC for MVP)
- ✅ Dashboard (balance, recent transactions)
- ✅ Send money (@handle, account/routing)
- ✅ Receive money (QR code, @handle)
- ✅ Transaction history
- ✅ Contacts
- ⚠️ Cards (optional for MVP)
- ⚠️ Add funds (optional for MVP)

### Merchant App (Priority 2)

**New features to add (not in ios-wallet-app):**
- ❌ Payment acceptance (QR code generation for customers)
- ❌ Sales dashboard (daily/weekly/monthly revenue)
- ❌ Customer management
- ❌ Invoice generation
- ❌ Settlement tracking
- ❌ Merchant analytics

**Can reuse from ios-wallet-app:**
- ✅ Auth flow
- ✅ Dashboard structure
- ✅ Transaction history
- ✅ Settings/profile
- ✅ Networking layer

---

## Next Steps - Implementation Roadmap

### Week 1: Setup & Backend Integration
- [ ] Fork ios-wallet-app to `titan-consumer-ios` repo
- [ ] Update branding (app name, colors, icons)
- [ ] Set up Xcode project with Titan certificates
- [ ] Create API endpoint mapping document
- [ ] Implement `TitanAPIManager.swift` wrapper for Titan services
- [ ] Update `EndpointType.swift` with Titan endpoints

### Week 2: Core Features
- [ ] Replace Auth0 with Titan Auth Service integration
- [ ] Update Account views to use Blnk ledger API
- [ ] Integrate HRS for @handle resolution
- [ ] Update Send flow with @handle support
- [ ] Connect Transaction view to Payment Router

### Week 3: Testing & Polish
- [ ] End-to-end testing of all flows
- [ ] Security audit (jailbreak, encryption, keychain)
- [ ] Performance testing
- [ ] UI polish and bug fixes
- [ ] App Store assets preparation

### Week 4: Merchant App
- [ ] Fork consumer app to `titan-merchant-ios`
- [ ] Add merchant-specific features (payment acceptance, sales dashboard)
- [ ] Test merchant payment flows
- [ ] Integrate merchant analytics

---

## Code Quality Assessment

### ✅ Strengths

1. **Comprehensive Feature Set:** Everything a banking app needs
2. **Security-First:** Jailbreak detection, encryption, VGS, keychain
3. **Production-Ready:** Used by Solid.fi customers in production
4. **Well-Organized:** Clear separation between account origination and post-origination
5. **Configurable:** AppMetaData.json for easy branding
6. **Third-Party Integrations:** Plaid, Google Places, Auth0 already working

### ⚠️ Technical Debt

1. **UIKit/Storyboards:** Not modern SwiftUI (but mature and stable)
2. **Large Storyboard Files:** Can be slow to open in Xcode
3. **Tight Coupling:** Some view controllers have business logic
4. **Limited Unit Tests:** Primarily relies on manual testing
5. **CocoaPods:** Older dependency management (SPM is preferred now)

### Refactoring Opportunities (Post-MVP)

1. Migrate to SwiftUI incrementally
2. Add comprehensive unit test coverage
3. Migrate from CocoaPods to Swift Package Manager
4. Extract business logic into view models (MVVM)
5. Implement repository pattern for data layer
6. Add UI tests with XCTest

---

## Risk Assessment

### Low Risk ✅
- Using proven production code
- Well-established dependencies
- Clear API structure

### Medium Risk ⚠️
- Backend API mapping complexity
- Auth0 → Titan Auth migration
- VGS removal (need alternative for card data)
- Testing coverage gaps

### High Risk 🔴
- Regulatory compliance (ensure proper licensing)
- Security audit required for production
- Apple Pay entitlements (requires Apple approval)
- PCI compliance for card features

---

## Recommendations

### For MVP (Next 4 Weeks)

1. **Fork ios-wallet-app immediately** - Don't start from scratch
2. **Focus on consumer app first** - Merchant app can wait
3. **Strip down to essentials:**
   - Remove: Cards, KYC/KYB (use simplified onboarding)
   - Keep: Auth, Send, Receive, Transactions, Contacts
4. **Connect to Titan backend services:**
   - Auth Service (8004)
   - HRS (8001)
   - Payment Router (8002)
   - User Management (8006)
5. **Test thoroughly** - Banking apps require extensive QA

### For Production (Post-MVP)

1. **Security audit** - Hire third-party security firm
2. **Compliance review** - Ensure banking regulations compliance
3. **Performance optimization** - Profile and optimize critical paths
4. **Accessibility** - VoiceOver support, dynamic type
5. **Localization** - Multi-language support if needed
6. **Analytics integration** - Track user flows and errors

---

## Files to Review

**Critical files to understand:**

1. **`APIManager.swift`** - Core networking implementation
2. **`EndpointType.swift`** - All API endpoint definitions
3. **`AppMetaData.json`** - App configuration
4. **`Config.swift`** - API keys and environment settings
5. **Auth flow:**
   - `AuthVC.swift`
   - `AuthViewModel.swift`
6. **Send money:**
   - `PaymentVC.swift`
   - `PaymentViewModel.swift`

---

## Conclusion

The ios-wallet-app provides a **massive head start** for Titan Wallet's iOS development. With 42,000 lines of production-tested code covering all major banking features, forking and adapting this app is significantly faster than building from scratch.

**Estimated Timeline:**
- **Fork & Adapt Approach:** 2-3 weeks for functional MVP
- **SwiftUI Rebuild:** 4-6 weeks for modern architecture
- **From Scratch:** 8-12 weeks with higher risk

**Recommendation:** Start with Option 1 (Fork & Rebrand), ship MVP quickly, then refactor to SwiftUI in v2.0 once product-market fit is validated.

---

## Status Update

✅ **Monitoring & Observability Stack** - COMPLETE
- Full Prometheus + Grafana + Loki + AlertManager setup
- 20+ alert rules including HRS sub-10ms SLA monitoring
- Auto-provisioned dashboards
- 30-day metrics and logs retention

✅ **iOS Wallet App Analysis** - COMPLETE
- Comprehensive feature inventory
- Architecture documentation
- Adaptation plan with 3 options
- Implementation roadmap

🎯 **Next:** Await user decision on iOS app approach (Fork vs. Rebuild vs. Reference)
