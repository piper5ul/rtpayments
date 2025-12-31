# Mobile App Fork Strategy - Consumer & Merchant Apps

**Date:** 2025-12-30
**Decision:** Use ios-wallet-app and android-wallet-app for BOTH consumer and merchant applications

---

## 🎯 Strategy Overview

We'll create **4 mobile applications** from **2 source repositories**:

```
Source: ios-wallet-app (42,000 LOC)
  ├─ Fork 1: titan-consumer-ios (Consumer wallet)
  └─ Fork 2: titan-merchant-ios (Merchant payment acceptance)

Source: android-wallet-app (30,000+ LOC)
  ├─ Fork 1: titan-consumer-android (Consumer wallet)
  └─ Fork 2: titan-merchant-android (Merchant payment acceptance)
```

**Key Insight:** The base banking app has 95% of features needed for BOTH consumer and merchant apps. We'll enable/disable features and add merchant-specific UI on top.

---

## 📊 Feature Matrix - Consumer vs. Merchant

| Feature | Consumer App | Merchant App | In Base App? |
|---------|--------------|--------------|--------------|
| **Authentication** | ✅ Required | ✅ Required | ✅ Yes (Auth0) |
| **KYC Verification** | ✅ Personal KYC | ⚠️ Business KYB | ✅ Yes (both) |
| **Dashboard/Home** | ✅ Balance, transactions | ✅ Sales, settlements | ✅ Yes (rebrand) |
| **Send Money** | ✅ @handle, ACH, wire | ❌ Not needed | ✅ Yes (hide for merchant) |
| **Receive Money** | ✅ QR codes, @handle | ✅ **PRIMARY FEATURE** | ✅ Yes (emphasize for merchant) |
| **Request Payment** | ✅ Occasional use | ✅ **PRIMARY FEATURE** | ✅ Yes (make prominent) |
| **Transaction History** | ✅ Show all transactions | ✅ Show sales only | ✅ Yes (filter logic) |
| **Contacts** | ✅ Send money to contacts | ✅ Customer directory | ✅ Yes (rename to "Customers") |
| **Cards** | ✅ Debit card, Apple/Google Pay | ❌ Not needed | ✅ Yes (hide for merchant) |
| **Add Funds (ACH Pull)** | ✅ Pull from bank | ❌ Not needed | ✅ Yes (hide for merchant) |
| **Bank Account Details** | ✅ View routing/account | ✅ View settlement account | ✅ Yes (both need it) |
| **QR Code Generation** | ✅ Receive payments | ✅ **PRIMARY FEATURE** | ✅ Yes (make prominent) |
| **Settings/Profile** | ✅ Standard | ✅ Business profile | ✅ Yes (adapt UI) |
| **Notifications** | ✅ Payment received | ✅ Sale notifications | ✅ Yes (same) |
| **Sales Dashboard** | ❌ Not needed | ✅ **NEW FEATURE** | ❌ **Add analytics** |
| **Refund Management** | ❌ Not needed | ✅ **NEW FEATURE** | ❌ **Add refund UI** |
| **Invoice Generation** | ❌ Not needed | ✅ **NEW FEATURE** | ❌ **Add invoice feature** |

**Summary:**
- ✅ **Consumer app:** Use 80% of base features as-is, hide cards/add funds
- ✅ **Merchant app:** Use 60% of base features, hide send/cards, ADD sales dashboard/refunds/invoices

---

## 🍴 Fork Strategy - Step by Step

### Phase 1: Consumer Apps (Weeks 1-4)

#### 1.1 iOS Consumer App (Week 1-2)

**Step 1: Fork & Setup (Day 1)**
```bash
# Create new repo on GitHub
gh repo create piper5ul/titan-consumer-ios --public --description "Titan Wallet - Consumer iOS App"

# Clone the source
cd /Users/pushkar/Downloads/rtpayments
cp -R external_repos/ios-wallet-app titan-consumer-ios
cd titan-consumer-ios

# Initialize git
git init
git remote add origin https://github.com/piper5ul/titan-consumer-ios.git
git add .
git commit -m "Initial fork from Solid.fi wallet app

Base: ios-wallet-app (42,000 LOC)
Features: Auth0, KYC, Accounts, Cards, Payments, Plaid
Status: Production-ready Solid.fi banking app

Next: Rebrand to Titan Wallet"
git push -u origin main
```

