# Titan Wallet - Corrected System Architecture

## Overview

This document defines the actual architecture for Titan Wallet based on confirmed technology choices.

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Ledger** | Blnk (Open Source) | Double-entry accounting, multi-currency, reconciliation |
| **RTP Network** | Trice.co | Virtual accounts, routing numbers, RTP connectivity (FedNow/TCH) |
| **Banking Provider** | [TBD - To Be Selected] | FBO account, settlement, KYC/compliance, card issuing |
| **Handle Service** | Custom (Go) | @handle resolution, fraud detection, routing |
| **Payment Router** | Custom (Go) | Payment orchestration, method selection |
| **Mobile Apps** | Native (Swift/Kotlin) | Consumer and merchant apps |
| **Card Issuing** | [TBD - Lithic/Marqeta] | Virtual/physical card issuance, Apple Pay/Google Pay |
| **Admin Dashboard** | Retool/Custom Next.js | Operations, compliance, analytics |
| **Push Notifications** | APNs + FCM | Transaction alerts, security notifications |

---

## Why Native Apps Are Critical

### ⚠️ DO NOT Use Hybrid/Cross-Platform for Financial Apps

The current React + TypeScript + Capacitor apps in your repository are **unsuitable for production** use in a payments wallet. Here's why:

#### Security Vulnerabilities with Hybrid Apps

| Security Risk | Native Solution | Hybrid/Capacitor Risk |
|---------------|-----------------|----------------------|
| **Secure Storage** | iOS Keychain (hardware-backed)<br>Android Keystore (hardware-backed) | LocalStorage/AsyncStorage<br>Software-based, extractable |
| **Biometric Auth** | Secure Enclave (iOS)<br>StrongBox (Android) | Plugin-based<br>No hardware isolation |
| **SSL Pinning** | Native networking with certificate pinning | Can be bypassed in JavaScript |
| **Code Protection** | Binary obfuscation<br>Runtime integrity checks | JavaScript visible<br>Easy to tamper |
| **Memory Safety** | ASLR, Stack canaries | JavaScript heap accessible |
| **Root Detection** | Native OS APIs | Plugin-based, unreliable |

#### Platform Features Lost with Hybrid

```
❌ Apple Pay NFC (requires PassKit framework)
❌ Google Pay NFC (requires Host Card Emulation)
❌ Hardware security module access
❌ Secure Enclave for biometrics
❌ Background transaction monitoring
❌ Native push notification encryption
❌ Optimal performance (60 fps)
❌ App Store financial certification
❌ Deep linking for payment requests
❌ Native widgets (home screen balance)
```

#### Recommended Native Stack

**iOS - Swift + SwiftUI**:
```swift
// Secure token storage in Keychain
import Security

class SecureStorage {
    func storeToken(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecValueData as String: token.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }
}

// Biometric authentication
import LocalAuthentication

func authenticateWithBiometrics() async -> Bool {
    let context = LAContext()
    do {
        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to confirm payment"
        )
    } catch {
        return false
    }
}

// Certificate pinning
let session = URLSession(
    configuration: .default,
    delegate: SSLPinningDelegate(),
    delegateQueue: nil
)
```

**Android - Kotlin + Jetpack Compose**:
```kotlin
// Hardware-backed keystore
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties

class SecureStorage {
    fun storeToken(token: String) {
        val keyStore = KeyStore.getInstance("AndroidKeyStore")
        keyStore.load(null)

        val keyGenerator = KeyGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_AES,
            "AndroidKeyStore"
        )
        keyGenerator.init(
            KeyGenParameterSpec.Builder(
                "token_key",
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
            .setUserAuthenticationRequired(true)
            .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
            .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
            .build()
        )
        // ... encryption logic
    }
}

// Biometric authentication
import androidx.biometric.BiometricPrompt

val biometricPrompt = BiometricPrompt(
    this,
    executor,
    object : BiometricPrompt.AuthenticationCallback() {
        override fun onAuthenticationSucceeded(
            result: BiometricPrompt.AuthenticationResult
        ) {
            // Payment confirmed
        }
    }
)
```

**Development Timeline**:
- iOS app: 8-12 weeks (with experienced Swift developer)
- Android app: 8-12 weeks (with experienced Kotlin developer)
- **Can develop in parallel** (shared API contracts)

---

## System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     User Interface Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Titan Wallet │  │  Merchant App │  │   POS/NFC    │       │
│  │  (iOS/Android│  │  (iOS/Android)│  │   QR Codes   │       │
│  │   Native)    │  │               │  │              │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└──────────────────────────────────────────────────────────────┘
                           ↓ ↑ REST/gRPC APIs
