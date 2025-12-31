# Integrated Flow Architecture - Titan Wallet

## Holistic System Overview

This document reconciles the original architecture design with the detailed payment flows, showing how all components integrate.

## Architecture Stack

```
┌─────────────────────────────────────────────────────────────┐
│                     User Interface Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Titan Wallet │  │  Merchant App │  │   POS/NFC    │      │
│  │   (Native)    │  │   (Native)    │  │   QR Codes   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Handle Resolution Service (HRS) - Go                │   │
│  │  • @handle → wallet_id mapping                       │   │
│  │  • Fraud detection & velocity checks                 │   │
│  │  • Cross-network routing                            │   │
│  │  • Transaction limits & KYC enforcement              │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Titan Payment Router & Orchestration - Go           │   │
│  │  • Same-network vs cross-network routing            │   │
│  │  • Payment method selection (RTP/NFC/QR)            │   │
│  │  • Multi-currency exchange                           │   │
│  │  • Transaction state management                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                    Ledger & Banking Layer                    │
│  ┌─────────────────┐              ┌─────────────────┐       │
│  │  Blnk Ledger    │              │  Bambu Banking  │       │
│  │  • Double-entry │◄────────────►│  Middleware     │       │
│  │  • Balance mgmt │              │  • Account mgmt │       │
│  │  • Multi-currency│             │  • Compliance   │       │
│  │  • Reconciliation│             │  • Card issuing│       │
│  └─────────────────┘              └─────────────────┘       │
└─────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌─────────────────────────────────────────────────────────────┐
│                  Core Banking & Network Layer                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Galileo    │  │   Trice.co   │  │ External RTP │      │
│  │ Core Banking │  │  RTP Network │  │   Networks   │      │
│  │ • Virtual A/C│  │  • FedNow    │  │ • TCH RTP    │      │
│  │ • Settlement │  │  • Settlement│  │ • Others     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Component Integration Strategy

### 1. Ledger Architecture (Blnk + Bambu)

**Decision**: Use both systems with clear separation of concerns

```
┌─────────────────────────────────────────────────────────┐
│                    Account Structure                     │
└─────────────────────────────────────────────────────────┘

Bambu/Galileo Layer (Banking Compliance):
├── FBO Master Account (Physical bank account)
│   ├── Virtual Account #1 → User A (KYC, compliance, cards)
│   ├── Virtual Account #2 → User B
│   └── Virtual Account #N → User N