**Step 2: Rebrand (Day 1-2)**

Update branding in key files:

**File 1: AppMetaData.json** (`Solid/Solid/Source/Classes/Utilities/App Utils/AppMetaData.json`)
```json
{
    "name": "Titan Wallet",
    "primaryColor": "#667eea",
    "darkPrimaryColor": "#FFFFFF",
    "primaryTextColor": "#000000",
    "darkPrimaryTextColor": "#FFFFFF",
    "secondaryColor": "#764ba2",
    "darkSecondaryColor": "#EBEBF5",
    "ctaColor": "#667eea",
    "darkCtaColor": "#764ba2",
    "ctaTextColor": "#FFFFFF",
    "darkCtaTextColor": "#000000",
    "ui": {
        "isTestModeEnabled": true,
        "isSendCardByMailVisible": false,
        "isPullFundsEnabled": true,
        "isIntrabankTransferEnabled": true,
        "isToAnotherBankEnabled": true,
        "isDepositCheckEnabled": false,
        "isSendMoneyIntraBankEnabled": true,
        "isSendMoneyACHEnabled": true,
        "isSendMoneyCheckEnabled": false,
        "isSendMoneyDomesticwireEnabled": true,
        "isSendMoneyVisaCardEnabled": false,
        "isContactMakePaymentEnabled": true,
        "isAddToWalletEnabled": true
    },
    "env": {
        "prod": {
            "auth0ClientId": "YOUR_AUTH0_CLIENT_ID",
            "auth0Audience": "https://api.titan.wallet",
            "auth0Domain": "titan-wallet.us.auth0.com",
            "segmentKey": "YOUR_SEGMENT_KEY"
        },
        "prodtest": {
            "auth0ClientId": "YOUR_AUTH0_TEST_CLIENT_ID",
            "auth0Audience": "https://api.titan.wallet",
            "auth0Domain": "titan-wallet-test.us.auth0.com",
            "segmentKey": "YOUR_SEGMENT_TEST_KEY"
        }
    },
    "supportedCountries": [
        {
            "name": "United States",
            "dial_code": "+1",
            "code": "US",
            "maxLength": 10
        }
    ],
    "supportMail": "support@titanwallet.com",
    "lcbTerms": "https://titanwallet.com/terms",
    "platformTerms": "https://titanwallet.com/platform-terms",
    "walletTerms": "https://titanwallet.com/wallet-terms",
    "helpCenter": "https://help.titanwallet.com",
    "disclosures": "https://titanwallet.com/disclosures",
    "auth0Terms": "https://titanwallet.com/auth0-terms",
    "auth0Privacy": "https://titanwallet.com/privacy",
    "appUrl": "https://apps.apple.com/us/app/titan-wallet/XXXXXXXXX"
}
```

**File 2: Xcode Project Settings**
- Open `Solid/Solid.xcworkspace` in Xcode
- Update Display Name: "Titan Wallet"
- Update Bundle Identifier: `com.titanwallet.consumer`
- Update App Icons (replace in `Assets.xcassets/AppIcon.appiconset/`)
- Update Launch Screen

**File 3: Info.plist**
- Update app name
- Update URL schemes

**Step 3: API Integration (Day 3-5)**

Create new API manager wrapper for Titan services:

