# Titan Wallet - Complete Interactive Prototype Guide

## Overview

This is a fully clickable, interactive prototype demonstrating **all aspects** of the Titan Wallet payment system, including user flows, HRS (Handle Resolution Service) operations, and comprehensive admin dashboard functionality.

**Files:**
- `titan_wallet_complete_prototype.html` - Full prototype with all flows
- `titan_wallet_prototype.html` - Simplified version

## How to Use

1. Open `titan_wallet_complete_prototype.html` in any modern web browser
2. The prototype runs entirely in the browser (no backend required)
3. Click through any flow - all interactions are functional
4. Access admin dashboard from welcome screen or settings

---

## Complete Flow Coverage

### 1. User Onboarding & KYC ✅

**Path:** Welcome → Sign Up → KYC → Create @Handle → Link Bank → Home

**What's Demonstrated:**
- Sign up form with validation
- KYC verification process with PII collection
- @Handle creation with real-time availability checking via HRS
- Plaid bank account linking simulation
- Full onboarding completion flow

**Key Features:**
- Handle validation rules (3-20 characters, unique)
- Real-time handle availability check
- KYC compliance messaging
- Secure Plaid integration simulation

---

### 2. ACH Pull (Wallet Funding) ✅

**Path:** Home → Add Money → Enter Amount → Initiate ACH Pull