┌──────────────────────────────────────────────────────────────┐
│           Titan Backend Services (Go Microservices)           │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Handle Resolution Service (HRS)                       │  │
│  │  ─────────────────────────────────                     │  │
│  │  • @handle → wallet_id mapping (encrypted)             │  │
│  │  • Cross-network routing (@jane@titan vs @bob@phonepe)│  │
│  │  • Fraud detection engine                              │  │
│  │  • Velocity checks (10 txns/hour limit)                │  │
│  │  • Amount anomaly detection                            │  │
│  │  • KYC level enforcement                               │  │
│  │  • Three-tier caching (local → Redis → PostgreSQL)     │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Payment Router & Orchestration                        │  │
│  │  ───────────────────────────────                       │  │
│  │  • Route selection: Same-network vs Cross-network      │  │
│  │  • Payment method: Handle/QR/NFC/RTP                   │  │
│  │  • Transaction state management (inflight → commit)    │  │
│  │  • Multi-currency exchange                             │  │
│  │  • Webhook handlers (Trice.co, Banking Provider)       │  │
│  │  • Notification dispatch                               │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Reconciliation Service                                │  │
│  │  ────────────────────────                              │  │
│  │  • Daily Blnk ↔ Banking Provider reconciliation        │  │
│  │  • Blnk ↔ Trice.co RTP transaction matching            │  │
│  │  • Discrepancy detection & alerting                    │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌──────────────────────────────────────────────────────────────┐
│                      Ledger Layer                             │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Blnk Ledger (Open Source - Go)                        │  │
│  │  ────────────────────────────────                      │  │
│  │  • Double-entry accounting (debits = credits)          │  │
│  │  • Balance management:                                 │  │
│  │    - balance (current available)                       │  │
│  │    - inflight_balance (pending transactions)           │  │
│  │    - credit_balance (lifetime credits)                 │  │
│  │    - debit_balance (lifetime debits)                   │  │
│  │  • Multi-currency support (USD, EUR, GBP, etc.)        │  │
│  │  • Cryptocurrency support (BTC, ETH, USDT, USDC)       │  │
│  │  • Arbitrary precision (big.Int for crypto decimals)   │  │
│  │  • Inflight transactions (hold → commit/void)          │  │
│  │  • Built-in reconciliation engine                      │  │
│  │  • Transaction history & audit trail                   │  │
│  │  • Identity management with PII tokenization           │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
│  Database: PostgreSQL (Blnk's data store)                     │
└──────────────────────────────────────────────────────────────┘
                           ↓ ↑
┌──────────────────────────────────────────────────────────────┐
│              External Banking & Network Layer                 │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Banking Provider [TBD - Selection Needed]          │     │
│  │  ───────────────────────────────────────────────    │     │
│  │                                                      │     │
│  │  Requirements:                                       │     │
│  │  • FBO (For Benefit Of) master account              │     │
│  │  • Settlement capabilities                           │     │
│  │  • KYC/AML compliance services                       │     │
│  │  • Card issuing (debit cards)                        │     │
│  │  • API integration (webhooks)                        │     │
│  │                                                      │     │
│  │  Candidate Options:                                  │     │
│  │  - Synapse (if available)                            │     │
│  │  - Unit.co                                           │     │
│  │  - Treasury Prime                                    │     │
│  │  - Column                                            │     │
│  │  - Stripe Treasury                                   │     │
│  └─────────────────────────────────────────────────────┘     │
│                                                                │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  Trice.co (RTP Platform)                            │     │
│  │  ─────────────────────────                          │     │
│  │                                                      │     │
│  │  Provides:                                           │     │
│  │  ✅ Virtual Account Numbers (per user)              │     │
│  │  ✅ Routing Numbers (for RTP)                        │     │
│  │  ✅ FedNow connectivity                              │     │
│  │  ✅ TCH RTP network access                           │     │
│  │  ✅ Real-time settlement (2-10 seconds)              │     │
│  │  ✅ Webhooks (incoming/outgoing RTP status)          │     │
│  │  ✅ Request for Payment (RIP) support                │     │
│  │                                                      │     │
│  │  Integration:                                        │     │
│  │  - REST API (https://api.trice.co/v1)               │     │
│  │  - Webhook endpoint (POST /webhooks/trice)          │     │
│  │  - Each Titan user gets unique VA from Trice        │     │
│  └─────────────────────────────────────────────────────┘     │
│                          ↓ ↑                                  │
│  ┌─────────────────────────────────────────────────────┐     │
│  │  External RTP Networks                              │     │
│  │  ────────────────────                               │     │
│  │  • FedNow (Federal Reserve)                         │     │
│  │  • TCH RTP (The Clearing House)                     │     │
│  │  • Other banks' RTP endpoints                       │     │
│  │  • Other wallet providers (PhonePe, Venmo, etc.)    │     │
│  └─────────────────────────────────────────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

## Account Structure

```
┌──────────────────────────────────────────────────────────────┐
│                  Account Hierarchy                            │
└──────────────────────────────────────────────────────────────┘

Banking Provider Layer (Physical Money):
┌────────────────────────────────────────┐
│  Titan FBO Master Account              │
│  (Pool of all user funds)              │
│  Balance: $10,000,000                  │
└────────────────────────────────────────┘
         ↓ (Settlement layer)

Trice.co Layer (RTP Virtual Accounts):
┌────────────────────────────────────────┐
│  User A: Virtual Account #001          │
│  Routing: 123456789                    │
│  Account: TRICE_VA_001                 │
│  (Used for RTP incoming/outgoing)      │
├────────────────────────────────────────┤
│  User B: Virtual Account #002          │
│  Routing: 123456789                    │
│  Account: TRICE_VA_002                 │
└────────────────────────────────────────┘
         ↓ (Mapped 1:1)

Blnk Layer (Ledger - Virtual Balances):
┌────────────────────────────────────────┐
│  Balance ID: bal_001 → User A          │
│  ├─ balance: $1,000.00 (available)     │
│  ├─ inflight_balance: $50.00           │
│  ├─ credit_balance: $5,000.00 (total)  │
│  ├─ debit_balance: $4,000.00 (total)   │
│  └─ currency: USD                      │
├────────────────────────────────────────┤
│  Balance ID: bal_002 → User B          │
│  ├─ balance: $500.00                   │
│  ├─ inflight_balance: $0.00            │
│  ├─ credit_balance: $1,500.00          │
│  ├─ debit_balance: $1,000.00           │
│  └─ currency: USD                      │
└────────────────────────────────────────┘

HRS Mapping Table (Encrypted):
┌─────────────────────────────────────────────────────────────┐
│ wallet_id  │ handle  │ blnk_balance │ trice_va             │
├────────────┼─────────┼──────────────┼──────────────────────┤
│ wal_001    │ @jane   │ bal_001      │ TRICE_VA_001         │
│ wal_002    │ @emily  │ bal_002      │ TRICE_VA_002         │
└─────────────────────────────────────────────────────────────┘
```

### Key Principle: Virtual Balances

- **Physical Money**: Pooled in FBO account at Banking Provider
- **Virtual Balances**: Tracked individually in Blnk ledger
- **RTP Routing**: Each user has unique virtual account from Trice.co
- **Settlement**: Daily reconciliation ensures Blnk = Banking Provider

**Example**:
- FBO account holds $10M total
- User A's Blnk balance: $1,000
- User B's Blnk balance: $500
- User C's Blnk balance: $8,000
- ... (Sum of all Blnk balances = $10M)

---

## Critical Architecture Decisions (PM Review Responses)

### 1. ACH Pull / On-Ramping (Addressing "Incoming Funds Blind Spot")

**Problem Identified**: New users cannot fund their wallet without another RTP-capable account.

**Solution**: Add ACH Pull via Plaid/Teller

```
User Journey:
1. User downloads app
2. Taps "Add Money"
3. Links bank account (Plaid/Teller)
4. Initiates ACH pull ($100)
5. Funds available in 1-3 business days

Architecture Addition:
┌──────────────────────────────────────────────────────┐
│  ACH Pull Service (New Component)                    │
│                                                       │
│  ┌────────────────┐         ┌──────────────────┐    │
│  │  Plaid/Teller  │────────►│  Banking Provider│    │
│  │  Link Account  │         │  Initiate ACH    │    │
│  └────────────────┘         └────────┬─────────┘    │
│                                       │              │
│                                       ▼              │
│                             ┌──────────────────┐    │
│                             │  ACH Received    │    │
│                             │  (1-3 days)      │    │
│                             └────────┬─────────┘    │
│                                      │              │
│                                      ▼              │
│                             ┌──────────────────┐    │
│                             │  Blnk: Credit    │    │
│                             │  User Balance    │    │
│                             └──────────────────┘    │
└──────────────────────────────────────────────────────┘
```

**Implementation**:

```go
// ACH Pull Flow
type ACHPullRequest struct {
    UserID          string
    PlaidAccessToken string
    AccountID       string
    Amount          float64
    Currency        string
}

func InitiateACHPull(req ACHPullRequest) (*ACHTransfer, error) {
    // Step 1: Verify bank account via Plaid
    account, err := plaid.GetAccount(req.PlaidAccessToken, req.AccountID)
    if err != nil {
        return nil, err
    }

    // Step 2: Create ACH transfer via Banking Provider
    achTransfer, err := bankingProvider.CreateACHDebit({
        SourceAccount: account.AccountNumber,
        SourceRouting: account.RoutingNumber,
        DestAccount:   getUserFBOAccount(req.UserID),
        Amount:        req.Amount,
        Currency:      req.Currency,
        Description:   "Wallet funding"
    })

    // Step 3: Create PENDING transaction in Blnk
    blnkTxn, err := blnk.RecordTransaction({
        Source:      "ach_clearing",
        Destination: getUserBalanceID(req.UserID),
        Amount:      req.Amount,
        Status:      "inflight", // ⚠️ NOT committed yet
        Reference:   achTransfer.ID,
        MetaData: {
            "ach_transfer_id": achTransfer.ID,
            "settlement_date": achTransfer.EstimatedSettlement,
            "type": "ach_pull"
        }
    })

    // Step 4: Store transfer record
    db.Query(`
        INSERT INTO ach_transfers (id, user_id, blnk_txn_id, status, amount)
        VALUES ($1, $2, $3, 'pending', $4)
    `, achTransfer.ID, req.UserID, blnkTxn.TransactionID, req.Amount)

    return achTransfer, nil
}

// ACH Settlement Webhook Handler
func HandleACHSettlement(webhook BankingProviderWebhook) error {
    if webhook.Status == "settled" {
        // Commit the Blnk transaction
        blnk.CommitInflightTransaction(webhook.BlnkTxnID)

        // Update database
        db.Query(`
            UPDATE ach_transfers
            SET status = 'settled', settled_at = NOW()
            WHERE id = $1
        `, webhook.ACHTransferID)

        // Notify user
        sendPushNotification(webhook.UserID, {
            Title: "Funds Available",
            Body:  fmt.Sprintf("$%.2f is now available in your wallet", webhook.Amount)
        })
    } else if webhook.Status == "failed" {
        // Void the transaction
        blnk.VoidInflightTransaction(webhook.BlnkTxnID)

        // Update database
        db.Query(`
            UPDATE ach_transfers
            SET status = 'failed', failure_reason = $2
            WHERE id = $1
        `, webhook.ACHTransferID, webhook.FailureReason)

        // Notify user
        sendPushNotification(webhook.UserID, {
            Title: "Transfer Failed",
            Body:  "Your bank transfer could not be completed"
        })
    }

    return nil
}
```

**Database Schema Addition**:

```sql
CREATE TABLE ach_transfers (
    id VARCHAR(100) PRIMARY KEY,
    user_id VARCHAR(100) NOT NULL,
    blnk_txn_id VARCHAR(100) REFERENCES blnk_transactions,

    direction VARCHAR(10) NOT NULL,  -- 'pull' (funding) or 'push' (withdrawal)

    -- External details
    plaid_access_token_encrypted BYTEA,
    external_account_id VARCHAR(100),
    external_routing VARCHAR(20),
    external_account_last4 VARCHAR(4),

    -- Transfer details
    amount DECIMAL(20, 8) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',

    -- Status
    status VARCHAR(50) NOT NULL,  -- 'pending', 'settled', 'failed', 'returned'
    failure_reason TEXT,
    estimated_settlement DATE,
    settled_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),

    INDEX idx_user_status (user_id, status)
);
```

**Required Integrations**:
- **Plaid** ($0.20/link + $0.10/ACH): Bank account linking + ACH initiation
- **Alternative: Teller** (similar pricing, better UX)
- **Alternative: MX** (more expensive but enterprise-grade)

### 2. Settlement Finality & Float Risk

**Problem Identified**: Crediting users instantly on webhook without verifying settlement finality creates float risk.

**Solution**: Multi-tier settlement status

```go
// Incoming RTP Handler (CORRECTED)
func HandleIncomingRTP(webhook TriceWebhook) error {
    // Step 1: Verify settlement finality
    settlementFinal := webhook.SettlementStatus == "FINAL" &&
                       webhook.Network in []string{"FedNow", "TCH_RTP"}

    var blnkStatus string
    var availableToUser bool

    if settlementFinal {
        // FedNow/TCH RTP are FINAL and IRREVOCABLE
        blnkStatus = "committed"
        availableToUser = true
    } else {
        // Other rails (accelerated ACH, etc.) are REVERSIBLE
        blnkStatus = "inflight"
        availableToUser = false
    }

    // Step 2: Create Blnk transaction with appropriate status
    blnkTxn, err := blnk.RecordTransaction({
        Source:      "external_rtp_clearing",
        Destination: webhook.BalanceID,
        Amount:      webhook.Amount,
        Status:      blnkStatus, // ⚠️ CONDITIONAL
        Inflight:    !settlementFinal,
        Reference:   webhook.PaymentID,
        MetaData: {
            "trice_payment_id": webhook.PaymentID,
            "settlement_status": webhook.SettlementStatus,
            "network": webhook.Network,
            "reversible": !settlementFinal
        }
    })

    // Step 3: Record transaction
    db.Query(`
        INSERT INTO incoming_payments (
            trice_payment_id,
            blnk_txn_id,
            settlement_final,
            available_to_user
        )
        VALUES ($1, $2, $3, $4)
    `, webhook.PaymentID, blnkTxn.TransactionID, settlementFinal, availableToUser)

    // Step 4: Notify user with appropriate message
    if availableToUser {
        sendPushNotification(webhook.UserID, {
            Title: "Payment Received",
            Body:  fmt.Sprintf("$%.2f is now available", webhook.Amount)
        })
    } else {
        sendPushNotification(webhook.UserID, {
            Title: "Payment Pending",
            Body:  fmt.Sprintf("$%.2f pending (available in 1-2 days)", webhook.Amount)
        })
    }

    return nil
}

// Settlement finality checker
func IsSettlementFinal(network string, status string) bool {
    finalNetworks := map[string]bool{
        "FedNow":   true,  // Always final
        "TCH_RTP":  true,  // Always final
        "SWIFT":    true,  // Generally final after confirmation
        "ACH":      false, // Reversible for 60 days
        "Wire":     true,  // Final after receipt
    }

    return finalNetworks[network] && status == "SETTLED"
}
```

**Balance Display Logic**:

```typescript
// Mobile app balance display
interface UserBalance {
    available: number;      // Can spend now
    pending: number;        // Incoming but not final
    total: number;          // available + pending
}

async function getUserBalance(userId: string): Promise<UserBalance> {
    const blnkBalance = await blnk.getBalance(getUserBalanceID(userId));

    return {
        available: blnkBalance.balance / 100,           // Committed funds
        pending: blnkBalance.inflight_balance / 100,    // Non-final settlements
        total: (blnkBalance.balance + blnkBalance.inflight_balance) / 100
    };
}

// UI Display:
// Available: $500.00
// Pending:   $100.00  (Available Dec 31)
// ─────────────────
// Total:     $600.00
```

### 3. Idempotency for Financial Transactions

**Problem Identified**: Duplicate requests can result in double-charges.

**Solution**: Mandatory Idempotency-Key header + Redis deduplication

```go
// Idempotency middleware
func IdempotencyMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        // Only for state-changing operations
        if r.Method != "POST" && r.Method != "PUT" && r.Method != "DELETE" {
            next.ServeHTTP(w, r)
            return
        }

        // Require Idempotency-Key header
        idempotencyKey := r.Header.Get("Idempotency-Key")
        if idempotencyKey == "" {
            http.Error(w, `{"error": "missing_idempotency_key"}`, 400)
            return
        }

        // Validate format (UUID v4)
        if !isValidUUID(idempotencyKey) {
            http.Error(w, `{"error": "invalid_idempotency_key_format"}`, 400)
            return
        }

        // Check if request already processed
        cacheKey := fmt.Sprintf("idempotency:%s:%s", r.URL.Path, idempotencyKey)
        cached, err := redis.Get(ctx, cacheKey).Result()

        if err == nil {
            // Return cached response
            w.Header().Set("Content-Type", "application/json")
            w.Header().Set("X-Idempotent-Replay", "true")
            w.WriteHeader(http.StatusOK)
            w.Write([]byte(cached))
            return
        }

        // Create response recorder
        rec := &ResponseRecorder{
            ResponseWriter: w,
            Body:          new(bytes.Buffer),
        }

        // Process request
        next.ServeHTTP(rec, r)

        // Cache successful responses for 24 hours
        if rec.StatusCode >= 200 && rec.StatusCode < 300 {
            redis.Set(ctx, cacheKey, rec.Body.String(), 24*time.Hour)
        }
    })
}

// Apply to critical endpoints
router.HandleFunc("/api/v1/payments", IdempotencyMiddleware(paymentHandler))
router.HandleFunc("/api/v1/transactions", IdempotencyMiddleware(transactionHandler))
router.HandleFunc("/api/v1/rtp/send", IdempotencyMiddleware(rtpSendHandler))
```

**Mobile App Implementation**:

```swift
// iOS - Generate idempotency key for each payment
func initiatePayment(amount: Double, recipient: String) async {
    let idempotencyKey = UUID().uuidString

    var request = URLRequest(url: URL(string: "\(apiURL)/payments")!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = [
        "amount": amount,
        "recipient": recipient,
        "idempotency_key": idempotencyKey  // Also in body for retry logic
    ]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    // Retry logic with SAME idempotency key
    var attempts = 0
    while attempts < 3 {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Success - payment processed
                    return
                } else if httpResponse.statusCode >= 500 {
                    // Server error - retry with same key
                    attempts += 1
                    try await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(attempts))
                    continue
                } else {
                    // Client error - don't retry
                    throw PaymentError.failed
                }
            }
        } catch {
            attempts += 1
        }
    }
}
```

**Kong API Gateway Configuration**:

```yaml
# kong.yml - Enforce idempotency at gateway level
services:
  - name: payment-service
    url: http://payment-router:8081
    routes:
      - name: payments
        paths:
          - /api/v1/payments
          - /api/v1/transactions
          - /api/v1/rtp/send
        methods: [POST, PUT, DELETE]
        plugins:
          - name: request-validator
            config:
              header_schema:
                - name: Idempotency-Key
                  required: true
                  type: string
                  pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"
```

---

## Payment Flows

### 1. Same-Network P2P (Fastest)

**Scenario**: Jane (@jane) sends $100 to Emily (@emily), both on Titan

```
Jane's Wallet                 Titan Backend                Emily's Wallet
     │                              │                            │
     │ 1. Enter @emily, $100        │                            │
     ├──────────────────────────────►                            │
     │                              │                            │
     │                         2. HRS resolves:                  │
     │                            @emily → wal_002 → bal_002     │
     │                              │                            │
     │                         3. Fraud check (10ms)             │
     │                            ✓ Velocity OK                  │
     │                            ✓ Amount normal                │
     │                              │                            │
     │                         4. Check balance (5ms)            │
     │                            Jane bal_001: $1,000 ✓         │
     │                              │                            │
     │◄──── Confirm: Pay $100? ─────┤                            │
     │                              │                            │
     │ 5. Confirms (biometric)      │                            │
     ├──────────────────────────────►                            │
     │                              │                            │
     │                         6. Create Blnk transaction:       │
     │                            POST /transactions             │
     │                            {                              │
     │                              "source": "bal_001",         │
     │                              "destination": "bal_002",    │
     │                              "amount": 100.00,            │
     │                              "inflight": false,           │
     │                              "skip_queue": true           │
     │                            }                              │
     │                              │                            │
     │                         7. Committed instantly:           │
     │                            Jane: $1,000 → $900            │
     │                            Emily: $500 → $600             │
     │                              │                            │
     │◄──── Success ────────────────┤                            │
     │                              │                            │
     │                              ├───────────────────────────►│
     │                              │  Push: "You received $100  │
     │                              │   from @jane"              │
```

**Performance**: <50ms end-to-end
**No RTP needed**: Both users on same ledger

---

### 2. Cross-Network P2P (RTP via Trice.co)

**Scenario**: Jane (@jane on Titan) sends $100 to Bob (@bob on PhonePe)

```
Jane's Wallet              Titan Backend              Trice.co           Bob (PhonePe)
     │                          │                          │                   │
     │ 1. Enter @bob, $100      │                          │                   │
     ├──────────────────────────►                          │                   │
     │                          │                          │                   │
     │                     2. HRS resolves:                │                   │
     │                        @bob → external (PhonePe)    │                   │
     │                        Lookup routing info          │                   │
     │                          │                          │                   │
     │                     3. Fraud + balance check        │                   │
     │                          │                          │                   │
     │◄─ Confirm: Pay $100 via RTP to PhonePe user? ──────┤                   │
     │                          │                          │                   │
     │ 4. Confirms              │                          │                   │
     ├──────────────────────────►                          │                   │
     │                          │                          │                   │
     │                     5. Create INFLIGHT transaction: │                   │
     │                        POST /transactions           │                   │
     │                        {                            │                   │
     │                          "source": "bal_001",       │                   │
     │                          "destination": "rtp_out",  │                   │
     │                          "amount": 100.00,          │                   │
     │                          "inflight": true           │                   │
     │                        }                            │                   │
     │                        Jane: $1,000 → $900 (hold)   │                   │
     │                          │                          │                   │
     │                     6. Send RTP:                    │                   │
     │                        POST /v1/rtp/send ───────────►                   │
     │                        {                            │                   │
     │                          "source_va": "TRICE_VA_001"│                   │
     │                          "dest_routing": "987654321"│                   │
     │                          "dest_account": "BOB_ACCT" │                   │
     │                          "amount": 100.00           │                   │
     │                        }                            │                   │
     │                          │                          │                   │
     │                          │                     7. RTP processing:       │
     │                          │                        • Debit VA_001        │
     │                          │                        • Send to FedNow  ───►│
     │                          │                          │                   │
     │                          │                          │   8. Settlement   │
     │                          │                          │   (2-5 seconds)   │
     │                          │                          │                   │
     │                          │◄── 9. Webhook: SETTLED ──┤                   │
     │                          │    {                     │                   │
     │                          │      "status": "settled",│                   │
     │                          │      "txn_id": "..."     │                   │
     │                          │    }                     │                   │
     │                          │                          │                   │
     │                    10. Commit Blnk transaction:     │                   │
     │                        POST /transactions/{id}/commit│                  │
     │                        Jane: $900 (finalized)       │                   │
     │                          │                          │                   │
     │◄──── Success ────────────┤                          │                   │
     │      "Sent $100 via RTP" │                          │                   │
```

**Performance**: 2-10 seconds (RTP settlement time)
**Cost**: RTP transaction fee (typically $0.05-0.15)

---

### 3. Incoming RTP

**Scenario**: External user sends $200 to Jane (@jane) via bank transfer

```
External Bank          Trice.co              Titan Backend         Jane's Wallet
     │                      │                       │                    │
     │ 1. Customer initiates RTP:                   │                    │
     │    To: Routing #123456789                    │                    │
     │    Account: TRICE_VA_001                     │                    │
     │    Amount: $200                              │                    │
     ├──────────────────────►                       │                    │
     │                      │                       │                    │
     │                 2. RTP settlement:           │                    │
     │                    FedNow processes          │                    │
     │                    Credits TRICE_VA_001      │                    │
     │                      │                       │                    │
     │                 3. Trice webhook:            │                    │
     │                    POST /webhooks/trice ─────►                    │
     │                    {                         │                    │
     │                      "type": "incoming_rtp", │                    │
     │                      "va": "TRICE_VA_001",   │                    │
     │                      "amount": 200.00,       │                    │
     │                      "sender_info": {...}    │                    │
     │                    }                         │                    │
     │                      │                       │                    │
     │                      │                  4. Map VA → wallet:       │
     │                      │                     TRICE_VA_001 → wal_001 │
     │                      │                     → bal_001              │
     │                      │                       │                    │
     │                      │                  5. Create Blnk txn:       │
     │                      │                     POST /transactions     │
     │                      │                     {                      │
     │                      │                       "source": "rtp_in",  │
     │                      │                       "destination": "bal_001",
     │                      │                       "amount": 200.00,    │
     │                      │                       "status": "committed"│
     │                      │                     }                      │
     │                      │                     Jane: $900 → $1,100    │
     │                      │                       │                    │
     │                      │                       ├────────────────────►│
     │                      │                       │  Push: "Received   │
     │                      │                       │   $200 via RTP"    │
     │                      │                       │                    │
```

**Why committed immediately?**
- Funds already settled at Trice.co
- No risk of insufficient funds
- Can credit user immediately

---

### 4. QR Code Payment (Merchant)

**Scenario**: Customer pays $50 at Coffee Shop

```
Customer Wallet          Titan Backend          Merchant (Coffee Shop)
     │                        │                           │
     │                        │                      1. Merchant generates QR:
     │                        │                         Amount: $50           │
     │                        │                         Merchant: @coffee_shop│
     │                        │◄──────────────────────── QR displayed         │
     │                        │                           │
     │ 2. Scan QR code        │                           │
     ├────────────────────────►                           │
     │                        │                           │
     │                   3. Decode QR:                    │
     │                      Handle: @coffee_shop          │
     │                      Amount: $50                   │
     │                        │                           │
     │                   4. HRS resolves:                 │
     │                      @coffee_shop → merchant_bal   │
     │                        │                           │
     │◄─── Show confirmation: "Pay $50 to Coffee Shop?" ─┤
     │                        │                           │
     │ 5. Confirm             │                           │
     ├────────────────────────►                           │
     │                        │                           │
     │                   6. Same-network P2P flow:        │
     │                      (Customer bal → Merchant bal) │
     │                      Instant commit (<50ms)        │
     │                        │                           │
     │                        ├───────────────────────────►│
     │                        │     Webhook: Payment received
     │                        │     POS updates: PAID ✓   │
     │◄──── Receipt ──────────┤                           │
```

**QR Code Format**:
```
titan://pay?handle=@coffee_shop&amount=50.00&invoice=inv_12345&expires=1705334400
```

---

### 5. NFC Payment (Service Technician)

**Scenario**: Customer pays service technician $150 via tap-to-pay

```
Customer Wallet          Titan Backend          Technician POS
     │                        │                        │
     │                        │                   1. Technician enters $150
     │                        │                      Shows "Ready for NFC"  │
     │                        │                        │
     │ 2. Customer taps "Pay" │                        │
     │    Opens NFC           │                        │
     │                        │                        │
     │◄─────────── NFC handshake ────────────────────►│
     │   Exchange: merchant_id, amount                │
     │                        │                        │
     │ 3. Show confirmation:  │                        │
     │    "Pay $150 to ServiceCo Tech #4521?"         │
     │    [Confirm with Face ID]                      │
     │                        │                        │
     │ 4. Biometric auth      │                        │
     ├────────────────────────►                        │
     │                        │                        │
     │                   5. Instant transaction:       │
     │                      POST /transactions         │
     │                      (committed immediately)    │
     │                      Customer bal → Merchant bal│
     │                        │                        │
     │                        ├────────────────────────►│
     │   ◄───── NFC write: SUCCESS ───────────────────┤
     │                        │   POS shows: PAID ✓    │
     │                        │                        │
     │◄──── Receipt ──────────┤                        │
```

**NFC Data Format** (NDEF):
```json
{
  "merchant_id": "merch_4521",
  "amount": 150.00,
  "currency": "USD",
  "merchant_name": "ServiceCo Technician",
  "txn_ref": "unique_ref_12345"
}
```

---

## Reconciliation

### Daily Blnk ↔ Banking Provider

```
┌────────────────────────────────────────────────────────┐
│           Nightly Reconciliation (2:00 AM UTC)          │
└────────────────────────────────────────────────────────┘

Step 1: Sum all Blnk balances
┌──────────────────────────────────────┐
│ SELECT SUM(balance)                  │
│ FROM blnk.balances                   │
│ WHERE currency = 'USD'               │
└──────────────────────────────────────┘
Result: $10,234,567.89

Step 2: Query Banking Provider FBO account balance
┌──────────────────────────────────────┐
│ GET /api/accounts/fbo_master/balance │
└──────────────────────────────────────┘
Result: $10,234,567.89

Step 3: Compare
┌──────────────────────────────────────┐
│ Blnk Total:    $10,234,567.89        │
│ FBO Balance:   $10,234,567.89        │
│ Difference:    $0.00        ✓ MATCH  │
└──────────────────────────────────────┘

If mismatch:
┌──────────────────────────────────────┐
│ Blnk Total:    $10,234,567.89        │
│ FBO Balance:   $10,234,500.00        │
│ Difference:    $67.89        ❌      │
│                                       │
│ Actions:                              │
│ 1. Alert finance team (PagerDuty)    │
│ 2. Create ticket (JIRA)              │
│ 3. Query transaction logs             │
│ 4. Identify missing settlement        │
└──────────────────────────────────────┘
```

### Transaction-Level Reconciliation (Trice.co)

```
For each RTP transaction:

1. Titan creates Blnk transaction (outgoing)
   txn_001: Jane → external ($100)

2. Trice.co processes RTP
   rtp_abc123: TRICE_VA_001 → External Bank ($100)

3. Match by reference ID
   Titan txn_001.meta_data.trice_payment_id = "rtp_abc123"

4. Verify amounts match
   Blnk: $100.00
   Trice: $100.00 ✓

If amounts don't match:
   Create discrepancy ticket for manual review
```

---

## Database Schemas

### HRS Database (PostgreSQL)

```sql
-- Handle Registry
CREATE TABLE handles (
    handle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handle VARCHAR(255) UNIQUE NOT NULL,           -- 'jane'
    full_handle VARCHAR(255) UNIQUE NOT NULL,      -- '@jane'
    handle_type VARCHAR(50) NOT NULL,              -- 'user' | 'merchant'
    network_id VARCHAR(100) NOT NULL DEFAULT 'titan-wallet',

    -- Encrypted mappings (AES-256-GCM)
    wallet_id_encrypted BYTEA NOT NULL,
    blnk_balance_id_encrypted BYTEA NOT NULL,
    trice_virtual_account_encrypted BYTEA,

    -- Handle metadata
    verified BOOLEAN DEFAULT false,
    status VARCHAR(50) DEFAULT 'active',           -- 'active' | 'suspended' | 'deleted'

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    -- Indexes
    INDEX idx_handle (handle),
    INDEX idx_full_handle (full_handle),
    INDEX idx_network (network_id)
);

-- Cross-Network Routing
CREATE TABLE external_handles (
    external_handle_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handle VARCHAR(255) NOT NULL,                  -- 'bob'
    full_handle VARCHAR(255) NOT NULL,             -- '@bob@phonepe'
    network_id VARCHAR(100) NOT NULL,              -- 'phonepe'

    -- External routing info (encrypted)
    routing_number_encrypted BYTEA,
    account_number_encrypted BYTEA,
    network_metadata JSONB,                        -- Network-specific data

    -- Cache TTL
    cached_at TIMESTAMP,
    cache_expires_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW(),

    UNIQUE (handle, network_id)
);

-- Fraud Detection: Activity Log
CREATE TABLE handle_activity (
    activity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handle_id UUID REFERENCES handles(handle_id),

    activity_type VARCHAR(50) NOT NULL,            -- 'transaction' | 'login' | 'resolution'
    amount DECIMAL(20, 8),
    currency VARCHAR(10),

    -- Context
    ip_address INET,
    user_agent TEXT,
    device_fingerprint VARCHAR(255),
    geolocation JSONB,                             -- {lat, lon, city, country}

    -- Risk scoring
    risk_score INTEGER,                            -- 0-100
    risk_factors JSONB,                            -- ['high_velocity', 'unusual_amount']
    action_taken VARCHAR(50),                      -- 'approved' | 'challenged' | 'declined'

    created_at TIMESTAMP DEFAULT NOW(),

    INDEX idx_handle_time (handle_id, created_at DESC),
    INDEX idx_activity_type (activity_type)
);

-- Velocity tracking (for fraud detection)
CREATE TABLE velocity_limits (
    limit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    handle_id UUID REFERENCES handles(handle_id),

    -- Limits
    hourly_transaction_limit INTEGER DEFAULT 10,
    hourly_amount_limit DECIMAL(20, 2) DEFAULT 1000.00,
    daily_transaction_limit INTEGER DEFAULT 50,
    daily_amount_limit DECIMAL(20, 2) DEFAULT 5000.00,

    -- Current counters (reset periodically)
    current_hour_count INTEGER DEFAULT 0,
    current_hour_amount DECIMAL(20, 2) DEFAULT 0.00,
    current_day_count INTEGER DEFAULT 0,
    current_day_amount DECIMAL(20, 2) DEFAULT 0.00,

    last_reset_hourly TIMESTAMP,
    last_reset_daily TIMESTAMP,

    updated_at TIMESTAMP DEFAULT NOW()
);

-- Mapping table (wallet_id → blnk → trice)
CREATE TABLE wallet_mappings (
    wallet_id VARCHAR(100) PRIMARY KEY,

    -- Blnk references
    blnk_balance_id VARCHAR(100) UNIQUE NOT NULL,
    blnk_identity_id VARCHAR(100),
    blnk_ledger_id VARCHAR(100) DEFAULT 'titan_main_ledger',

    -- Trice.co references
    trice_virtual_account VARCHAR(100) UNIQUE NOT NULL,
    trice_customer_id VARCHAR(100),

    -- Banking provider references
    banking_provider_customer_id VARCHAR(100),

    -- User info (encrypted)
    user_email_encrypted BYTEA,
    user_phone_encrypted BYTEA,

    -- Status
    status VARCHAR(50) DEFAULT 'active',
    kyc_level INTEGER DEFAULT 1,                   -- 1: Basic, 2: Intermediate, 3: Full

    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),

    INDEX idx_blnk_balance (blnk_balance_id),
    INDEX idx_trice_va (trice_virtual_account)
);
```

### Blnk Database (Managed by Blnk)

Blnk manages its own PostgreSQL schema. Key tables:

```sql
-- Simplified view (actual schema is more complex)

CREATE TABLE ledgers (
    id SERIAL PRIMARY KEY,
    ledger_id VARCHAR(100) UNIQUE,
    name VARCHAR(255),
    created_at TIMESTAMP
);

CREATE TABLE balances (
    id SERIAL PRIMARY KEY,
    balance_id VARCHAR(100) UNIQUE,
    ledger_id VARCHAR(100) REFERENCES ledgers(ledger_id),

    -- Balances (stored as big.Int in Blnk)
    balance BIGINT NOT NULL,                       -- Available balance
    inflight_balance BIGINT DEFAULT 0,
    credit_balance BIGINT DEFAULT 0,
    debit_balance BIGINT DEFAULT 0,

    -- Currency
    currency VARCHAR(10) DEFAULT 'USD',
    currency_multiplier FLOAT DEFAULT 100,         -- 100 for USD (2 decimals)

    -- Version for optimistic locking
    version INTEGER DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE transactions (
    id SERIAL PRIMARY KEY,
    transaction_id VARCHAR(100) UNIQUE,
    parent_transaction VARCHAR(100),

    -- Amount (stored as big.Int)
    precise_amount BIGINT NOT NULL,
    amount FLOAT NOT NULL,                         -- Decimal representation
    precision FLOAT DEFAULT 100,

    -- Source/Destination
    source VARCHAR(100),                           -- Balance ID or external
    destination VARCHAR(100),

    -- Transaction metadata
    reference VARCHAR(255),
    description TEXT,
    currency VARCHAR(10) DEFAULT 'USD',
    rate FLOAT DEFAULT 1.0,                        -- For currency conversion

    -- Status
    status VARCHAR(50) NOT NULL,                   -- 'inflight' | 'committed' | 'void'
    inflight BOOLEAN DEFAULT false,
    hash VARCHAR(255),                             -- Transaction hash for integrity

    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    effective_date TIMESTAMP,                      -- For backdated transactions
    scheduled_for TIMESTAMP,                       -- For scheduled transactions
    inflight_expiry_date TIMESTAMP,

    -- Metadata
    meta_data JSONB,

    INDEX idx_transaction_id (transaction_id),
    INDEX idx_source (source),
    INDEX idx_destination (destination),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at DESC)
);
```

---

## API Specifications

### HRS API

#### Resolve Handle

```http
POST /api/v1/handles/resolve
Authorization: Bearer {jwt_token}
Content-Type: application/json

Request:
{
  "handle": "@emily",
  "network": "titan-wallet"  // Optional, defaults to titan-wallet
}

Response (200 OK):
{
  "handle": "@emily",
  "wallet_id": "wal_002",
  "balance_id": "bal_002",
  "network": "titan-wallet",
  "is_external": false,
  "verified": true
}

Response (external handle):
{
  "handle": "@bob@phonepe",
  "network": "phonepe",
  "is_external": true,
  "routing_info": {
    "routing_number": "987654321",
    "account_type": "external_rtp"
  }
}

Error (404):
{
  "error": "handle_not_found",
  "message": "Handle @xyz does not exist"
}
```

#### Check Fraud

```http
POST /api/v1/fraud/check
Authorization: Bearer {jwt_token}
Content-Type: application/json

Request:
{
  "wallet_id": "wal_001",
  "transaction_type": "p2p_send",
  "amount": 100.00,
  "currency": "USD",
  "destination_handle": "@emily",
  "context": {
    "ip_address": "192.168.1.1",
    "user_agent": "TitanWallet/iOS 1.0",
    "device_id": "device_abc123"
  }
}

Response (200 OK - Approved):
{
  "result": "approved",
  "risk_score": 15,
  "risk_factors": [],
  "action": "proceed"
}

Response (200 OK - Challenge):
{
  "result": "challenge",
  "risk_score": 65,
  "risk_factors": ["high_velocity", "unusual_amount"],
  "action": "require_2fa",
  "message": "Additional verification required"
}

Response (200 OK - Declined):
{
  "result": "declined",
  "risk_score": 95,
  "risk_factors": ["suspicious_location", "exceeded_limits"],
  "action": "block",
  "message": "Transaction blocked due to suspicious activity"
}
```

### Payment Router API

#### Initiate Payment

```http
POST /api/v1/payments
Authorization: Bearer {jwt_token}
Content-Type: application/json

Request:
{
  "source_handle": "@jane",
  "destination_handle": "@emily",
  "amount": 100.00,
  "currency": "USD",
  "payment_method": "handle",  // 'handle' | 'qr' | 'nfc'
  "description": "Dinner split",
  "metadata": {
    "invoice_id": "inv_12345"
  }
}

Response (200 OK - Same Network):
{
  "payment_id": "pay_xyz789",
  "status": "completed",
  "transaction_id": "txn_abc123",
  "route": "same_network",
  "processing_time_ms": 45,
  "source_balance_after": 900.00,
  "destination_handle": "@emily",
  "created_at": "2025-01-15T10:30:00Z"
}

Response (202 Accepted - Cross Network):
{
  "payment_id": "pay_xyz789",
  "status": "processing",
  "transaction_id": "txn_abc123",
  "route": "cross_network_rtp",
  "estimated_completion": "2025-01-15T10:30:05Z",
  "rtp_payment_id": "rtp_trice_456",
  "message": "RTP payment in progress. You'll receive notification when settled."
}

Error (400):
{
  "error": "insufficient_balance",
  "message": "Insufficient funds. Available: $50.00, Required: $100.00"
}

Error (403):
{
  "error": "fraud_check_failed",
  "message": "Transaction blocked due to suspicious activity. Please contact support."
}
```

### Blnk API (Subset - Blnk provides full API)

#### Create Transaction

```http
POST /transactions
Content-Type: application/json

Request:
{
  "source": "bal_001",
  "destination": "bal_002",
  "amount": 100.00,
  "currency": "USD",
  "precision": 100,
  "reference": "pay_xyz789",
  "description": "P2P payment: @jane to @emily",
  "inflight": false,
  "meta_data": {
    "payment_method": "handle",
    "source_handle": "@jane",
    "destination_handle": "@emily"
  }
}

Response (201 Created):
{
  "transaction_id": "txn_abc123",
  "source": "bal_001",
  "destination": "bal_002",
  "amount": 100.00,
  "precise_amount": "10000",
  "currency": "USD",
  "status": "committed",
  "hash": "a1b2c3d4...",
  "created_at": "2025-01-15T10:30:00Z"
}
```

#### Get Balance

```http
GET /balances/{balance_id}

Response (200 OK):
{
  "balance_id": "bal_001",
  "balance": "90000",           // Precise amount (900.00 * 100)
  "inflight_balance": "0",
  "credit_balance": "500000",
  "debit_balance": "410000",
  "currency": "USD",
  "currency_multiplier": 100,
  "version": 42,
  "created_at": "2025-01-01T00:00:00Z"
}
```

### Trice.co API Integration

#### Send RTP

```http
POST https://api.trice.co/v1/rtp/send
Authorization: Bearer {trice_api_key}
Content-Type: application/json

Request:
{
  "source_virtual_account": "TRICE_VA_001",
  "destination_routing_number": "987654321",
  "destination_account_number": "EXT_ACCT_789",
  "amount": 100.00,
  "currency": "USD",
  "description": "P2P payment from Titan Wallet",
  "idempotency_key": "pay_xyz789",
  "metadata": {
    "titan_payment_id": "pay_xyz789",
    "titan_transaction_id": "txn_abc123"
  }
}

Response (202 Accepted):
{
  "rtp_payment_id": "rtp_trice_456",
  "status": "processing",
  "source_va": "TRICE_VA_001",
  "amount": 100.00,
  "estimated_settlement": "2025-01-15T10:30:05Z",
  "created_at": "2025-01-15T10:30:00Z"
}
```

#### Trice.co Webhook (Incoming)

```http
POST https://titan-backend.com/webhooks/trice
Content-Type: application/json
X-Trice-Signature: {hmac_signature}

Webhook Payload:
{
  "event_type": "rtp.settled",
  "rtp_payment_id": "rtp_trice_456",
  "virtual_account": "TRICE_VA_001",
  "direction": "outgoing",
  "status": "settled",
  "amount": 100.00,
  "currency": "USD",
  "settled_at": "2025-01-15T10:30:04Z",
  "metadata": {
    "titan_payment_id": "pay_xyz789",
    "titan_transaction_id": "txn_abc123"
  }
}

Expected Response (200 OK):
{
  "received": true
}
```

---

## Security

### Encryption Strategy

```
┌────────────────────────────────────────────────────────┐
│                 Data Encryption Layers                  │
└────────────────────────────────────────────────────────┘

Layer 1: Application-Level (AES-256-GCM)
├─ PII data (email, phone, SSN)
├─ Bank account numbers
├─ Routing numbers
├─ Handle → wallet_id mappings
└─ External routing information

Layer 2: Database-Level (PostgreSQL pgcrypto)
├─ Transparent column encryption
└─ Encrypted backups

Layer 3: Disk-Level (LUKS)
├─ Full disk encryption for all database servers
└─ Encrypted PostgreSQL data directory

Layer 4: Network-Level (TLS 1.3)
├─ All service-to-service communication
├─ API Gateway to backend services
├─ Mobile app to API Gateway
└─ Trice.co API calls
```

### Authentication Flow

```
1. User Login
   Mobile App → Auth Service
   {username, password}

2. Auth Service verifies credentials
   - Check bcrypt password hash
   - Verify user not suspended

3. Generate JWT tokens
   access_token (15 min TTL):
   {
     "sub": "wal_001",
     "handle": "@jane",
     "kyc_level": 2,
     "exp": 1705334400,
     "iat": 1705333500
   }

   refresh_token (30 day TTL):
   {
     "sub": "wal_001",
     "token_id": "refresh_xyz",
     "exp": 1707925500
   }

4. Store refresh token in Redis
   KEY: "refresh_token:wal_001:refresh_xyz"
   VALUE: {user_id, device_id, created_at}
   TTL: 30 days

5. Mobile app stores tokens securely
   iOS: Keychain
   Android: EncryptedSharedPreferences

6. Subsequent API calls
   Authorization: Bearer {access_token}

7. API Gateway (Kong) validates JWT
   - Verify signature (RS256)
   - Check expiration
   - Extract claims

8. Token refresh (when access_token expires)
   POST /auth/refresh
   {refresh_token}

   Returns new access_token
```

---

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (AWS EKS)                │
└─────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │   CloudFlare    │
                    │  DDoS Protection│
                    │  CDN / WAF      │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  AWS ALB        │
                    │  Load Balancer  │
                    └────────┬────────┘
                             │
                ┌────────────┴──────────────┐
                │                           │
        ┌───────▼────────┐        ┌────────▼────────┐
        │ Kong Gateway   │        │ Kong Gateway    │
        │ (Replica 1)    │        │ (Replica 2)     │
        └───────┬────────┘        └────────┬────────┘
                │                           │
    ┌───────────┴───────────┬───────────────┴──────────┐
    │                       │                           │
┌───▼─────────┐   ┌─────────▼────────┐   ┌────────────▼─────┐
│ HRS Service │   │ Payment Router   │   │ Blnk Service     │
│ (10-50 pods)│   │ (5-30 pods)      │   │ (10-100 pods)    │
│             │   │                  │   │                  │
│ Autoscaling │   │ Autoscaling      │   │ Autoscaling      │
│ CPU > 70%   │   │ CPU > 70%        │   │ CPU > 70%        │
└───────┬─────┘   └─────────┬────────┘   └────────┬─────────┘
        │                   │                      │
        └───────────┬───────┴──────────────────────┘
                    │
        ┌───────────┴────────────────────┐
        │                                 │
┌───────▼─────────┐           ┌──────────▼──────────┐
│ Redis Cluster   │           │ PostgreSQL Cluster  │
│ (3M + 3R)       │           │ (1 Primary + 2 Rep) │
│                 │           │                     │
│ • Cache         │           │ • HRS DB            │
│ • Rate limiting │           │ • Blnk DB           │
│ • Sessions      │           │                     │
│ • Pub/Sub       │           │ • Patroni (HA)      │
└─────────────────┘           │ • pgBackRest backup │
                              └─────────────────────┘

External Services:
┌──────────────────┐  ┌───────────────────┐
│    Trice.co      │  │ Banking Provider  │
│   RTP Network    │  │ [TBD - Select]    │
│                  │  │                   │
│ • Virtual Accts  │  │ • FBO Account     │
│ • RTP Settlement │  │ • Settlement      │
│ • Webhooks       │  │ • KYC/Compliance  │
└──────────────────┘  └───────────────────┘
```

### Resource Allocation

```yaml
# HRS Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hrs-service
spec:
  replicas: 10
  template:
    spec:
      containers:
      - name: hrs
        image: titan/hrs:latest
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        env:
        - name: POSTGRES_DSN
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: hrs-dsn
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: url

---
# HPA (Horizontal Pod Autoscaler)
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hrs-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hrs-service
  minReplicas: 10
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
```

---

## Admin Dashboard & Operations Tools

### Why Admin Dashboard is Phase 1 Requirement

**Problem**: Support team cannot help users without visibility into transactions.

**User Support Scenario**:
```
User: "I sent $100 to @emily 2 hours ago but she says she didn't get it"

Support Agent needs to see:
- Did the transaction get created in Blnk?
- What's the transaction status?
- Did HRS resolve @emily correctly?
- Was there a fraud block?
- Is there a settlement delay?
```

### Required Admin Features

```
┌────────────────────────────────────────────────────┐
│           Admin Dashboard (Retool/Next.js)         │
├────────────────────────────────────────────────────┤
│                                                     │
│  1. User Management                                │
│     • Search by handle, email, phone               │
│     • View user profile & KYC status               │
│     • Transaction history (paginated)              │
│     • Current balance (all currencies)             │
│     • Suspend/unsuspend account                    │
│     • Adjust transaction limits                    │
│     • Manual KYC review & approval                 │
│                                                     │
│  2. Transaction Investigation                      │
│     • Search by ID, amount, date range             │
│     • View full transaction details:               │
│       - Blnk transaction ID                        │
│       - Source/destination balances                │
│       - Trice.co payment ID (if RTP)               │
│       - Fraud risk score                           │
│       - Settlement status                          │
│     • Reverse transaction (with approval)          │
│     • Add internal notes                           │
│                                                     │
│  3. Reconciliation Dashboard                       │
│     • Daily reconciliation status (✓ or ⚠)         │
│     • View discrepancies                           │
│     • Blnk total vs FBO total                      │
│     • Trice.co transaction matching                │
│     • Manual adjustment creation                   │
│                                                     │
│  4. Fraud & Compliance                             │
│     • Flagged transactions (high risk score)       │
│     • Suspended accounts                           │
│     • AML screening results                        │
│     • Sanctions hits                               │
│     • Generate SAR reports                         │
│     • Export audit logs                            │
│                                                     │
│  5. Analytics & Reports                            │
│     • Transaction volume charts (daily/weekly)     │
│     • Revenue metrics (fees collected)             │
│     • User growth (new signups)                    │
│     • Fraud rates & blocked transactions           │
│     • Top merchants by volume                      │
│     • Churn analysis                               │
│                                                     │
└────────────────────────────────────────────────────┘
```

### Implementation Recommendation: Retool

**Why Retool**:
- ✅ Built-in database connectors (PostgreSQL, REST APIs)
- ✅ Pre-built components (tables, charts, forms)
- ✅ RBAC (role-based access control)
- ✅ Audit logs built-in
- ✅ Can go from zero to working dashboard in 1-2 weeks
- ✅ $50/user/month (vs months of custom dev)

**Retool Setup**:

```javascript
// Connect to Blnk API
const blnkResource = {
  type: 'REST API',
  baseURL: 'http://blnk:5001',
  authentication: {
    type: 'bearer',
    token: '{{secrets.blnk_api_key}}'
  }
};

// Search transactions query
const searchTransactions = {
  resource: blnkResource,
  method: 'GET',
  url: '/transactions',
  params: {
    reference: '{{searchInput.value}}',
    limit: 50,
    offset: '{{table.pageOffset}}'
  }
};

// Display in table component
<Table
  data={{searchTransactions.data}}
  columns={[
    {key: 'transaction_id', label: 'ID'},
    {key: 'amount', label: 'Amount'},
    {key: 'status', label: 'Status'},
    {key: 'created_at', label: 'Date'}
  ]}
  onRowClick={(row) => openTransactionDetail(row)}
/>
```

**Alternative: Custom Next.js Admin**

```typescript
// If you need more customization

// app/admin/transactions/page.tsx
export default async function TransactionsPage({
  searchParams
}: {
  searchParams: { query?: string; page?: string }
}) {
  const transactions = await blnk.getTransactions({
    search: searchParams.query,
    page: Number(searchParams.page) || 1,
    limit: 50
  });

  return (
    <div className="p-8">
      <h1>Transactions</h1>
      <SearchBar />
      <TransactionTable data={transactions} />
      <Pagination totalPages={transactions.total_pages} />
    </div>
  );
}

// Components
function TransactionTable({ data }) {
  return (
    <table className="w-full">
      <thead>
        <tr>
          <th>ID</th>
          <th>Amount</th>
          <th>From</th>
          <th>To</th>
          <th>Status</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        {data.map(txn => (
          <tr key={txn.transaction_id}>
            <td><code>{txn.transaction_id}</code></td>
            <td>${txn.amount / 100}</td>
            <td>{txn.source}</td>
            <td>{txn.destination}</td>
            <td>
              <Badge color={getStatusColor(txn.status)}>
                {txn.status}
              </Badge>
            </td>
            <td>
              <Button onClick={() => viewDetails(txn)}>View</Button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

### Access Control

```sql
-- Admin users table
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255),

    role VARCHAR(50) NOT NULL,  -- 'viewer', 'agent', 'admin', 'super_admin'

    permissions JSONB,  -- {"can_suspend_users": true, "can_reverse_txns": false}

    -- Audit
    last_login_at TIMESTAMP,
    created_by UUID REFERENCES admin_users(id),
    created_at TIMESTAMP DEFAULT NOW(),

    INDEX idx_role (role)
);

-- Admin activity log
CREATE TABLE admin_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES admin_users(id),

    action VARCHAR(100) NOT NULL,  -- 'suspend_user', 'reverse_transaction', etc.
    target_type VARCHAR(50),       -- 'user', 'transaction', etc.
    target_id VARCHAR(100),

    details JSONB,
    ip_address INET,

    created_at TIMESTAMP DEFAULT NOW(),

    INDEX idx_admin_user (admin_user_id, created_at DESC),
    INDEX idx_action (action, created_at DESC)
);
```

---

## NFC vs QR for MVP

### PM Concern: NFC (Tap-to-Pay) is Too Complex for MVP

**Reality Check**:

| Aspect | NFC (SoftPOS) | QR Code |
|--------|---------------|---------|
| **iOS Requirements** | Tap to Pay on iPhone entitlement<br>Apple approval (difficult for startups) | Standard camera access |
| **Android Requirements** | Host Card Emulation (HCE)<br>NFC hardware required | Standard camera |
| **Development Time** | 8-12 weeks<br>Extensive certification | 1-2 weeks |
| **Merchant Hardware** | NFC-capable phone | Any phone with screen |
| **Certification** | EMV certification<br>PCI compliance (Level 1) | None |
| **Approval Time** | 2-6 months (Apple review) | Immediate |
| **Cost** | $10-30k for certification | $0 |

### Recommendation: Start with QR, Add NFC in Phase 2

**MVP Payment Methods** (Phase 1):
1. ✅ **P2P via Handles** (@emily) - Core feature
2. ✅ **QR Code Payments** - Easy for merchants
3. ✅ **RTP** - Cross-network

**Phase 2** (Months 6-9):
4. **NFC/Tap-to-Pay** - After establishing user base
5. **Physical Cards** - Debit card issuance

### QR Code Implementation (Simple & Effective)

```typescript
// Merchant generates QR code
function generatePaymentQR(
  merchantHandle: string,
  amount: number,
  invoiceId: string
): string {
  const payload = {
    merchant: merchantHandle,
    amount: amount,
    invoice: invoiceId,
    expires: Date.now() + (5 * 60 * 1000)  // 5 min expiry
  };

  const encoded = btoa(JSON.stringify(payload));
  return `titan://pay?data=${encoded}`;
}

// Display QR code
import QRCode from 'qrcode';

const qrCodeDataURL = await QRCode.toDataURL(qrCodeURL, {
  width: 300,
  margin: 2,
  color: {
    dark: '#000000',
    light: '#ffffff'
  }
});

// Customer scans and pays (standard P2P flow)
```

**Advantages**:
- ✅ Works on any phone
- ✅ No special hardware
- ✅ No certification required
- ✅ Familiar UX (Venmo, PayPal use QR)
- ✅ Can be printed (table tents, receipts)

---

## Rate Limiting Strategy (Revised)

### PM Concern: Handle Lookup Rate Limits Too Generous

**Original**: 100 requests/minute for handle lookups
**Problem**: Allows username enumeration (144k/day per IP)

### Updated Rate Limits

```yaml
# Kong API Gateway - Rate Limiting Configuration

services:
  - name: handle-resolution-service
    routes:
      - name: handle-resolve
        paths: [/api/v1/handles/resolve]
        plugins:
          # Unauthenticated lookups (very restrictive)
          - name: rate-limiting
            config:
              minute: 5              # ⚠️ Reduced from 100
              hour: 50
              policy: redis
              fault_tolerant: false
              hide_client_headers: false

          # Authenticated lookups (more generous)
          - name: rate-limiting
            config:
              minute: 30             # Per authenticated user
              hour: 500
              policy: redis
              header_name: Authorization

  - name: payment-service
    routes:
      - name: payments
        paths: [/api/v1/payments]
        plugins:
          - name: rate-limiting
            config:
              minute: 10             # Max 10 payments/min
              hour: 100
              day: 500

  - name: admin-api
    routes:
      - name: admin
        paths: [/api/v1/admin/*]
        plugins:
          - name: rate-limiting
            config:
              minute: 200            # Higher for admin tools
              hour: 5000
```

### Application-Level Rate Limiting (Per User)

```go
// Per-user rate limiting for sensitive operations
type UserRateLimiter struct {
    redis *redis.Client
}

func (r *UserRateLimiter) CheckLimit(
    userId string,
    action string,
    limit int,
    window time.Duration,
) (bool, error) {
    key := fmt.Sprintf("rate_limit:%s:%s", userId, action)

    // Increment counter
    count, err := r.redis.Incr(ctx, key).Result()
    if err != nil {
        return false, err
    }

    // Set expiry on first request
    if count == 1 {
        r.redis.Expire(ctx, key, window)
    }

    // Check if over limit
    if count > int64(limit) {
        return false, fmt.Errorf("rate limit exceeded: %d/%d", count, limit)
    }

    return true, nil
}

// Usage in payment handler
func HandlePayment(w http.ResponseWriter, r *http.Request) {
    userId := r.Context().Value("user_id").(string)

    // Check user-specific rate limit
    allowed, err := rateLimiter.CheckLimit(
        userId,
        "payment",
        10,  // 10 payments
        time.Minute,  // per minute
    )

    if !allowed {
        http.Error(w, `{
            "error": "rate_limit_exceeded",
            "message": "Maximum 10 payments per minute",
            "retry_after": 60
        }`, 429)
        return
    }

    // Process payment...
}
```

### DDoS Protection Layers

```
Layer 1: CloudFlare
├─ 1000 req/sec per IP (burst)
├─ Challenge on suspicious traffic
└─ Block known attack IPs

Layer 2: NGINX (API Gateway)
├─ 100 req/sec per IP (global)
├─ Connection limits
└─ Request size limits

Layer 3: Kong (Application Gateway)
├─ 10 req/min anonymous handle lookups
├─ 30 req/min authenticated lookups
└─ 10 payments/min per user

Layer 4: Application (HRS/Payment Router)
├─ Per-user limits (Redis)
├─ Per-handle limits (prevent spam to one user)
└─ CAPTCHA on repeated failures
```

---

## Missing Components Summary

Beyond the critical PM concerns, here are additional components needed:

### 1. Card Issuing Integration

```
┌────────────────────────────────────────────────┐
│  Card Issuing Provider (Lithic / Marqeta)     │
│                                                 │
│  • Virtual card creation                       │
│  • Physical card fulfillment                   │
│  • Apple Pay / Google Pay tokenization         │
│  • Card transaction webhooks                   │
│  • Spending controls API                       │
└────────────────┬───────────────────────────────┘
                 │
                 ▼
      ┌─────────────────────┐
      │  Card Transaction   │
      │  Handler            │
      │                     │
      │  On card swipe:     │
      │  1. Auth request    │
      │  2. Check balance   │
      │  3. Approve/Decline │
      │  4. Debit Blnk      │
      └─────────────────────┘
```

**Recommended**: Lithic ($0.50/card + $0.01/transaction)

### 2. Dispute Management

```sql
CREATE TABLE disputes (
    dispute_id UUID PRIMARY KEY,
    transaction_id VARCHAR(100),
    user_id VARCHAR(100),

    dispute_type VARCHAR(50),  -- 'unauthorized', 'not_received', 'wrong_amount'
    amount DECIMAL(20, 8),

    status VARCHAR(50),  -- 'pending', 'investigating', 'resolved', 'declined'

    -- Evidence
    user_description TEXT,
    merchant_response TEXT,
    evidence_urls JSONB,

    -- Resolution
    resolution VARCHAR(50),
    resolution_amount DECIMAL(20, 8),
    resolved_at TIMESTAMP,

    created_at TIMESTAMP DEFAULT NOW()
);
```

### 3. Push Notifications

```go
// APNs (iOS) + FCM (Android)
type NotificationService struct {
    apnsClient *apns2.Client
    fcmClient  *fcm.Client
}

func (s *NotificationService) SendTransactionAlert(
    userId string,
    txn Transaction,
) error {
    devices := getUserDevices(userId)

    for _, device := range devices {
        notification := &Notification{
            Title: "Payment Sent",
            Body:  fmt.Sprintf("You sent $%.2f to %s", txn.Amount, txn.Recipient),
            Data: map[string]string{
                "transaction_id": txn.ID,
                "type": "transaction",
            },
        }

        if device.Platform == "ios" {
            s.apnsClient.Push(notification)
        } else {
            s.fcmClient.Send(notification)
        }
    }

    return nil
}
```

### 4. Regulatory Reporting

```go
// SAR (Suspicious Activity Report) generation
type ComplianceReporting struct {}

func (c *ComplianceReporting) GenerateSAR(userId string) error {
    // Gather suspicious transactions
    suspiciousTxns := db.Query(`
        SELECT * FROM transactions
        WHERE user_id = $1
        AND risk_score > 70
        ORDER BY created_at DESC
    `, userId)

    // Generate FinCEN SAR XML
    sarXML := generateFinCENSAR(userId, suspiciousTxns)

    // File with FinCEN
    fileSAR(sarXML)

    return nil
}

// 1099-K tax reporting
func (c *ComplianceReporting) Generate1099K(year int) {
    // Users with >$600 and >200 transactions
    qualifyingUsers := db.Query(`
        SELECT user_id, SUM(amount), COUNT(*)
        FROM transactions
        WHERE EXTRACT(YEAR FROM created_at) = $1
        GROUP BY user_id
        HAVING SUM(amount) > 60000 AND COUNT(*) > 200
    `, year)

    for _, user := range qualifyingUsers {
        generate1099KForm(user)
        fileWithIRS(user)
    }
}
```

---

## Banking Provider Selection Guide

### Requirements

Your banking provider must support:

1. **FBO (For Benefit Of) Accounts**
   - Master pooled account structure
   - Ability to track individual user balances (via Blnk)

2. **Settlement & Transfers**
   - ACH transfers
   - Wire transfers
   - Integration with Trice.co for RTP settlement

3. **Compliance & KYC**
   - KYC verification API
   - AML screening
   - OFAC checks
   - SAR filing support

4. **Card Issuing** (Optional for MVP, but needed later)
   - Virtual card issuance
   - Physical card issuance
   - Card controls API

5. **API Integration**
   - REST API
   - Webhooks for balance updates
   - Sandbox environment for testing

### Recommended Options

| Provider | Pros | Cons | Cost |
|----------|------|------|------|
| **Unit.co** | Modern API, great docs, fast onboarding | Higher pricing | $0.50-1.00/user/mo |
| **Treasury Prime** | Multi-bank network, flexible | More complex setup | Custom pricing |
| **Column** | Developer-first, good API | Limited track record | $0.25-0.75/user/mo |
| **Stripe Treasury** | Stripe ecosystem, reliable | Higher fees | $0.50/user/mo + tx fees |
| **Bond** | Good compliance tools | API can be slow | Custom pricing |

### Evaluation Criteria

```
Score each provider (1-5):

Technical:
- API Quality & Documentation
- Sandbox Environment
- Webhook Reliability
- Uptime SLA

Compliance:
- KYC/AML Tools
- Regulatory Support
- Audit Trail

Cost:
- Per-user fees
- Transaction fees
- Monthly minimums

Integration:
- Time to go live
- Support quality
- Community/resources
```

---

## Next Steps

### Phase 1: Infrastructure & Core Services (Week 1-4) - REVISED

```
Week 1-2: Infrastructure
□ Set up AWS account & EKS cluster
□ Deploy PostgreSQL cluster (RDS or self-managed with Patroni)
□ Deploy Redis cluster (ElastiCache or self-managed)
□ Set up monitoring (Prometheus, Grafana, Jaeger)
□ Configure CI/CD (GitHub Actions)
□ Set up secrets management (AWS Secrets Manager)
□ Configure CloudFlare DDoS protection

Week 3-4: Ledger & HRS
□ Deploy Blnk ledger
  □ Create blnk.json config
  □ Initialize database with FBO account structure
  □ Test transaction creation
  □ Test inflight transaction flow
  □ Test balance queries

□ Build Handle Resolution Service (HRS) - ⚠️ CRITICAL
  □ Create database schema
  □ Implement handle resolution API
  □ Implement fraud detection engine
  □ Add three-tier caching (local → Redis → PostgreSQL)
  □ Implement rate limiting (5 req/min unauthenticated, 30 req/min authenticated)
  □ Add idempotency middleware
  □ Write unit tests
  □ Load test (target: <5ms p50, <20ms p99)

□ Build Payment Router
  □ Implement payment initiation API
  □ Add routing logic (same-network vs cross-network)
  □ Integrate with HRS
  □ Integrate with Blnk
  □ Implement idempotency for all financial operations
  □ Add settlement finality checks
  □ Write unit tests
```

### Phase 2: Banking & On-Ramping (Week 5-7) - NEW PRIORITY

```
Week 5: Banking Provider Selection
□ Evaluate Banking Providers
  □ Unit.co (recommended)
  □ Treasury Prime
  □ Column
  □ Stripe Treasury
  □ Decision criteria: FBO support, API quality, compliance tools

□ Set up Banking Provider (e.g., Unit.co)
  □ Create sandbox account
  □ Test FBO account creation
  □ Test virtual account creation
  □ Implement webhook handlers

Week 6: ACH Pull / On-Ramping - ⚠️ CRITICAL (PM CONCERN #1)
□ Integrate Plaid/Teller
  □ Set up Plaid account ($0.20/link + $0.10/ACH)
  □ Implement bank account linking UI
  □ Test ACH pull initiation

□ Build ACH Transfer Handler
  □ Create ach_transfers table
  □ Implement ACH pull flow (inflight → settled)
  □ Handle ACH settlement webhooks
  □ Handle ACH failures (void inflight transactions)
  □ Display pending funds in UI (Available vs Pending)

□ Settlement Finality Logic - ⚠️ CRITICAL (PM CONCERN #2)
  □ Implement IsSettlementFinal() checker
  □ Update incoming RTP handler:
    - FedNow/TCH_RTP → committed immediately
    - ACH/other → inflight until settled
  □ Update balance display:
    - Available balance (committed funds)
    - Pending balance (inflight funds)

Week 7: Trice.co RTP Integration
□ Set up Trice account
□ Test virtual account creation per user
□ Implement RTP send API (with idempotency)
□ Implement webhook handler (check settlement_status)
□ Test incoming/outgoing RTP
□ Test Request for Payment (RIP)
```

### Phase 3: Admin Tools & Operations (Week 8-9) - NEW

```
Week 8: Admin Dashboard - ⚠️ CRITICAL (PM CONCERN #4)
□ Set up Retool account ($50/user/month)
  □ Connect to PostgreSQL (HRS + Blnk)
  □ Connect to Blnk REST API

□ Build Core Admin Features
  □ User Management:
    - Search users (by handle, email, phone)
    - View transaction history
    - View current balance (all currencies)
    - Suspend/unsuspend accounts
    - Adjust transaction limits

  □ Transaction Investigation:
    - Search transactions
    - View full details (Blnk ID, Trice ID, fraud score, settlement status)
    - Add internal notes
    - View related transactions

  □ Reconciliation Dashboard:
    - Daily recon status
    - Blnk total vs FBO balance
    - Trice transaction matching
    - View discrepancies

  □ Fraud & Compliance:
    - Flagged transactions
    - AML screening results
    - Generate SAR reports

Week 9: Push Notifications & Monitoring
□ Set up APNs (Apple Push Notification Service)
  □ Create Apple Developer certificate
  □ Configure push notification server

□ Set up FCM (Firebase Cloud Messaging)
  □ Create Firebase project
  □ Integrate FCM SDK

□ Build Notification Service
  □ Transaction alerts ("You sent $100")
  □ Security alerts ("New device login")
  □ ACH settlement notifications ("$100 now available")

□ Enhanced Monitoring
  □ Set up PagerDuty for critical alerts
  □ Configure Sentry for error tracking
  □ Create runbook for common issues
```

### Phase 4: Native Mobile Apps (Week 10-16)

```
Week 10-13: iOS App (Swift + SwiftUI)
□ Set up Xcode project
  □ Configure app signing
  □ Set up Keychain for secure storage
  □ Implement SSL certificate pinning

□ Authentication Flow
  □ Phone number verification (Twilio)
  □ Biometric authentication (Face ID/Touch ID)
  □ JWT token storage in Keychain

□ Core Wallet Features
  □ Balance display (Available + Pending)
  □ P2P payments via @handle
  □ Transaction history
  □ QR code scanning for merchant payments
  □ ACH pull (link bank account via Plaid)

□ Security Features
  □ Idempotency-Key header on all payments
  □ Retry logic with same idempotency key
  □ Root/jailbreak detection

□ TestFlight Beta
  □ Internal testing (10 users)
  □ External testing (100 users)

Week 14-16: Android App (Kotlin + Jetpack Compose)
□ Set up Android Studio project
  □ Configure app signing
  □ Set up Android Keystore for secure storage
  □ Implement SSL certificate pinning

□ Authentication Flow
  □ Phone number verification
  □ Biometric authentication
  □ JWT token storage in EncryptedSharedPreferences

□ Core Wallet Features
  □ Balance display (Available + Pending)
  □ P2P payments via @handle
  □ Transaction history
  □ QR code scanning
  □ ACH pull (Plaid integration)

□ Google Play Beta
  □ Internal testing (10 users)
  □ External testing (100 users)

⚠️ NFC REMOVED FROM PHASE 1 (PM CONCERN #5)
   - Too complex (EMV certification, Apple approval)
   - QR code sufficient for MVP
   - Add NFC in Phase 2 after establishing user base
```

### Phase 5: Testing, Security & Launch (Week 17-20)

```
Week 17-18: Comprehensive Testing
□ End-to-end testing
  □ P2P same-network (instant)
  □ P2P cross-network (RTP via Trice)
  □ ACH pull (funding wallet)
  □ QR code merchant payments
  □ Reconciliation flows (Blnk ↔ Banking Provider)
  □ Settlement finality (FedNow vs ACH)

□ Load testing
  □ Target: 1000 TPS sustained
  □ Handle resolution: <5ms p50, <20ms p99
  □ Payment processing: <100ms p50
  □ Blnk transaction throughput: 10,000 TPS

□ Idempotency testing - ⚠️ CRITICAL (PM CONCERN #3)
  □ Test duplicate payment requests (should return cached response)
  □ Test retry logic in mobile apps
  □ Test timeout scenarios
  □ Verify 24-hour idempotency key caching

□ Float risk testing - ⚠️ CRITICAL (PM CONCERN #2)
  □ Verify FedNow payments credited immediately (final settlement)
  □ Verify ACH payments stay inflight until settled
  □ Test balance display (Available vs Pending)
  □ Test spending only available balance

Week 19: Security Audit
□ Penetration testing (hire external firm)
  □ API security (rate limiting, authentication bypass attempts)
  □ Mobile app security (root detection, SSL pinning)
  □ Database security (SQL injection, access controls)

□ Code review
  □ Security-focused code review
  □ Idempotency implementation review
  □ Encryption verification (Keychain, Keystore)

□ Compliance check
  □ KYC/AML procedures documented
  □ SAR reporting process tested
  □ Data retention policies implemented
  □ Privacy policy & ToS drafted

Week 20: Launch Preparation
□ Production environment setup
  □ Configure Kubernetes production cluster
  □ Set up production databases with backups
  □ Configure monitoring & alerts
  □ Set up log aggregation
  □ Prepare incident response plan

□ Operations readiness
  □ Train support team on admin dashboard
  □ Create support documentation
  □ Set up on-call rotation
  □ Test disaster recovery procedures

□ Phased Launch
  □ Week 20 Day 1-3: Internal launch (10 employees)
  □ Week 20 Day 4-5: Friends & family (50 users)
  □ Week 20 Day 6-7: Beta launch (500 users)
  □ Monitor metrics, fraud rates, support tickets

□ Post-launch monitoring (first 2 weeks)
  □ Daily reconciliation checks
  □ Fraud detection tuning
  □ Performance optimization
  □ Bug fixes

□ Full public launch (Week 22)
```

---

## Updated Technology Decisions Summary

| Component | Decision | Rationale |
|-----------|----------|-----------|
| **Mobile Apps** | Native (Swift + Kotlin) | Security, biometrics, hardware access |
| **Ledger** | Blnk | Fast integration, built-in reconciliation |
| **RTP Provider** | Trice.co | Virtual accounts + RTP network |
| **Banking Provider** | Unit.co (recommended) | Modern API, FBO support, compliance tools |
| **On-Ramping** | Plaid + ACH Pull | Standard in fintech, familiar UX |
| **Admin Dashboard** | Retool | Fast to build, 1-2 weeks vs months |
| **Card Issuing** | Phase 2 (Lithic) | Not critical for MVP |
| **Merchant Payments** | QR Code (MVP), NFC (Phase 2) | QR is sufficient, NFC too complex |
| **HRS** | Custom build (Go) | Competitive moat, no existing solution |
| **Push Notifications** | APNs + FCM | Industry standard |

---

## Critical PM Concerns - Resolution Summary

| Concern | Resolution | Implementation |
|---------|------------|----------------|
| **#1: On-Ramping** | ACH Pull via Plaid/Teller | Week 6 (Phase 2) |
| **#2: Float Risk** | Settlement finality checks | Week 6-7 (inflight for non-final) |
| **#3: Idempotency** | Mandatory Idempotency-Key header | Week 3-4 (Core Services) |
| **#4: Admin Dashboard** | Retool dashboard | Week 8 (Phase 3) |
| **#5: NFC Complexity** | Removed from MVP, QR only | Phase 1 uses QR, NFC in Phase 2 |
| **#6: Rate Limiting** | 5 req/min unauthenticated | Week 3-4 (HRS implementation) |

---

## Conclusion

The corrected architecture is simpler and more focused:

**Core Stack**:
- ✅ **Blnk**: Ledger (multi-currency, crypto-ready, reconciliation)
- ✅ **Trice.co**: RTP network (virtual accounts, routing, settlement)
- ✅ **Banking Provider [TBD]**: FBO account, compliance, settlement
- ✅ **Custom Go Services**: HRS, Payment Router, Reconciliation

**Removed**:
- ❌ Bambu (defunct)
- ❌ Galileo (not needed with Trice.co providing virtual accounts)

**Benefits**:
1. Simpler architecture = faster time to market
2. Trice.co handles RTP complexity
3. Blnk handles all ledger logic
4. Clear separation of concerns
5. Easier to understand and maintain

**Performance Targets**:
- Same-network P2P: <50ms
- Handle resolution: <5ms (p50), <20ms (p99)
- Cross-network RTP: 2-10 seconds (network latency)
- System throughput: 1000+ TPS

This architecture is production-ready and scales to millions of users.