**File: `TitanAPIManager.swift`** (new file in `Source/Classes/Networking/`)
```swift
import Foundation

class TitanAPIManager {
    static let shared = TitanAPIManager()

    private let baseURL: String

    private init() {
        #if DEBUG
        baseURL = "http://localhost:8000" // Local dev
        #else
        baseURL = "https://api.titanwallet.com" // Production
        #endif
    }

    // MARK: - Service Endpoints

    struct Endpoints {
        // Auth Service (Port 8004)
        static let authRegister = "/auth/register"
        static let authLogin = "/auth/login"
        static let authRefresh = "/auth/refresh"
        static let authLogout = "/auth/logout"
        static let authVerify = "/auth/verify"

        // HRS (Port 8001)
        static let handleResolve = "/handles/resolve"
        static let handleCreate = "/handles"

        // Payment Router (Port 8002)
        static let paymentInitiate = "/payments/initiate"
        static let paymentStatus = "/payments/:id/status"
        static let transactionHistory = "/transactions"

        // User Management (Port 8006)
        static let userProfile = "/users/profile"
        static let userKYC = "/users/kyc"

        // ACH Service (Port 8003)
        static let achPlaidToken = "/ach/plaid/token"
        static let achLink = "/ach/link"
        static let achTransfer = "/ach/transfer"

        // Blnk Ledger (Port 5001)
        static let ledgerBalance = "/balances/:id"
        static let ledgerTransaction = "/transactions"
    }

    // MARK: - Helper Methods

    func resolveHandle(_ handle: String, completion: @escaping (Result<HandleResolution, Error>) -> Void) {
        let urlString = "\(baseURL):8001\(Endpoints.handleResolve)?handle=\(handle)"
        // Implementation using existing Alamofire patterns from APIManager.swift
    }

    func initiatePayment(_ payment: Payment, completion: @escaping (Result<PaymentResponse, Error>) -> Void) {
        let urlString = "\(baseURL):8002\(Endpoints.paymentInitiate)"
        // Implementation
    }
}

struct HandleResolution: Codable {
    let handle: String
    let walletID: String
    let balanceID: String
    let network: String
}

struct Payment: Codable {
    let toHandle: String
    let amount: Decimal
    let currency: String
    let memo: String?
    let idempotencyKey: String
}

struct PaymentResponse: Codable {
    let paymentID: String
    let status: String
    let estimatedSettlement: Date
}
```

**Step 4: Update Send Money Flow with @handle Support (Day 6-8)**

Modify `Source/Classes/Post Origination/Send/PaymentVC.swift`:

```swift
// Add @handle field
@IBOutlet weak var handleTextField: UITextField!

func sendPayment() {
    guard let recipient = handleTextField.text, recipient.hasPrefix("@") else {
        showError("Please enter a valid @handle (e.g., @alice)")
        return
    }

    // Step 1: Resolve handle via HRS
    TitanAPIManager.shared.resolveHandle(recipient) { [weak self] result in
        switch result {
        case .success(let resolution):
            // Step 2: Initiate payment via Payment Router
            let payment = Payment(
                toHandle: recipient,
                amount: self?.amount ?? 0,
                currency: "USD",
                memo: self?.memo,
                idempotencyKey: UUID().uuidString
            )

            TitanAPIManager.shared.initiatePayment(payment) { paymentResult in
                switch paymentResult {
                case .success(let response):
                    self?.showSuccess("Payment sent to \(recipient)!")
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }

        case .failure(let error):
            self?.showError("Handle not found: \(error.localizedDescription)")
        }
    }
}
```

**Step 5: Testing (Day 9-10)**
- Test Auth0 login flow
- Test @handle resolution
- Test send money flow
- Test transaction history
- Test Plaid bank linking
- Test card management
- Device testing (iPhone 12, 13, 14, 15)

**Step 6: Build & Submit (Day 11-14)**
- Archive for distribution
- Upload to App Store Connect
- Submit for TestFlight review
- Add beta testers

---

#### 1.2 Android Consumer App (Week 3-4)

**Step 1: Fork & Setup (Day 1)**
```bash
# Create new repo
gh repo create piper5ul/titan-consumer-android --public --description "Titan Wallet - Consumer Android App"

# Clone source
cd /Users/pushkar/Downloads/rtpayments
cp -R external_repos/android-wallet-app titan-consumer-android
cd titan-consumer-android

# Initialize git
git init
git remote add origin https://github.com/piper5ul/titan-consumer-android.git
git add .
git commit -m "Initial fork from Solid.fi wallet app

Base: android-wallet-app (377 Kotlin files)
Features: Auth0, KYC, Accounts, Cards, Google Pay, Payments
Status: Production-ready Solid.fi banking app

Next: Rebrand to Titan Wallet"
git push -u origin main
```

**Step 2: Rebrand (Day 1-2)**