Blnk Layer (Ledger & Transaction Engine):
├── Titan Wallet Ledger
│   ├── Balance ID: bal_001 → User A (maps to VA #1)
│   │   ├── balance: $1,000.00 USD
│   │   ├── credit_balance: $5,000.00
│   │   ├── debit_balance: $4,000.00
│   │   └── inflight_balance: $50.00
│   ├── Balance ID: bal_002 → User B (maps to VA #2)
│   └── Balance ID: bal_N → User N

Mapping Table (In HRS Database):
├── wallet_id: wal_001 → balance_id: bal_001 → virtual_account: VA#1
├── wallet_id: wal_002 → balance_id: bal_002 → virtual_account: VA#2
```

**Why Both Systems?**

- **Bambu/Galileo**:
  - Banking compliance (KYC, AML, OFAC)
  - Card issuance
  - Regulatory reporting
  - Physical money settlement

- **Blnk**:
  - High-performance transaction ledger
  - Multi-currency/crypto support
  - Real-time balance management
  - Inflight transaction states
  - Reconciliation engine

### 2. RTP Network Integration (Trice.co + Direct RTP)

**Architecture**: Trice.co as primary RTP provider + direct network fallback

```go
// RTP Provider Abstraction
type RTPProvider interface {
    SendRTP(ctx context.Context, req RTPRequest) (*RTPResponse, error)
    ReceiveRTPWebhook(webhook RTPWebhook) error
}

// Primary provider: Trice.co
type TriceProvider struct {
    client *trice.Client
}

// Fallback provider: Direct RTP network
type DirectRTPProvider struct {
    networkClient *rtp.Client
}

// Router decides which provider to use
type RTPRouter struct {
    primaryProvider  RTPProvider  // Trice.co
    fallbackProvider RTPProvider  // Direct

    // Route based on:
    // - Destination network
    // - Amount (Trice may have limits)
    // - Provider health
}
```

### 3. Virtual Account Number Mapping

```
Flow: External RTP → Galileo VA → Blnk Balance

Step 1: External sender sends RTP to:
  Routing #: 123456789 (Galileo routing number)
  Account #: VA_00123 (Virtual account for User B)

Step 2: Galileo receives funds, triggers webhook to Bambu

Step 3: Bambu webhook → Titan Payment Router
  {
    "virtual_account": "VA_00123",
    "amount": 100.00,
    "currency": "USD",
    "sender_info": {...}
  }

Step 4: Payment Router queries mapping:
  VA_00123 → balance_id: bal_002 → wallet_id: wal_002

Step 5: Create Blnk transaction:
  {
    "source": "external_rtp_clearing",
    "destination": "bal_002",
    "amount": 100.00,
    "status": "inflight",
    "reference": "rtp_incoming_xyz"
  }

Step 6: Verify funds settled in Galileo → Commit Blnk transaction

Step 7: Update balance, send push notification to user
```

---

## Updated Payment Flows

### Flow 1: P2P Same Network (Handle-based)

**Scenario**: Jane (@jane) sends $100 to Emily (@emily), both on Titan Wallet

```
┌──────────┐                                              ┌──────────┐
│   Jane   │                                              │  Emily   │
│  Wallet  │                                              │  Wallet  │
└────┬─────┘                                              └────┬─────┘
     │                                                          │
     │ 1. Enter "@emily" and $100                              │
     │                                                          │
     ├─────► 2. HRS: Resolve @emily                            │
     │       ┌──────────────────────────────┐                  │
     │       │ SELECT wallet_id, balance_id │                  │
     │       │ FROM handles                 │                  │
     │       │ WHERE handle = 'emily'       │                  │
     │       │ AND network = 'titan-wallet' │                  │
     │       └──────────────────────────────┘                  │
     │       Returns: wallet_id=wal_002, balance_id=bal_002    │
     │                                                          │
     ├─────► 3. Fraud Check (HRS)                              │
     │       • Check Jane's velocity (10 txns/hour)            │
     │       • Check amount vs Jane's average                  │
     │       • IP geolocation check                            │
     │       • Device fingerprint                              │
     │       Result: APPROVE                                   │
     │                                                          │
     ├─────► 4. Check Jane's Balance (Blnk)                    │
     │       GET /balances/bal_001                             │
     │       Balance: $1,000 → Sufficient ✓                    │
     │                                                          │
     ├─────► 5. Create Inflight Transaction (Blnk)             │
     │       POST /transactions                                │
     │       {                                                 │
     │         "source": "bal_001",                            │
     │         "destination": "bal_002",                       │
     │         "amount": 100.00,                               │
     │         "currency": "USD",                              │
     │         "precision": 100,                               │
     │         "inflight": true,                               │
     │         "reference": "p2p_jane_emily_xyz"               │
     │       }                                                 │
     │       Status: INFLIGHT                                  │
     │       Jane's balance: $1,000 → $900 (available)         │
     │       Jane's inflight_debit_balance: $0 → $100          │
     │       Emily's inflight_credit_balance: $0 → $100        │
     │                                                          │
     ├─────► 6. Jane Confirms Transaction (PIN/Biometric)      │
     │                                                          │
     ├─────► 7. Commit Transaction (Blnk)                      │
     │       POST /transactions/{txn_id}/commit                │
     │       • Jane bal_001: $900 (final)                      │
     │       • Emily bal_002: $500 → $600                      │
     │       • Inflight balances cleared                       │
     │       Status: COMMITTED                                 │
     │                                                          │
     ├────────────────────────────────────────────────────────►│
     │                                              8. Push Notification
     │                          "You received $100 from @jane" │
     │                                                          │
```

**Performance**: <100ms end-to-end (same network, no RTP)

---

### Flow 2: P2P Cross-Network (Handle-based)

**Scenario**: Jane (@jane on Titan) sends $100 to Emily (@emily on PhonePe)

```
┌──────────┐                                              ┌──────────┐
│   Jane   │                                              │  Emily   │
│  (Titan) │                                              │(PhonePe) │
└────┬─────┘                                              └────┬─────┘
     │                                                          │
     │ 1. Enter "@emily" and $100                              │
     │                                                          │
     ├─────► 2. HRS: Resolve @emily                            │
     │       Query returns:                                    │
     │       • network: "phonepe" (DIFFERENT!)                 │
     │       • No wallet_id (external user)                    │
     │       • external_routing_info: {...}                    │
     │                                                          │
     ├─────► 3. Router Decision: CROSS-NETWORK                 │
     │       Method: RTP via Trice.co                          │
     │                                                          │
     ├─────► 4. Fraud Check + Balance Check                    │
     │       (Same as Flow 1)                                  │
     │                                                          │
     ├─────► 5. Create Inflight Blnk Transaction               │
     │       {                                                 │
     │         "source": "bal_001",                            │
     │         "destination": "external_rtp_clearing",         │
     │         "amount": 100.00,                               │
     │         "inflight": true,                               │
     │         "meta_data": {                                  │
     │           "external_network": "phonepe",                │
     │           "external_handle": "@emily"                   │
     │         }                                               │
     │       }                                                 │
     │                                                          │
     ├─────► 6. Jane Confirms                                  │
     │                                                          │
     ├─────► 7. Send RTP via Trice.co                          │
     │       POST https://api.trice.co/v1/payments/rtp         │
     │       {                                                 │
     │         "amount": 100.00,                               │
     │         "destination_account": "emily_phonepe_va",      │
     │         "destination_routing": "123456789"              │
     │       }                                                 │
     │       Trice Response: payment_id, status=PENDING        │
     │                                                          │
     ├───┐                                                      │
     │   │ 8. Wait for RTP Settlement (async)                  │
     │   │    Trice.co → Federal Reserve → PhonePe             │
     │   │    (2-10 seconds typically)                         │
     │   │                                                      │
     ├◄──┘ 9. Trice Webhook: RTP SETTLED                       │
     │       POST /webhooks/trice                              │
     │       {                                                 │
     │         "payment_id": "...",                            │
     │         "status": "settled",                            │
     │         "settled_at": "2025-01-15T10:23:45Z"            │
     │       }                                                 │
     │                                                          │
     ├─────► 10. Commit Blnk Transaction                       │
     │        POST /transactions/{txn_id}/commit               │
     │        Jane's $100 moved to external_rtp_clearing       │
     │                                                          │
     ├────────────────────────────────────────────────────────►│
     │                                      11. Emily receives via PhonePe
     │                                          (PhonePe's internal ledger)
     │                                                          │
```

**Performance**: 2-10 seconds (RTP network latency)

---

### Flow 3: Incoming RTP (External → Titan User)

**Scenario**: External User A sends RTP to User B (Titan customer)

```
┌──────────────┐                                         ┌──────────┐
│  External    │                                         │  User B  │
│   Sender     │                                         │ (Titan)  │
│  (Any Bank)  │                                         └────┬─────┘
└──────┬───────┘                                              │
       │                                                       │
       │ 1. Send RTP via their bank                           │
       │    To: Routing #123456789, Acct #VA_00123            │
       │    Amount: $100                                      │
       │                                                       │
       ├────────► 2. RTP Network (FedNow/TCH)                 │
       │          Settlement in seconds                       │
       │                                                       │
       │          ┌──────────────────┐                        │
       │          │     Galileo      │                        │
       │          │  Core Banking    │                        │
       │          │                  │                        │
       │          │ VA_00123 receives│                        │
       │          │ $100 credit      │                        │
       │          └────────┬─────────┘                        │
       │                   │                                  │
       │                   │ 3. Webhook to Bambu              │
       │                   ▼                                  │
       │          ┌──────────────────┐                        │
       │          │      Bambu       │                        │
       │          │   Middleware     │                        │
       │          └────────┬─────────┘                        │
       │                   │                                  │
       │                   │ 4. Webhook to Titan Router       │
       │                   ▼                                  │
       │          ┌──────────────────────────┐               │
       │          │  Titan Payment Router    │               │
       │          │                          │               │
       │          │ • Map VA_00123 → bal_002 │               │
       │          │ • Verify amount settled  │               │
       │          └────────┬─────────────────┘               │
       │                   │                                  │
       │                   │ 5. Create Blnk Transaction       │
       │                   ▼                                  │
       │          ┌──────────────────┐                        │
       │          │   Blnk Ledger    │                        │
       │          │                  │                        │
       │          │ POST /transactions│                       │
       │          │ {                │                        │
       │          │   "source": "external_rtp_clearing",      │
       │          │   "destination": "bal_002",               │
       │          │   "amount": 100.00,                       │
       │          │   "status": "committed",  ← Direct commit │
       │          │   "meta_data": {                          │
       │          │     "external_sender": "...",             │
       │          │     "galileo_txn_id": "..."               │
       │          │   }                                       │
       │          │ }                │                        │
       │          │                  │                        │
       │          │ User B balance:  │                        │
       │          │ $500 → $600      │                        │
       │          └──────────────────┘                        │
       │                   │                                  │
       ├───────────────────┼──────────────────────────────────►
       │                                   6. Push Notification
       │                     "You received $100 via RTP"      │
       │                     From: External Sender Name       │
       │                                                       │
```

**Key Points**:
- Funds already settled at Galileo before Blnk transaction
- Blnk transaction is COMMITTED immediately (not inflight)
- No risk of insufficient funds since money already received
- Account status verification step before committing

---

### Flow 4: Outgoing RTP Push (Titan User → External)

**Scenario**: User B (Titan) sends $100 to External User A

```
┌──────────┐                                         ┌──────────────┐
│  User B  │                                         │  External    │
│ (Titan)  │                                         │   Receiver   │
└────┬─────┘                                         │  (Any Bank)  │
     │                                                └──────────────┘
     │ 1. Initiate RTP to external account                  │
     │    User enters: Routing + Account number             │
     │    (No handle available for external)                │
     │                                                       │
     ├─────► 2. Validate External Account                   │
     │       • Check routing number validity                │
     │       • Optionally verify account (Plaid/MX)         │
     │                                                       │
     ├─────► 3. Fraud + Balance Check                       │
     │       (Standard checks)                              │
     │                                                       │
     ├─────► 4. Create INFLIGHT Blnk Transaction            │
     │       {                                              │
     │         "source": "bal_002",                         │
     │         "destination": "external_rtp_pending",       │
     │         "amount": 100.00,                            │
     │         "inflight": true                             │
     │       }                                              │
     │       User B balance: $600 → $500 (available)        │
     │       Inflight debit: $100                           │
     │                                                       │
     ├─────► 5. User Confirms (PIN/Biometric)               │
     │                                                       │
     ├─────► 6. Create RTP via Trice.co                     │
     │       POST /v1/payments/rtp                          │
     │       {                                              │
     │         "source_account": "VA_00123",                │
     │         "destination_routing": "987654321",          │
     │         "destination_account": "EXT_ACCT",           │
     │         "amount": 100.00                             │
     │       }                                              │
     │                                                       │
     ├───┐   7. Trice processes RTP                         │
     │   │      • Debits Galileo VA_00123                   │
     │   │      • Sends to RTP network                      │
     │   │                                                   │
     │   │   8. RTP Settlement (2-10 seconds)               │
     │   │      Galileo → FedNow → External Bank            │
     │   │                                                   │
     ├◄──┘   9. Trice Webhook: SETTLED                      │
     │       {                                              │
     │         "status": "settled",                         │
     │         "debit_amount": 100.00,                      │
     │         "settlement_time": "..."                     │
     │       }                                              │
     │                                                       │
     ├─────► 10. Commit Blnk Transaction                    │
     │        • Move from inflight to committed             │
     │        • User B final balance: $500                  │
     │                                                       │
     ├──────────────────────────────────────────────────────►
     │                               11. External bank credits receiver
     │                                   (Their bank's ledger)
     │                                                       │
```

**Error Handling**:
```go
// If RTP fails (insufficient funds at Galileo, network error, etc.)
if webhookStatus == "failed" {
    // Void the Blnk transaction
    POST /transactions/{txn_id}/void

    // Returns funds to User B
    // Balance: $500 → $600
    // Inflight cleared

    // Notify user
    "RTP payment failed. Funds returned to your wallet."
}
```

---

### Flow 5: Request for Payment (RIP) - Incoming

**Scenario**: User A (external) requests $100 from User B (Titan)

```
┌──────────────┐                                         ┌──────────┐
│  External    │                                         │  User B  │
│   User A     │                                         │ (Titan)  │
│ (Requester)  │                                         └────┬─────┘
└──────┬───────┘                                              │
       │                                                       │
       │ 1. Create RIP request via their bank                 │
       │    Request from: Routing #123456789, Acct VA_00123   │
       │    Amount: $100                                      │
       │                                                       │
       ├────────► 2. RIP sent via RTP network                 │
       │                                                       │
       │          ┌──────────────────┐                        │
       │          │     Galileo      │                        │
       │          │  Receives RIP    │                        │
       │          └────────┬─────────┘                        │
       │                   │                                  │
       │                   │ 3. Webhook to Bambu/Titan        │
       │                   ▼                                  │
       │          ┌──────────────────────────┐               │
       │          │  Titan Payment Router    │               │
       │          │                          │               │
       │          │ • Map VA_00123 → User B  │               │
       │          │ • Create RIP record      │               │
       │          │ • Status: PENDING        │               │
       │          └────────┬─────────────────┘               │
       │                   │                                  │
       ├───────────────────┼──────────────────────────────────►
       │                                   4. Push Notification
       │                     "Payment Request: $100"          │
       │                     From: [External User A Info]     │
       │                     [Approve] [Decline]              │
       │                                                       │
       │◄──────────────────────────────────────────────────────┤
       │                                   5. User B reviews request
       │                                      Checks balance: $600 ✓
       │                                                       │
       │                   ┌───── If User B APPROVES ─────┐   │
       │                   │                              │   │
       │                   │ 6. Create Blnk Transaction   │   │
       │                   │    (INFLIGHT initially)      │   │
       │                   │                              │   │
       │                   │ 7. Send RTP payment          │   │
       │                   │    (via Trice.co)            │   │
       │◄──────────────────┤    Same as Outgoing RTP flow │   │
       │  8. RTP settled   │                              │   │
       │                   └──────────────────────────────┘   │
       │                                                       │
       │                   ┌───── If User B DECLINES ─────┐   │
       │                   │                              │   │
       │                   │ 9. Send RIP decline response │   │
       │◄──────────────────┤    via Galileo/Trice         │   │
       │ 10. Decline sent  │                              │   │
       │                   │ No Blnk transaction created  │   │
       │                   └──────────────────────────────┘   │
       │                                                       │
```

**RIP Database Schema**:
```sql
CREATE TABLE payment_requests (
    request_id UUID PRIMARY KEY,
    type VARCHAR(50) DEFAULT 'incoming_rip',

    -- Source (requester)
    external_routing VARCHAR(100),
    external_account VARCHAR(100),
    requester_name VARCHAR(255),

    -- Destination (our user)
    wallet_id VARCHAR(100),
    balance_id VARCHAR(100),

    -- Request details
    amount DECIMAL(20, 8),
    currency VARCHAR(10) DEFAULT 'USD',
    description TEXT,

    -- Status tracking
    status VARCHAR(50), -- 'pending', 'approved', 'declined', 'expired'
    expires_at TIMESTAMP,

    -- Resolution
    transaction_id VARCHAR(100), -- Blnk txn ID if approved
    resolved_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW()
);
```

---

### Flow 6: NFC Payment (Service Technician)

**Scenario**: Jane pays Service Technician $150 via NFC tap

```
┌──────────┐                                         ┌──────────────┐
│   Jane   │                                         │   Service    │
│  Wallet  │                                         │  Technician  │
│          │                                         │  (Merchant)  │
└────┬─────┘                                         └──────┬───────┘
     │                                                       │
     │                                   1. Technician opens POS app
     │                                      Enters amount: $150      │
     │                                      Shows NFC ready          │
     │                                                       │
     │ 2. Jane opens Titan Wallet                           │
     │    Taps "Pay with NFC"                                │
     │                                                       │
     │◄─────────────────────────────────────────────────────┤
     │                 3. NFC handshake                      │
     │                    Exchange: Merchant ID, Amount      │
     │                                                       │
     │ 4. Handle Mapper Service resolves merchant           │
     │    merchant_nfc_id → merchant_wallet_id               │
     │                                                       │
     ├─────► 5. Display confirmation to Jane                │
     │       "Pay $150 to ServiceCo Technician #4521?"      │
     │       [Confirm with Face ID]                         │
     │                                                       │
     │ 6. Jane confirms with biometric                      │
     │                                                       │
     ├─────► 7. Check balance (Blnk)                        │
     │       Jane balance: $1,000 ✓                         │
     │                                                       │
     ├─────► 8. Fraud check                                 │
     │       • Amount vs average                            │
     │       • Merchant legitimacy check                    │
     │       • Jane's velocity                              │
     │       Result: APPROVE                                │
     │                                                       │
     ├─────► 9. Create INFLIGHT transaction                 │
     │       {                                              │
     │         "source": "bal_001",  // Jane                │
     │         "destination": "bal_merchant_4521",          │
     │         "amount": 150.00,                            │
     │         "inflight": true,                            │
     │         "payment_method": "nfc"                      │
     │       }                                              │
     │                                                       │
     ├─────► 10. Immediately commit (NFC is instant)        │
     │        POST /transactions/{txn_id}/commit            │
     │                                                       │
     ├──────────────────────────────────────────────────────►
     │                               11. Success response via NFC
     │                                   Merchant POS shows: ✓ PAID
     │                                                       │
     │◄──────────────────────────────────────────────────────┤
     │                               12. Receipt displayed    │
     │                                   on Jane's phone     │
     │                                                       │
```

**NFC Technical Details**:
```typescript
// NFC Data Exchange Format (NDEF)
interface NFCPaymentRequest {
    merchant_id: string;      // "merch_nfc_4521"
    amount: number;           // 150.00
    currency: string;         // "USD"
    merchant_name: string;    // "ServiceCo Technician"
    transaction_ref: string;  // Unique ref for idempotency
}

// Titan Wallet NFC Handler (Swift/Kotlin)
class NFCPaymentHandler {
    func handleNFCTag(tag: NFCTag) {
        // Read NDEF message from merchant POS
        let paymentRequest = parseNDEF(tag);

        // Show confirmation UI
        showConfirmation(paymentRequest);

        // On user confirmation with biometric
        processPayment(paymentRequest);

        // Write success response back to tag
        writeNDEFResponse(tag, status: "success", txnId: "...");
    }
}
```

---

### Flow 7: QR Code Payment (Merchant)

**Scenario**: Consumer pays Merchant $50 via QR code scan

```
┌──────────┐                                         ┌──────────────┐
│ Consumer │                                         │   Merchant   │
│          │                                         │   (Store)    │
└────┬─────┘                                         └──────┬───────┘
     │                                                       │
     │                                   1. Merchant generates QR
     │                                      Amount: $50 (or dynamic)
     │                                      QR Code displayed        │
     │                                                       │
     │ 2. Consumer opens Titan Wallet                       │
     │    Taps "Scan QR to Pay"                             │
     │    Camera activates                                  │
     │                                                       │
     │ 3. Scan QR code ──────────────────────────────────►  │
     │                                                       │
     │ 4. QR decoded:                                       │
     │    {                                                 │
     │      "merchant_handle": "@coffee_shop_downtown",     │
     │      "amount": 50.00,                                │
     │      "invoice_id": "inv_12345"                       │
     │    }                                                 │
     │                                                       │
     ├─────► 5. Resolve merchant handle (HRS)              │
     │       @coffee_shop_downtown → merchant_balance_id    │
     │                                                       │
     ├─────► 6. Display confirmation                        │
     │       "Pay $50.00 to Coffee Shop Downtown?"         │
     │       [Confirm]                                      │
     │                                                       │
     │ 7. Consumer confirms                                 │
     │                                                       │
     ├─────► 8. Standard P2P flow (same network)           │
     │       • Balance check                                │
     │       • Create inflight transaction                  │
     │       • Commit                                       │
     │                                                       │
     ├──────────────────────────────────────────────────────►
     │                               9. Payment confirmation
     │                                  Merchant POS updated
     │                                  Invoice marked paid  │
     │                                                       │
     │◄──────────────────────────────────────────────────────┤
     │                               10. Receipt in wallet   │
     │                                   Push notification   │
     │                                                       │
```

**QR Code Format**:
```
Option 1: Simple URL with params
titan://pay?handle=@coffee_shop&amount=50.00&ref=inv_12345

Option 2: Encoded JSON (more secure)
titan://pay?data=eyJtZXJjaGFudF9oYW5kbGUiOiJAY29mZmVlX3Nob3AiLCJhbW91bnQiOjUwLjB9

Option 3: UPI-style (India standard)
upi://pay?pa=coffeeshop@titan&pn=Coffee%20Shop&am=50.00&cu=USD&tn=Invoice12345
```

**Dynamic QR Implementation**:
```go
// Merchant generates unique QR for each transaction
func GeneratePaymentQR(merchantID string, amount float64, invoiceID string) (string, error) {
    // Create payment session
    session := PaymentSession{
        SessionID:    uuid.New().String(),
        MerchantID:   merchantID,
        Amount:       amount,
        InvoiceID:    invoiceID,
        ExpiresAt:    time.Now().Add(5 * time.Minute),
        Status:       "pending",
    }

    // Store in Redis with TTL
    redis.Set("qr_session:" + session.SessionID, session, 5*time.Minute)

    // Generate QR code
    qrData := fmt.Sprintf("titan://pay?session=%s", session.SessionID)
    qrCode := qrcode.Generate(qrData)

    return qrCode, nil
}

// When consumer scans
func ProcessQRScan(sessionID string) (*PaymentSession, error) {
    session, err := redis.Get("qr_session:" + sessionID)
    if err != nil {
        return nil, errors.New("QR code expired or invalid")
    }

    // Verify not already paid
    if session.Status != "pending" {
        return nil, errors.New("Payment already processed")
    }

    return session, nil
}
```

---

## Reconciliation Flows

### Daily Reconciliation (Blnk ↔ Galileo)

```
┌────────────────────────────────────────────────────────────┐
│              Nightly Reconciliation Process                 │
│                    (Runs at 2:00 AM UTC)                    │
└────────────────────────────────────────────────────────────┘

Step 1: Export Blnk Transactions (Previous Day)
┌──────────────────────────────────────────────┐
│ SELECT * FROM transactions                    │
│ WHERE created_at >= '2025-01-14 00:00:00'    │
│ AND created_at < '2025-01-15 00:00:00'       │
│ AND status = 'committed'                      │
│ GROUP BY balance_id                           │
└──────────────────────────────────────────────┘
                    ↓
Result:
- bal_001: +$500 credit, -$200 debit = Net: +$300
- bal_002: +$100 credit, -$50 debit = Net: +$50
- bal_003: +$0 credit, -$150 debit = Net: -$150

Step 2: Query Galileo API (VA Balances)
┌──────────────────────────────────────────────┐
│ GET /api/v1/accounts/virtual-accounts        │
│                                               │
│ For each VA:                                  │
│ - VA_00001 (maps to bal_001): Balance $1,300 │
│ - VA_00002 (maps to bal_002): Balance $650   │
│ - VA_00003 (maps to bal_003): Balance $850   │
└──────────────────────────────────────────────┘

Step 3: Compare Balances
┌──────────────────────────────────────────────┐
│ Blnk Balance    vs    Galileo Balance        │
│ bal_001: $1,300   ✓   VA_00001: $1,300       │
│ bal_002: $650     ✓   VA_00002: $650         │
│ bal_003: $850     ✓   VA_00003: $850         │
└──────────────────────────────────────────────┘
Status: ALL MATCHED ✓

Step 4: If Mismatch Detected
┌──────────────────────────────────────────────┐
│ Blnk bal_004: $1,000                         │
│ Galileo VA_00004: $995                        │
│ DISCREPANCY: $5 difference                   │
│                                               │
│ Actions:                                      │
│ 1. Create reconciliation ticket              │
│ 2. Alert finance team                        │
│ 3. Query transaction logs for bal_004        │
│ 4. Identify missing/duplicate transaction    │
│ 5. Create adjustment entry                   │
└──────────────────────────────────────────────┘

Step 5: Create Reconciliation Report
┌──────────────────────────────────────────────┐
│ Daily Reconciliation Report                   │
│ Date: 2025-01-14                             │
│ ─────────────────────────────────────────────│
│ Total Accounts: 1,523                        │
│ Matched: 1,521 (99.87%)                      │
│ Mismatched: 2 (0.13%)                        │
│ Total Discrepancy: $12.50                    │
│                                               │
│ Mismatched Accounts:                         │
│ - bal_004: -$5.00 (Under in Galileo)        │
│ - bal_127: +$7.50 (Over in Galileo)         │
│ ─────────────────────────────────────────────│
│ Status: REVIEW REQUIRED                      │
└──────────────────────────────────────────────┘
```

**Blnk Built-in Reconciliation**:
```go
// Use Blnk's native reconciliation feature
type ReconciliationSource struct {
    Name string
    FetchBalances func() ([]ExternalBalance, error)
}

galileoSource := ReconciliationSource{
    Name: "Galileo Core Banking",
    FetchBalances: func() ([]ExternalBalance, error) {
        // Query Galileo API
        return galileoClient.GetVirtualAccountBalances()
    },
}

// Run reconciliation
result := blnk.Reconcile(galileoSource, ReconcileOptions{
    MatchStrategy: "balance_id_to_virtual_account",
    Threshold: 0.01, // $0.01 tolerance for rounding
})

if result.HasMismatches() {
    // Create tickets, send alerts
    alertFinanceTeam(result.Mismatches)
}
```

---

## System Integration Summary

### Database Mapping Strategy

```sql
-- Central Mapping Table (in HRS Database)
CREATE TABLE wallet_mappings (
    wallet_id VARCHAR(100) PRIMARY KEY,

    -- Blnk references
    blnk_balance_id VARCHAR(100) UNIQUE NOT NULL,
    blnk_identity_id VARCHAR(100),
    blnk_ledger_id VARCHAR(100),

    -- Bambu/Galileo references
    bambu_customer_id VARCHAR(100),
    galileo_virtual_account VARCHAR(100) UNIQUE NOT NULL,
    galileo_card_id VARCHAR(100),

    -- Handle references
    primary_handle VARCHAR(255) UNIQUE,
    network_id VARCHAR(100) DEFAULT 'titan-wallet',

    -- Status
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Example data:
-- wallet_id: wal_001
-- blnk_balance_id: bal_001
-- galileo_virtual_account: VA_00001
-- primary_handle: @jane
```

### Transaction State Machine

```
┌─────────────────────────────────────────────────────────┐
│           Blnk Transaction State Machine                 │
└─────────────────────────────────────────────────────────┘

                    ┌──────────┐
                    │  CREATE  │
                    └─────┬────┘
                          │
                    inflight=true?
                    ┌─────┴─────┐
                   Yes          No
                    │            │
            ┌───────▼──────┐    │
            │   INFLIGHT   │    │
            │              │    │
            │ • Balance    │    │
            │   reserved   │    │
            │ • Not final  │    │
            └───────┬──────┘    │
                    │            │
        User confirms/settles?   │
            ┌───────┴──────┐    │
           Yes           No│     │
            │              │     │
    ┌───────▼──────┐  ┌────▼────▼────┐
    │  COMMITTED   │  │     VOID      │
    │              │  │               │
    │ • Final      │  │ • Cancelled   │
    │ • Balances   │  │ • Balances    │
    │   updated    │  │   restored    │
    └──────────────┘  └───────────────┘
```

### API Gateway Configuration

```yaml
# Kong API Gateway Configuration
services:
  - name: handle-resolution-service
    url: http://hrs:8080
    routes:
      - name: resolve-handle
        paths:
          - /api/v1/handles/resolve
        methods: [POST]
        plugins:
          - name: rate-limiting
            config:
              minute: 100
              hour: 1000
              policy: redis
          - name: jwt
            config:
              claims_to_verify: [exp]
          - name: response-transformer
            config:
              add:
                headers:
                  - "X-Service: HRS"

  - name: blnk-ledger
    url: http://blnk:5001
    routes:
      - name: transactions
        paths:
          - /api/v1/transactions
        plugins:
          - name: rate-limiting
            config:
              minute: 500
              hour: 10000
          - name: jwt

  - name: payment-router
    url: http://router:8081
    routes:
      - name: initiate-payment
        paths:
          - /api/v1/payments
        plugins:
          - name: rate-limiting
            config:
              minute: 200
          - name: jwt
          - name: request-size-limiting
            config:
              allowed_payload_size: 128
```

---

## Performance Targets Revisited

```
┌─────────────────────────────────────────────────────────┐
│              End-to-End Performance SLOs                 │
└─────────────────────────────────────────────────────────┘

Operation                          p50      p95      p99
────────────────────────────────────────────────────────
Handle Resolution (HRS)           <2ms     <10ms    <20ms
Same-Network P2P (commit)         <50ms    <100ms   <200ms
Balance Check (Blnk)              <5ms     <15ms    <30ms
Fraud Check (HRS)                 <10ms    <30ms    <50ms
Transaction Commit (Blnk)         <20ms    <50ms    <100ms
QR/NFC Payment (total)            <100ms   <200ms   <300ms

Cross-Network RTP                 2-5sec   8sec     15sec
Incoming RTP Processing           <500ms   <1sec    <2sec
Reconciliation (per account)      <100ms   <200ms   <500ms

Database Query (indexed)          <3ms     <10ms    <20ms
Redis Cache Hit                   <1ms     <2ms     <5ms
Local Cache Hit                   <50μs    <100μs   <500μs
```

---

## Security Architecture

### Encryption Strategy

```
┌─────────────────────────────────────────────────────────┐
│                Data Encryption Strategy                  │
└─────────────────────────────────────────────────────────┘

Layer 1: Application-Level Encryption
┌──────────────────────────────────────────────────────┐
│ Field                  │ Encryption                   │
├────────────────────────┼──────────────────────────────┤
│ wallet_id              │ None (used as identifier)    │
│ PII (name, email, SSN) │ AES-256-GCM                  │
│ Bank account numbers   │ AES-256-GCM                  │
│ Routing numbers        │ AES-256-GCM                  │
│ Handle mappings        │ AES-256-GCM                  │
│ Transaction metadata   │ None (already anonymized)    │
└────────────────────────┴──────────────────────────────┘

Layer 2: Database Encryption (PostgreSQL pgcrypto)
┌──────────────────────────────────────────────────────┐
│ CREATE EXTENSION pgcrypto;                           │
│                                                       │
│ INSERT INTO handles (                                │
│   handle,                                            │
│   wallet_id_encrypted                                │
│ ) VALUES (                                           │
│   '@jane',                                           │
│   pgp_sym_encrypt('wal_001', 'encryption_key')      │
│ );                                                   │
└──────────────────────────────────────────────────────┘

Layer 3: Disk Encryption (PostgreSQL/Redis)
- PostgreSQL: LUKS full-disk encryption
- Redis: RDB/AOF file encryption
- Backups: Encrypted before upload to S3

Layer 4: Network Encryption
- TLS 1.3 for all service-to-service communication
- Certificate pinning for mobile apps
- mTLS for internal microservices
```

### Authentication Flow

```
┌─────────────────────────────────────────────────────────┐
│              JWT Authentication Flow                     │
└─────────────────────────────────────────────────────────┘

1. User Login
┌──────────┐                              ┌──────────────┐
│  Mobile  │──── POST /auth/login ───────►│ Auth Service │
│   App    │     {username, password}     │              │
└────┬─────┘                              └──────┬───────┘
     │                                            │
     │                                     Verify credentials
     │                                     Generate tokens
     │                                            │
     │◄───────── Tokens ────────────────────────┘
     │    {
     │      access_token: "eyJhbG...",  (15 min TTL)
     │      refresh_token: "dGhpc1...", (30 day TTL)
     │    }
     │
     │ 2. Store tokens securely
     │    iOS: Keychain
     │    Android: EncryptedSharedPreferences
     │
     │ 3. Subsequent API calls
     │──── POST /api/v1/payments ─────────────────►
     │     Headers:
     │       Authorization: Bearer eyJhbG...
     │
     │ 4. Token validation (Kong JWT plugin)
     │    ✓ Signature valid
     │    ✓ Not expired
     │    ✓ Claims match
     │
     │◄───────── API Response ─────────────────────┘

5. Token Refresh (when access_token expires)
┌──────────┐                              ┌──────────────┐
│  Mobile  │── POST /auth/refresh ───────►│ Auth Service │
│   App    │    {refresh_token}           │              │
└────┬─────┘                              └──────┬───────┘
     │                                            │
     │                                     Verify refresh token
     │                                     Generate new access
     │                                            │
     │◄───────── New Access Token ───────────────┘
     │    {access_token: "eyJhbG..."}
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster Architecture                 │
└─────────────────────────────────────────────────────────────────┘

                        ┌──────────────────┐
                        │   CloudFlare     │
                        │   DDoS Protection│
                        └────────┬─────────┘
                                 │
                        ┌────────▼─────────┐
                        │  Load Balancer   │
                        │  (AWS ALB)       │
                        └────────┬─────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                         │
            ┌───────▼────────┐      ┌────────▼────────┐
            │  Kong Gateway  │      │  Kong Gateway   │
            │   (Replica 1)  │      │   (Replica 2)   │
            └───────┬────────┘      └────────┬────────┘
                    │                         │
        ┌───────────┴───────────┬─────────────┴──────────┐
        │                       │                         │
┌───────▼────────┐   ┌──────────▼──────┐   ┌────────────▼─────┐
│ HRS Deployment │   │ Router Deploy   │   │ Blnk Deployment  │
│ (5-50 pods)    │   │ (3-20 pods)     │   │ (10-100 pods)    │
│                │   │                 │   │                  │
│ • Handle res   │   │ • Payment route │   │ • Transactions   │
│ • Fraud detect │   │ • Network route │   │ • Balances       │
│ • Cache tier 1 │   │ • RTP orchestr  │   │ • Reconciliation │
└───────┬────────┘   └──────────┬──────┘   └────────┬─────────┘
        │                       │                     │
        └───────────┬───────────┴─────────────────────┘
                    │
        ┌───────────┴──────────────────────┐
        │                                   │
┌───────▼──────────┐            ┌──────────▼─────────┐
│ Redis Cluster    │            │ PostgreSQL Cluster │
│ (3M + 3R)        │            │ (1 Primary + 2R)   │
│                  │            │                    │
│ • Cache          │            │ • Transactions     │
│ • Rate limiting  │            │ • Balances         │
│ • Sessions       │            │ • Handles          │
└──────────────────┘            └────────────────────┘

External Services:
┌────────────────┐  ┌─────────────┐  ┌──────────────┐
│  Trice.co RTP  │  │   Galileo   │  │    Bambu     │
│                │  │ Core Banking│  │  Middleware  │
└────────────────┘  └─────────────┘  └──────────────┘
```

### Horizontal Pod Autoscaling (HPA)

```yaml
# HRS Autoscaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hrs-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: handle-resolution-service
  minReplicas: 5
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  - type: Pods
    pods:
      metric:
        name: requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
```

---

## Monitoring & Observability

### Key Metrics (Prometheus)

```yaml
# Custom metrics exported by each service
metrics:
  # Handle Resolution Service
  - hrs_handle_resolution_duration_seconds (histogram)
  - hrs_fraud_check_duration_seconds (histogram)
  - hrs_cache_hit_rate (gauge)
  - hrs_total_requests (counter)
  - hrs_failed_requests (counter)

  # Payment Router
  - router_payment_duration_seconds (histogram)
  - router_same_network_count (counter)
  - router_cross_network_count (counter)
  - router_rtp_settlement_duration_seconds (histogram)

  # Blnk Ledger
  - blnk_transaction_count (counter)
  - blnk_transaction_duration_seconds (histogram)
  - blnk_balance_check_duration_seconds (histogram)
  - blnk_inflight_transaction_count (gauge)
  - blnk_reconciliation_discrepancies (counter)

  # Infrastructure
  - postgres_connection_pool_usage (gauge)
  - redis_cache_hit_rate (gauge)
  - redis_memory_usage_bytes (gauge)
```

### Distributed Tracing (Jaeger)

```go
// Example: End-to-end trace for P2P payment
func HandleP2PPayment(ctx context.Context, req PaymentRequest) error {
    ctx, span := tracer.Start(ctx, "p2p_payment")
    defer span.End()

    span.SetAttributes(
        attribute.String("source_handle", req.SourceHandle),
        attribute.String("dest_handle", req.DestHandle),
        attribute.Float64("amount", req.Amount),
    )

    // Each service call creates child spans
    walletID, err := hrs.ResolveHandle(ctx, req.DestHandle) // Child span
    if err != nil {
        span.RecordError(err)
        return err
    }

    fraudResult, err := hrs.CheckFraud(ctx, req) // Child span
    if err != nil {
        span.RecordError(err)
        return err
    }

    txn, err := blnk.CreateTransaction(ctx, ...) // Child span
    if err != nil {
        span.RecordError(err)
        return err
    }

    span.AddEvent("Payment completed successfully")
    return nil
}

// Resulting trace visualization:
// p2p_payment (500ms total)
//   ├─ hrs.ResolveHandle (5ms)
//   │   ├─ cache.Get (0.5ms)
//   │   └─ db.Query (4ms)
//   ├─ hrs.CheckFraud (15ms)
//   │   ├─ getVelocity (5ms)
//   │   └─ checkBlacklist (2ms)
//   └─ blnk.CreateTransaction (480ms)
//       ├─ balanceCheck (10ms)
//       ├─ createInflight (200ms)
//       └─ commit (270ms)
```

---

## Comparison: Initial Design vs Current Architecture

| Component | Initial Design | Current Architecture | Status |
|-----------|----------------|---------------------|---------|
| **Ledger** | Blnk only | Blnk + Bambu/Galileo | ✅ Enhanced |
| **RTP Provider** | Trice.co | Trice.co + Direct RTP | ✅ Aligned |
| **Handle Service** | HRS (Go) | HRS + Router/Lookup | ✅ Enhanced |
| **Virtual Accounts** | Not specified | Galileo VAs | ✅ New |
| **Payment Methods** | Handle-based only | Handle/NFC/QR/RTP/RIP | ✅ Expanded |
| **Cross-Network** | Designed | Detailed flows | ✅ Detailed |
| **Fraud Detection** | In HRS | In HRS (same) | ✅ Aligned |
| **Multi-Currency** | Blnk native | Blnk native | ✅ Aligned |
| **Reconciliation** | Blnk native | Blnk ↔ Galileo | ✅ Enhanced |

---

## Open Questions & Recommendations

### 1. Bambu vs Trice.co Relationship

**Question**: Are Bambu and Trice.co complementary or alternatives?

**Recommendation**:
```
Use BOTH:
- Bambu: Banking-as-a-Service (KYC, compliance, card issuing)
- Trice.co: RTP network connectivity and settlement
- Galileo: Core banking infrastructure (under Bambu)

Architecture:
Titan App → Payment Router → Blnk Ledger
                          ↓
                     Bambu (compliance layer)
                          ↓
                   Galileo (core banking)
                          ↓
                   Trice.co (RTP network) → External banks
```

### 2. Account Number Strategy

**Question**: Should users see their virtual account numbers?

**Recommendation**:
```
YES - Show in advanced settings for:
- Receiving direct bank transfers
- Linking to external apps (Venmo, etc.)
- Employer direct deposit setup

NO - Don't show during normal operation:
- Use handles for P2P
- Use NFC/QR for merchants
- Virtual account is "under the hood"
```

### 3. Cryptocurrency Implementation Timeline

**Question**: When to add crypto support?

**Recommendation**:
```
Phase 1 (MVP): Fiat only (USD, EUR, GBP)
Phase 2 (6 months): Add stablecoins (USDC, USDT)
Phase 3 (12 months): Add major crypto (BTC, ETH)

Rationale:
- Focus on RTP and fiat flows first
- Blnk already supports crypto (proven)
- Add when user demand is clear
```

### 4. Handle Reservation

**Question**: How to prevent handle squatting?

**Recommendation**:
```
Rules:
1. Free handles: Require verified phone/email
2. Premium handles (@shortname): $5/year fee
3. Business handles: KYC verification required
4. Inactive handles: Released after 12 months no activity
5. Reserved handles: Protect brand names (@visa, @paypal, etc.)
```

---

## Next Steps for Implementation

### Phase 1: Core Infrastructure (Weeks 1-4)

```
Week 1-2: Database & Services Setup
├─ Set up PostgreSQL cluster (Patroni HA)
├─ Set up Redis cluster (3M+3R)
├─ Deploy Blnk ledger
├─ Create central mapping database
└─ Set up monitoring (Prometheus/Jaeger)

Week 3-4: Handle Resolution Service
├─ Implement HRS in Go
├─ Build handle resolution API
├─ Implement three-tier caching
├─ Build fraud detection engine
└─ Add cross-network routing logic
```

### Phase 2: Banking Integration (Weeks 5-8)

```
Week 5-6: Bambu/Galileo Integration
├─ Set up Bambu sandbox account
├─ Integrate Galileo API
├─ Implement virtual account creation
├─ Build webhook handlers
└─ Test fund flows

Week 7-8: Trice.co RTP Integration
├─ Set up Trice.co account
├─ Integrate RTP API
├─ Build webhook handlers
├─ Test incoming/outgoing RTP
└─ Implement RIP (Request for Payment)
```

### Phase 3: Payment Flows (Weeks 9-12)

```
Week 9-10: P2P Payments
├─ Implement same-network flow
├─ Implement cross-network flow
├─ Add transaction confirmations
├─ Build notification system
└─ End-to-end testing

Week 11-12: Merchant Payments
├─ Implement QR code generation
├─ Implement NFC payment flow
├─ Build merchant dashboard
├─ Test with pilot merchants
└─ Load testing (target: 1000 TPS)
```

### Phase 4: Mobile Apps (Weeks 13-16)

```
Week 13-14: iOS App (Swift)
├─ Implement authentication
├─ Build wallet UI
├─ Integrate payment flows
├─ Add NFC capability
└─ TestFlight beta

Week 15-16: Android App (Kotlin)
├─ Implement authentication
├─ Build wallet UI
├─ Integrate payment flows
├─ Add NFC capability
└─ Google Play beta
```

---

## Conclusion

The integrated architecture combines:
- **Blnk**: High-performance ledger with multi-currency, crypto, reconciliation
- **Bambu/Galileo**: Banking compliance and virtual accounts
- **Trice.co**: RTP network connectivity
- **HRS**: Fast, secure handle resolution with fraud detection
- **Native Apps**: iOS/Android with NFC/QR support

**Key Differentiators**:
1. Privacy-first (@handle system hides account details)
2. Fast same-network transfers (<100ms)
3. RTP integration for cross-network (2-5 seconds)
4. Multi-payment methods (Handle/QR/NFC/RTP)
5. Built-in fraud detection
6. Future-ready for crypto

This architecture delivers on the "incredibly fast, secure" requirement while maintaining regulatory compliance and scalability to millions of users.