**What's Demonstrated:**
- Link bank account via Plaid
- Initiate ACH debit from external bank
- **Inflight → Settled state transition** (PM Concern #2 addressed)
- Settlement timeline (1-3 business days)
- Pending vs Available balance display

**Key Features:**
- Linked bank account display
- Settlement timeline warnings
- Pending transaction tracking
- Available vs Pending balance separation

**Architecture Points:**
- ACH transfers start as "inflight" in Blnk
- Funds show in "Pending" balance until settled
- Webhook handler commits transaction on settlement
- Voids transaction if ACH fails

---

### 3. P2P Same-Network Payment ✅

**Path:** Home → Send → Enter @emily → Amount → Review → Confirm

**What's Demonstrated:**
- Handle resolution via HRS
- Instant settlement (<50ms)
- Same-network routing detection
- Fraud check (low risk score)
- Biometric confirmation simulation

**Key Features:**
- Real-time @handle resolution
- Network detection (Same Network = Instant)
- Risk scoring display
- Face ID confirmation prompt
- Instant balance update

**HRS Flow:**
1. Lookup @emily in HRS (2ms cache hit)
2. Resolve to wallet_id and balance_id
3. Fraud check: Risk score 15/100 (Low)
4. Route: Same Network (Direct Blnk transfer)
5. Execute: <50ms total

---

### 4. P2P Cross-Network RTP Payment ✅

**Path:** Home → Send → Enter @bob@phonepe → Amount → Review → Confirm

**What's Demonstrated:**
- Cross-network handle detection
- RTP routing via Trice.co
- **Inflight → Settled state transition** (2-10 seconds)
- Settlement finality check (PM Concern #2 addressed)
- Multi-step settlement notifications

**Key Features:**
- External network detection (@handle@network)
- RTP settlement delay simulation (3 seconds)
- Inflight transaction status
- Settlement completion notification
- Final balance update

**HRS Flow:**
1. Parse handle: @bob@phonepe
2. Detect external network: phonepe
3. Query external routing info
4. Fraud check: Risk score varies
5. Route: Cross-Network RTP via Trice.co
6. Expected time: 2-10 seconds

**Settlement Flow:**
1. Create inflight Blnk transaction (holds funds)
2. Send RTP via Trice.co
3. Wait for settlement (2-10s)
4. Receive Trice webhook: "SETTLED"
5. Commit Blnk transaction (finalizes)

---

### 5. QR Code Merchant Payment ✅

**Path:** Home → Scan QR → Simulate Scan → Confirm

**What's Demonstrated:**
- QR code scanning interface
- Merchant payment flow
- Pre-filled payment details from QR
- Instant settlement (same-network)
- Receipt confirmation

**Key Features:**
- QR scanner UI
- Auto-populated merchant @handle and amount
- Same flow as P2P (instant for same-network merchants)

**QR Code Format:**
```
titan://pay?handle=@coffee_shop&amount=5.75&invoice=inv_12345
```

---

### 6. Balance Management ✅

**Path:** Home → View Balance | Activity → View History

**What's Demonstrated:**
- Available Balance (committed funds)
- Pending Balance (inflight/settling funds)
- Total Balance (available + pending)
- Transaction history with status badges
- Settlement finality indicators

**Key Features:**
- Three-tier balance display:
  - **Available:** $1,234.56 (can spend now)
  - **Pending:** $50.00 (awaiting settlement)
  - **Total:** $1,284.56
- Transaction list with:
  - Status badges (Completed, Pending, Failed)
  - Route information (Same Network, RTP, ACH)
  - Settlement estimates for pending transactions

---

### 7. HRS (Handle Resolution Service) Flow ✅

**Path:** Send → Enter @handle → Show HRS Resolution Process

**What's Demonstrated:**
- Complete HRS resolution pipeline
- Cache hit detection (Redis)
- Network detection (Same vs Cross)
- Fraud check with risk scoring
- Route selection logic
- Performance metrics

**HRS Steps Visualized:**

**Step 1: Handle Lookup**
- Query: @emily
- Cache: Hit (Redis)
- Latency: 2ms

**Step 2: Network Detection**
- Network: titan-wallet (Same Network)
- Wallet ID: wal_002
- Balance ID: bal_002

**Step 3: Fraud Check**
- Risk Score: 15/100 (Low)
- Velocity: 3/10 transactions (1h)
- Amount: ✓ Normal
- Location: ✓ Expected

**Step 4: Route Selection**
- Route: Same Network
- Method: Direct Blnk Transfer
- Time: <50ms
- Fee: $0.00

**Performance Metrics:**
- Total Resolution Time: 8ms
- Cache Hit Rate: 94%
- Fraud Check Time: 3ms

---

### 8. Admin Dashboard (6 Tabs) ✅

**Path:** Welcome → Admin Dashboard | Settings → Admin Dashboard

#### Tab 1: Overview
**Metrics:**
- Active Users: 1,234
- Total Volume: $2.4M
- Transactions: 5,678
- Fraud Rate: 0.03%

**System Health:**
- HRS Service: ✓ Healthy
- Payment Router: ✓ Healthy
- Blnk Ledger: ✓ Healthy
- Trice.co RTP: ✓ Connected

**Alerts:**
- High Velocity Alert: User @bob - 15 txns/hour
- Reconciliation Complete: Daily recon passed

#### Tab 2: HRS Analytics
**Metrics:**
- Lookups (24h): 127K
- Cache Hit Rate: 94%
- Avg Latency: 3ms
- Success Rate: 99.98%

**Performance Breakdown:**
- Cache Hits (Redis): 119,380 (94%)
- Database Queries: 7,620 (6%)

**Cross-Network Routing:**
- Same Network: 4,521 txns (<50ms avg)
- Cross-Network RTP: 1,157 txns (3.2s avg)

**Top External Networks:**
- @phonepe: 345 txns
- @venmo: 289 txns
- @cashapp: 201 txns

#### Tab 3: Fraud Detection Center
**Metrics:**
- Fraud Rate: 0.03%
- Blocked (24h): 17
- Challenged: 42
- Amount Saved: $12.4K

**Flagged Transactions:**
- txn_high_risk_001: Risk Score 92/100
  - Flags: Unusual amount, new recipient, high velocity
  - Actions: Block | Approve
- txn_med_risk_045: Risk Score 58/100
  - Flags: New location detected
  - Actions: Block | Approve

**Velocity Limits Status:**
- @bob (Exceeded): 15/10 txns ⚠️
- @alice (Normal): 3/10 txns ✓
- @emily (Normal): 7/10 txns ✓

#### Tab 4: User Management
**Features:**
- User search (by @handle, email, phone)
- User status (Active, Suspended)
- Balance visibility
- KYC level display
- Suspension management

**Sample Users:**
- @jane: Active, $1,234.56, KYC Level 2 ✓
- @bob: Suspended (High velocity), $45.20
- @emily: Active, $2,567.89, KYC Level 3 ✓

#### Tab 5: Transaction Investigation
**Features:**
- Transaction search (by ID, @handle, amount)
- Full transaction details
- HRS context (resolution time, risk score)
- Blnk transaction ID linkage
- Trice.co payment ID (for RTP)
- Settlement status tracking

**Sample Transactions:**
- txn_abc123: @jane → @emily, $100, Same Network
  - Blnk: txn_001, HRS Latency: 8ms, Risk: 15
- txn_xyz789: ACH Pull, $50, Pending Settlement (Est. Jan 17)
  - Blnk: inflight, ACH ID: ach_pull_456
- txn_rtp_321: @external_bob@phonepe → @jane, $200, RTP
  - Blnk: txn_002, Trice: rtp_trice_789, Settlement: 3.2s

#### Tab 6: Reconciliation Dashboard
**Daily Reconciliation Status:**
- Last Run: Jan 15, 2025 at 02:00 UTC
- Status: ✓ Passed

**Blnk ↔ Banking Provider:**
- Blnk Total Balance (USD): $10,234,567.89
- FBO Account Balance: $10,234,567.89
- Difference: $0.00 ✓ MATCH

**Blnk ↔ Trice.co:**
- Blnk RTP Transactions: 1,157
- Trice.co RTP Transactions: 1,157
- Match Rate: 100% ✓

**Historical Reconciliation:**
- Jan 15: ✓ Passed
- Jan 14: ✓ Passed
- Jan 13: ⚠️ Manual Adjustment

---

### 9. Error Flows (All Edge Cases) ✅

**Path:** Settings → Demo Controls → Test Error Flows

#### Error 1: Insufficient Balance
**Trigger:** Send amount > available balance

**Message:**
```
Insufficient Balance

You do not have enough funds to complete this transaction.

Available: $1,234.56
Required: $2,000.00
```

#### Error 2: Fraud Block (PM Concern #3 addressed)
**Trigger:** High risk score transaction

**Message:**
```
Transaction Blocked

This transaction has been blocked due to suspicious activity.

Risk Score: 92/100
Flags: Unusual amount, high velocity

Please contact support if you believe this is an error.
```

**HRS Fraud Detection:**
- Velocity check: 15 txns/hour (limit: 10)
- Amount anomaly: $2,500 (avg: $150)
- New recipient + high amount
- Unusual location

#### Error 3: RTP Timeout
**Trigger:** RTP network doesn't respond

**Message:**
```
RTP Timeout

The RTP network did not respond in time. Your payment has been voided and funds returned to your balance.

Transaction ID: txn_timeout_123
```

**Recovery:**
- Inflight transaction voided in Blnk
- Funds returned to available balance
- User notified of failure

#### Error 4: ACH Failure
**Trigger:** Bank declines ACH pull

**Message:**
```
ACH Transfer Failed

Your bank declined this transfer.

Reason: Insufficient funds in source account
ACH ID: ach_fail_456
```

**Recovery:**
- Inflight Blnk transaction voided
- Pending balance decreased
- User notified

#### Error 5: Idempotency Replay (PM Concern #3 addressed)
**Trigger:** Duplicate payment request with same Idempotency-Key

**Test Flow:**
1. Send payment successfully
2. Retry same payment (network error simulation)
3. Idempotency middleware detects duplicate
4. Returns cached response instead of double-charging

**Message:**
```
Idempotency Replay

This payment was already processed.

Idempotency-Key matched a previous request. Returning cached response instead of creating duplicate transaction.

X-Idempotent-Replay: true
```

**Architecture:**
- Mandatory `Idempotency-Key` header on all POST requests
- Redis cache: `idempotency:{path}:{key}` → response (24h TTL)
- Prevents duplicate charges from network retries
- Returns 200 with cached response

---

### 10. Additional Features ✅

#### Velocity Limits Display
**Path:** Settings → Transaction Limits

**Shows:**
- Hourly Limits: 3/10 txns, $350/$1,000
- Daily Limits: 12/50 txns, $1,250/$5,000
- Visual progress bars
- Real-time tracking

#### Transaction History
**Features:**
- Recent transactions on home (3 most recent)
- Full history in Activity tab
- Status badges (Completed, Pending, Failed)
- Route information (Same Network, RTP, ACH)
- Settlement estimates for pending
- Click for details

#### Settings & Profile
**Features:**
- User profile (@handle, name)
- KYC status display
- Linked bank accounts
- Transaction limits
- Demo controls for testing

---

## Critical Architecture Points Demonstrated

### 1. ACH Pull / On-Ramping (PM Concern #1) ✅
**Solution:** Complete ACH Pull flow via Plaid

**Flow:**
1. User links bank via Plaid
2. Initiates ACH debit
3. Transaction created as "inflight" in Blnk
4. Funds show in "Pending" balance
5. Settlement webhook (1-3 days)
6. Blnk transaction committed
7. Funds move to "Available" balance

**Demonstrated:**
- Plaid integration simulation
- Inflight transaction status
- Pending vs Available balance separation
- Settlement notifications

### 2. Settlement Finality (PM Concern #2) ✅
**Solution:** Conditional settlement based on payment rail

**Flow:**
1. Incoming payment webhook from Trice.co
2. Check `SettlementStatus` and `Network`
3. If FedNow/TCH_RTP: **Status = "committed"** (final, irrevocable)
4. If ACH: **Status = "inflight"** (reversible for 60 days)
5. Create Blnk transaction with appropriate status
6. User sees "Available" (final) or "Pending" (reversible)

**Demonstrated:**
- FedNow RTP: Instant credit to Available balance
- ACH: Credit to Pending balance until settlement
- Settlement time display (RTP: 2-10s, ACH: 1-3 days)
- Final vs Pending indicators

### 3. Idempotency (PM Concern #3) ✅
**Solution:** Mandatory `Idempotency-Key` header + Redis deduplication

**Flow:**
1. Mobile app generates UUID for payment
2. Includes `Idempotency-Key: {uuid}` header
3. Backend checks Redis: `idempotency:/payments:{uuid}`
4. If exists: Return cached response (prevents duplicate)
5. If new: Process payment, cache response (24h TTL)
6. Network retry uses same key → no duplicate charge

**Demonstrated:**
- Test flow in Settings → Demo Controls
- Shows successful payment
- Shows retry with same key
- Shows idempotency replay message
- Prevents double-charging

### 4. Admin Dashboard (PM Concern #4) ✅
**Solution:** 6-tab comprehensive admin dashboard

**Tabs:**
1. Overview: System health, metrics, alerts
2. HRS Analytics: Performance, cache hits, routing
3. Fraud Detection: Risk scores, flagged transactions
4. User Management: Search, status, KYC, balances
5. Transaction Investigation: Full context, HRS data
6. Reconciliation: Blnk ↔ Banking Provider ↔ Trice.co

**Demonstrated:**
- Real-time metrics
- System health monitoring
- Fraud detection center
- Transaction investigation tools
- Reconciliation dashboard

### 5. NFC vs QR (PM Concern #5) ✅
**Solution:** QR Code for MVP, NFC for Phase 2

**MVP (Demonstrated):**
- QR code scanning interface
- Merchant QR payment flow
- Instant settlement (same-network)

**Phase 2 (Documented in architecture):**
- NFC/Tap-to-Pay
- EMV certification required
- Apple Pay/Google Pay integration

### 6. Rate Limiting (PM Concern #6) ✅
**Solution:** Reduced from 100 to 5 req/min (unauthenticated)

**Demonstrated in HRS:**
- 5 req/min unauthenticated (prevents username enumeration)
- 30 req/min authenticated
- Velocity limits: 10 txns/hour per user
- Admin dashboard shows velocity status

---

## HRS (Handle Resolution Service) Complete Flow

### Real-Time Resolution Demo
**Path:** Send → Enter @handle → Watch resolution status

**What Happens:**
1. User types @emily
2. HRS query triggered (300ms debounce)
3. Display: "🔍 Resolving via HRS..."
4. Resolution complete:
   - ✓ Found on Titan Wallet
   - Route: Same Network (Instant)

**For External Handle (@bob@phonepe):**
1. User types @bob@phonepe
2. HRS detects external network
3. Display: "✓ Found on phonepe"
4. Route: RTP (2-10 seconds)

### HRS Flow Visualization Page
**Path:** Send → Show HRS Resolution Process

**Displays 4-Step Process:**

1. **Handle Lookup**
   - Query: @emily
   - Cache Hit: Yes (Redis)
   - Latency: 2ms

2. **Network Detection**
   - Network: titan-wallet
   - Wallet ID: wal_002
   - Balance ID: bal_002

3. **Fraud Check**
   - Risk Score: 15/100 (Low)
   - Velocity: 3/10 transactions (1h)
   - Amount Check: ✓ Normal
   - Location: ✓ Expected

4. **Route Selection**
   - Route: Same Network
   - Method: Direct Blnk Transfer
   - Expected Time: <50ms
   - Fee: $0.00

**Performance Metrics:**
- Total Resolution Time: 8ms
- Cache Hit Rate: 94%
- Fraud Check Time: 3ms

---

## Technical Implementation Highlights

### State Management
```javascript
const appState = {
    currentUser: {
        handle: '@jane',
        name: 'Jane Doe',
        balance: 1234.56,
        pendingBalance: 50.00,
        walletId: 'wal_001',
        balanceId: 'bal_001'
    },
    transactions: [...],
    pendingPayment: null,
    adminTab: 'overview'
};
```

### Balance Update Logic
```javascript
function updateBalance() {
    // Available balance (committed funds)
    document.getElementById('balance-available').textContent =
        `$${appState.currentUser.balance.toFixed(2)}`;

    // Pending balance (inflight/settling funds)
    document.getElementById('balance-pending').textContent =
        `$${appState.currentUser.pendingBalance.toFixed(2)}`;
}
```

### Transaction Status Rendering
- **Sent:** Red icon, negative amount, route info
- **Received:** Green icon, positive amount, sender
- **ACH Pull:** Blue icon, pending badge, settlement estimate
- **RTP:** Blue icon, settlement time display

### Fraud Risk Scoring
```javascript
riskScore: Math.floor(Math.random() * 30)  // Low: 0-40
riskScore: Math.floor(Math.random() * 40)  // Medium: 41-70
riskScore: 92  // High: 71-100 (blocked)
```

---

## User Journey Paths

### Path 1: New User Onboarding
Welcome → Sign Up → KYC → @Handle → Link Bank → Home → Send Money → Success

### Path 2: Existing User - Same Network Payment
Home → Send → @emily → $100 → Confirm → Success (Instant)

### Path 3: Existing User - Cross Network Payment
Home → Send → @bob@phonepe → $200 → Confirm → RTP Settlement → Success

### Path 4: Existing User - Add Money
Home → Add Money → $50 → Initiate ACH → Pending → (Wait 1-3 days) → Settled

### Path 5: Merchant Payment
Home → Scan QR → Auto-fill → Confirm → Success (Instant)

### Path 6: Admin - Investigation
Admin → Transactions Tab → Search txn_abc123 → View Details

### Path 7: Admin - Fraud Monitoring
Admin → Fraud Tab → Review Flagged → Block/Approve

### Path 8: Error Handling
Home → Send → $2,000 (exceeds balance) → Insufficient Balance Error

---

## What's NOT Included (Scope Limitations)

1. **Request Money:** Placeholder page (not core flow)
2. **Card Issuing:** Not demonstrated (Phase 2)
3. **NFC Payments:** Not demonstrated (Phase 2)
4. **Withdrawal to Bank:** Not demonstrated (reverse ACH)
5. **Multi-Currency:** Not demonstrated (architecture supports)
6. **Cryptocurrency:** Not demonstrated (Blnk supports)

---

## Browser Compatibility

- ✅ Chrome/Edge (Recommended)
- ✅ Firefox
- ✅ Safari
- ✅ Mobile browsers (responsive design)

**No installation required** - open HTML file directly

---

## Next Steps for Production

1. **Backend Implementation:**
   - Go microservices (HRS, Payment Router, Reconciliation)
   - Blnk ledger integration
   - Trice.co RTP integration
   - Banking Provider selection and integration
   - Plaid ACH implementation

2. **Native Mobile Apps:**
   - iOS: Swift + SwiftUI
   - Android: Kotlin + Jetpack Compose
   - Biometric authentication
   - Keychain/Keystore token storage
   - SSL pinning

3. **Admin Dashboard:**
   - Retool deployment (recommended)
   - OR Custom Next.js app
   - RBAC implementation
   - Audit logging

4. **Infrastructure:**
   - Kubernetes (AWS EKS)
   - PostgreSQL clusters (Patroni)
   - Redis clusters (Sentinel)
   - Kong API Gateway
   - CloudFlare DDoS protection

5. **Compliance:**
   - KYC provider integration
   - AML screening
   - SAR reporting
   - PCI DSS Level 1 certification (if adding NFC)

---

## Demo Script (5 Minutes)

**Minute 1: Onboarding**
- Click "Get Started"
- Fill name, email, phone
- Complete KYC
- Create @handle (check availability)
- Link bank account

**Minute 2: Same-Network Payment**
- Send $100 to @emily
- Watch HRS resolution
- See instant settlement
- Check transaction history

**Minute 3: Cross-Network RTP**
- Send $50 to @bob@phonepe
- See RTP routing
- Watch 3-second settlement
- Check balance update

**Minute 4: ACH Pull**
- Add $200 via ACH
- See pending status
- View settlement timeline

**Minute 5: Admin Dashboard**
- Navigate to Admin
- Review HRS analytics
- Check fraud dashboard
- View reconciliation status

---

## Questions & Answers

**Q: Can I test error flows?**
A: Yes! Go to Settings → Demo Controls → Test Error Flows

**Q: How do I see HRS in action?**
A: Go to Send → Enter @handle → Click "Show HRS Resolution Process"

**Q: Where's the admin dashboard?**
A: Welcome screen → Admin Dashboard | Settings → Admin Dashboard

**Q: Can I see idempotency protection?**
A: Settings → Demo Controls → Test: Idempotency Replay

**Q: Is the data persistent?**
A: No, all data is in-memory and resets on page reload

**Q: Can I add more transactions?**
A: Yes! Use Send Money, Add Money, or Scan QR to create new transactions

---

## Summary

This prototype demonstrates **100% of critical flows** requested:

✅ User onboarding (signup, KYC, @handle, bank linking)
✅ ACH Pull (inflight → settled states)
✅ P2P same-network (instant payments)
✅ P2P cross-network (RTP with settlement delay)
✅ QR code merchant payments
✅ Balance view (Available vs Pending)
✅ HRS flow visualization
✅ Admin dashboard (6 tabs)
✅ Error flows (all edge cases)
✅ Idempotency protection
✅ Fraud detection
✅ Reconciliation dashboard
✅ Velocity limits
✅ Transaction investigation

**All PM concerns addressed** with working demonstrations.
**All user journeys covered** with realistic data and transitions.
**All admin functionality** with comprehensive monitoring tools.

**Ready for stakeholder review and user testing.**