Update `wise-android-v2-core/src/main/cpp/native-lib.cpp`:
```cpp
// Update API base URLs
extern "C" JNIEXPORT jstring JNICALL
Java_us_titan_android_core_secure_Keys_getBaseUrl(JNIEnv* env, jobject /* this */) {
    return env->NewStringUTF("https://api.titanwallet.com");
}

extern "C" JNIEXPORT jstring JNICALL
Java_us_titan_android_core_secure_Keys_getAuth0ClientId(JNIEnv* env, jobject /* this */) {
    return env->NewStringUTF("YOUR_AUTH0_CLIENT_ID");
}

extern "C" JNIEXPORT jstring JNICALL
Java_us_titan_android_core_secure_Keys_getAuth0Domain(JNIEnv* env, jobject /* this */) {
    return env->NewStringUTF("titan-wallet.us.auth0.com");
}
```

Update `app/src/main/res/values/strings.xml`:
```xml
<resources>
    <string name="app_name">Titan Wallet</string>
    <string name="support_email">support@titanwallet.com</string>
</resources>
```

Update package names:
- Refactor `us.solid.android.*` → `com.titanwallet.consumer.*`

**Step 3: API Integration (Day 3-5)**

Create `TitanAPIClient.kt` in `wise-android-v2-core` module:
```kotlin
package com.titanwallet.core.network

import retrofit2.http.*

interface TitanAPIClient {

    // HRS Service
    @GET("handles/resolve")
    suspend fun resolveHandle(@Query("handle") handle: String): HandleResolution

    @POST("handles")
    suspend fun createHandle(@Body request: CreateHandleRequest): HandleResponse

    // Payment Router
    @POST("payments/initiate")
    suspend fun initiatePayment(@Body payment: Payment): PaymentResponse

    @GET("transactions")
    suspend fun getTransactions(): List<Transaction>

    // User Management
    @GET("users/profile")
    suspend fun getUserProfile(): UserProfile

    @POST("users/kyc")
    suspend fun submitKYC(@Body kyc: KYCRequest): KYCResponse
}

data class HandleResolution(
    val handle: String,
    val walletID: String,
    val balanceID: String,
    val network: String
)

data class Payment(
    val toHandle: String,
    val amount: Double,
    val currency: String,
    val memo: String?,
    val idempotencyKey: String
)
```

**Step 4: Update Send Flow (Day 6-8)**
- Add @handle input field
- Integrate HRS resolution
- Update payment initiation

**Step 5: Testing (Day 9-10)**
- Test on multiple Android versions (API 23-34)
- Test on various screen sizes
- Google Pay integration testing

**Step 6: Build & Submit (Day 11-14)**
- Generate signed APK/AAB
- Upload to Google Play Console
- Submit to Internal Testing track

---

### Phase 2: Merchant Apps (Weeks 5-6)

#### 2.1 iOS Merchant App (Week 5)

**Strategy:** Fork consumer iOS app and add merchant-specific features

**Step 1: Fork from Consumer (Day 1)**
```bash
cd /Users/pushkar/Downloads/rtpayments
cp -R titan-consumer-ios titan-merchant-ios
cd titan-merchant-ios

git remote set-url origin https://github.com/piper5ul/titan-merchant-ios.git
```

**Step 2: Rebrand for Merchant (Day 1)**

Update `AppMetaData.json`:
```json
{
    "name": "Titan Merchant",
    "ui": {
        "isPullFundsEnabled": false,
        "isSendMoneyIntraBankEnabled": false,
        "isSendMoneyACHEnabled": false,
        "isSendMoneyCheckEnabled": false,
        "isSendMoneyDomesticwireEnabled": false,
        "isAddToWalletEnabled": false
    }
}
```

**Step 3: Add Merchant Features (Day 2-4)**

**Feature 1: QR Code Generation (Prominent)**

Create `MerchantQRGeneratorVC.swift`:
```swift
import UIKit
import CoreImage

class MerchantQRGeneratorVC: UIViewController {

    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var invoiceIDTextField: UITextField!

    var merchantHandle: String = "@merchant_user"

    func generateStaticQR() {
        // QR contains: titan://pay/{merchantHandle}
        let qrData = "titan://pay/\(merchantHandle)"
        qrImageView.image = generateQRCode(from: qrData)
    }

    func generateDynamicQR() {
        // QR contains: titan://pay/{merchantHandle}?amount={amount}&invoice={invoiceID}
        let amount = amountTextField.text ?? "0"
        let invoice = invoiceIDTextField.text ?? UUID().uuidString
        let qrData = "titan://pay/\(merchantHandle)?amount=\(amount)&invoice=\(invoice)"
        qrImageView.image = generateQRCode(from: qrData)
    }

    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: .utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let qrImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQR = qrImage.transformed(by: transform)

        return UIImage(ciImage: scaledQR)
    }

    @IBAction func shareQRCode() {
        guard let qrImage = qrImageView.image else { return }
        let activityVC = UIActivityViewController(activityItems: [qrImage], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}
```

**Feature 2: Sales Dashboard**

Create `MerchantDashboardVC.swift`:
```swift
import UIKit

class MerchantDashboardVC: UIViewController {

    @IBOutlet weak var todaySalesLabel: UILabel!
    @IBOutlet weak var weekSalesLabel: UILabel!
    @IBOutlet weak var monthSalesLabel: UILabel!
    @IBOutlet weak var transactionCountLabel: UILabel!
    @IBOutlet weak var averageTransactionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSalesData()
    }

    func loadSalesData() {
        TitanAPIManager.shared.getMerchantSales { [weak self] result in
            switch result {
            case .success(let sales):
                self?.todaySalesLabel.text = "$\(sales.today)"
                self?.weekSalesLabel.text = "$\(sales.week)"
                self?.monthSalesLabel.text = "$\(sales.month)"
                self?.transactionCountLabel.text = "\(sales.transactionCount)"
                self?.averageTransactionLabel.text = "$\(sales.averageTransaction)"
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }
}
```

**Feature 3: Refund Management**

Create `RefundVC.swift`:
```swift
import UIKit

class RefundVC: UIViewController {

    var transaction: Transaction!

    @IBOutlet weak var refundAmountTextField: UITextField!
    @IBOutlet weak var reasonTextField: UITextField!

    @IBAction func initiateRefund() {
        guard let amount = Double(refundAmountTextField.text ?? "0") else { return }
        guard let reason = reasonTextField.text, !reason.isEmpty else {
            showError("Please provide a reason")
            return
        }

        let refund = RefundRequest(
            transactionID: transaction.id,
            amount: amount,
            reason: reason
        )

        TitanAPIManager.shared.initiateRefund(refund) { [weak self] result in
            switch result {
            case .success:
                self?.showSuccess("Refund initiated")
                self?.dismiss(animated: true)
            case .failure(let error):
                self?.showError(error.localizedDescription)
            }
        }
    }
}
```

**Step 4: Update Tab Bar (Day 4)**

Replace consumer tabs with merchant tabs:
- **Home** → Sales Dashboard
- **Accept** → QR Code Generator
- **Transactions** → Sales History (filter to incoming only)
- **Customers** → Customer Directory (rename from Contacts)
- **Settings** → Business Profile

**Step 5: Hide Consumer Features (Day 5)**
- Hide "Send Money" tab
- Hide "Add Funds" option
- Hide "Cards" section
- Show only settlement account (not debit cards)

**Step 6: Testing & Submit (Day 6-7)**
- Test QR generation
- Test payment acceptance
- Test sales dashboard
- Test refunds
- Submit to TestFlight

---

#### 2.2 Android Merchant App (Week 6)

**Similar process as iOS merchant:**
1. Fork consumer Android app
2. Rebrand to "Titan Merchant"
3. Add QR generator activity
4. Add sales dashboard fragment
5. Add refund management
6. Update navigation
7. Hide consumer features
8. Test & submit to Google Play

---

## 🗺️ API Endpoint Mapping - Solid.fi → Titan

| Solid.fi Endpoint | Titan Service | Port | Titan Endpoint |
|-------------------|---------------|------|----------------|
| `/auth/login` | Auth0 | N/A | Keep Auth0 |
| `/person` | User Management | 8006 | `/users/profile` |
| `/person/:id/kyc` | User Management | 8006 | `/users/kyc` |
| `/business` | User Management | 8006 | `/users/business` |
| `/account` | Blnk Ledger | 5001 | `/balances` |
| `/account/:id` | Blnk Ledger | 5001 | `/balances/:id` |
| `/transaction` | Payment Router | 8002 | `/transactions` |
| `/transfer` | Payment Router | 8002 | `/payments/initiate` |
| `/ach/link` | ACH Service | 8003 | `/ach/link` |
| `/ach/transfer` | ACH Service | 8003 | `/ach/transfer` |
| `/card` | Payment Router | 8002 | `/cards` (future) |
| `/card/:id` | Payment Router | 8002 | `/cards/:id` (future) |
| N/A (new) | HRS | 8001 | `/handles/resolve` |
| N/A (new) | HRS | 8001 | `/handles` (create) |

**Key Changes:**
1. **Auth:** Keep Auth0 (no change)
2. **Accounts:** Solid `/account` → Blnk `/balances`
3. **Payments:** Solid `/transfer` → Titan `/payments/initiate` + HRS resolution
4. **Handles:** NEW - Add HRS integration for @handle support
5. **ACH:** Solid `/ach/*` → Titan `/ach/*` (similar structure)

---

## 📝 Configuration Checklist

### For Each App (4 total)

#### iOS Apps
- [ ] Update `AppMetaData.json` (app name, colors, URLs)
- [ ] Update Xcode project settings (bundle ID, display name)
- [ ] Replace app icons (`Assets.xcassets/AppIcon`)
- [ ] Update `Config.swift` (API keys, base URLs)
- [ ] Configure Auth0 client ID
- [ ] Configure Firebase project
- [ ] Configure Google Places API key (optional)
- [ ] Update Plaid client ID
- [ ] Remove VGS integration (replace with Titan encryption)
- [ ] Update terms/privacy URLs
- [ ] Configure Apple Push Notifications certificate
- [ ] Set up App Store Connect listing

#### Android Apps
- [ ] Update `native-lib.cpp` (API endpoints, keys)
- [ ] Update `strings.xml` (app name, support email)
- [ ] Refactor package names
- [ ] Replace app icons (`res/mipmap/`)
- [ ] Update `build.gradle` (application ID)
- [ ] Configure Auth0 client ID
- [ ] Configure Firebase project
- [ ] Configure Google Places API key (optional)
- [ ] Update Plaid client ID
- [ ] Remove VGS integration
- [ ] Update terms/privacy URLs
- [ ] Configure FCM for push notifications
- [ ] Set up Google Play Console listing

---

## 🎯 Success Metrics

### Consumer Apps
- User registration success rate > 90%
- Payment success rate > 95%
- @handle resolution < 10ms (P95)
- App crash rate < 1%
- App Store rating > 4.0

### Merchant Apps
- QR code generation success rate > 99%
- Payment acceptance success rate > 95%
- Average time to first sale < 5 minutes
- Refund processing < 24 hours
- Merchant satisfaction score > 4.5

---

## 🚀 Launch Timeline

```
Week 1-2: iOS Consumer
  ├─ Day 1-2: Fork, setup, rebrand
  ├─ Day 3-5: API integration
  ├─ Day 6-8: @handle support
  ├─ Day 9-10: Testing
  └─ Day 11-14: TestFlight

Week 3-4: Android Consumer (parallel with iOS Merchant)
  ├─ Day 1-2: Fork, setup, rebrand
  ├─ Day 3-5: API integration
  ├─ Day 6-8: @handle support
  ├─ Day 9-10: Testing
  └─ Day 11-14: Google Play Internal Testing

Week 5: iOS Merchant
  ├─ Day 1: Fork consumer app
  ├─ Day 2-4: Add merchant features (QR, sales dashboard, refunds)
  ├─ Day 5: Hide consumer features
  └─ Day 6-7: Test & submit

Week 6: Android Merchant
  ├─ Day 1: Fork consumer app
  ├─ Day 2-4: Add merchant features
  ├─ Day 5: Hide consumer features
  └─ Day 6-7: Test & submit
```

**Total Timeline:** 6 weeks to 4 production-ready apps

---

## 🔧 Development Environment Setup

### Prerequisites
- macOS with Xcode 14+ (for iOS)
- Android Studio Chipmunk or later (for Android)
- CocoaPods (for iOS)
- Java 11 (for Android)
- Git & GitHub CLI

### Local Backend
```bash
# Start Titan backend services
cd titan-backend-services
docker-compose up -d

# Verify all services running
docker-compose ps

# Check HRS
curl http://localhost:8001/health

# Check Auth Service
curl http://localhost:8004/health

# Check Payment Router
curl http://localhost:8002/health
```

### iOS Development
```bash
# Install CocoaPods dependencies
cd titan-consumer-ios/Solid
pod install

# Open workspace (NOT .xcodeproj)
open Solid.xcworkspace
```

### Android Development
```bash
# Open in Android Studio
studio titan-consumer-android

# Or via command line
cd titan-consumer-android
./gradlew build
```

---

## 📊 Resource Allocation

| Role | iOS Consumer | Android Consumer | iOS Merchant | Android Merchant |
|------|--------------|------------------|--------------|------------------|
| **iOS Developer** | 2 weeks | - | 1 week | - |
| **Android Developer** | - | 2 weeks | - | 1 week |
| **Backend Engineer** | API integration support | API integration support | Same | Same |
| **Designer** | App icons, branding | App icons, branding | Merchant UI | Merchant UI |
| **QA Tester** | Week 2 | Week 4 | Week 5 | Week 6 |

**Team Size:**
- 1 iOS developer
- 1 Android developer
- 0.5 Backend engineer (part-time support)
- 0.25 Designer (part-time)
- 0.5 QA tester (part-time)

**Total:** ~3.25 FTEs over 6 weeks

---

## 🎁 What You Get

After 6 weeks:

✅ **titan-consumer-ios** - Feature-complete iOS consumer wallet
✅ **titan-consumer-android** - Feature-complete Android consumer wallet
✅ **titan-merchant-ios** - iOS merchant payment acceptance app
✅ **titan-merchant-android** - Android merchant payment acceptance app

All integrated with:
- ✅ Titan backend services
- ✅ Auth0 authentication
- ✅ @handle resolution (HRS)
- ✅ Real-time payments (Trice.co via Payment Router)
- ✅ Blnk ledger
- ✅ Plaid ACH integration

**Total:** 4 production-ready mobile apps from 70,000+ LOC of proven banking code

---

## 🆘 Risk Mitigation

### Risk 1: Auth0 Configuration
**Mitigation:** Set up Auth0 tenant immediately, test with base app first

### Risk 2: API Integration Complexity
**Mitigation:** Create API mapping document, test each endpoint individually

### Risk 3: Platform-Specific Issues
**Mitigation:** Test on multiple iOS versions and Android devices early

### Risk 4: App Store Rejections
**Mitigation:** Review App Store guidelines, prepare compliance docs, use TestFlight

### Risk 5: Timeline Slippage
**Mitigation:** Consumer apps first (weeks 1-4), merchant apps can slip to week 7-8 if needed

---

## ✅ Next Actions

**Immediate (Today):**
1. Create 4 GitHub repositories:
   - piper5ul/titan-consumer-ios
   - piper5ul/titan-merchant-ios
   - piper5ul/titan-consumer-android
   - piper5ul/titan-merchant-android

2. Set up Auth0 tenant:
   - Create account at auth0.com
   - Create application for consumer apps
   - Create application for merchant apps
   - Get client IDs and domains

3. Fork ios-wallet-app → titan-consumer-ios
4. Start rebranding (AppMetaData.json, Xcode settings)

**This Week:**
- Complete iOS consumer app branding
- Start API integration
- Test @handle resolution with HRS

**Next Week:**
- Complete iOS consumer testing
- Submit to TestFlight
- Start Android consumer app

---

Ready to start? Let me know and I'll help you:
- **A)** Create the GitHub repositories
- **B)** Fork the ios-wallet-app and start rebranding
- **C)** Create the API mapping document
- **D)** Set up Auth0 configuration
