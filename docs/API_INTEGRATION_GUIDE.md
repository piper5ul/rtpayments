# API Integration Guide: Solid.fi → Titan Wallet

**Purpose:** Comprehensive endpoint mapping and integration guide for migrating mobile apps from Solid.fi API to Titan backend services

**Last Updated:** December 30, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Changes](#architecture-changes)
3. [Endpoint Mapping Reference](#endpoint-mapping-reference)
4. [Code Examples (Swift)](#code-examples-swift)
5. [Code Examples (Kotlin)](#code-examples-kotlin)
6. [Authentication Flow](#authentication-flow)
7. [Error Handling](#error-handling)
8. [Migration Checklist](#migration-checklist)

---

## Overview

### Solid.fi Architecture (Current)
```
Mobile App → https://api.solidfi.com/v1 (Monolithic API)
            → All endpoints under single domain
            → Single access token for all operations
```

### Titan Architecture (New)
```
Mobile App → API Gateway (FUTURE: to be built)
            → Multiple Microservices:
               - Handle Resolution Service (HRS) - Port 8001
               - Payment Router - Port 8002
               - ACH Service - Port 8003
               - Auth Service - Port 8004
               - User Management - Port 8006
               - Notification Service - Port 8005
            → Blnk Ledger - Port 5001 (Backend-only)
```

**Key Difference:** Solid.fi is a monolithic API; Titan uses microservices. Mobile apps will need to call different service endpoints OR wait for an API Gateway to be built.

---

## Architecture Changes

### Base URL Changes

**Solid.fi (Old):**
```swift
// EndpointItem.swift
var baseURL: String {
    switch APIManager.networkEnviroment {
    case .productionTest: return "https://test-api.solidfi.com/v1"
    case .productionLive: return "https://api.solidfi.com/v1"
    }
}
```

**Titan (New) - Option 1: Direct Microservice Calls**
```swift
enum TitanService {
    case handleResolution  // localhost:8001 (dev) or https://hrs.titanwallet.com (prod)
    case paymentRouter     // localhost:8002 (dev) or https://payments.titanwallet.com (prod)
    case achService        // localhost:8003 (dev) or https://ach.titanwallet.com (prod)
    case authService       // localhost:8004 (dev) or https://auth.titanwallet.com (prod)
    case userManagement    // localhost:8006 (dev) or https://users.titanwallet.com (prod)

    var baseURL: String {
        switch APIManager.networkEnviroment {
        case .productionTest:
            switch self {
            case .handleResolution: return "https://test-hrs.titanwallet.com"
            case .paymentRouter: return "https://test-payments.titanwallet.com"
            case .achService: return "https://test-ach.titanwallet.com"
            case .authService: return "https://test-auth.titanwallet.com"
            case .userManagement: return "https://test-users.titanwallet.com"
            }
        case .productionLive:
            switch self {
            case .handleResolution: return "https://hrs.titanwallet.com"
            case .paymentRouter: return "https://payments.titanwallet.com"
            case .achService: return "https://ach.titanwallet.com"
            case .authService: return "https://auth.titanwallet.com"
            case .userManagement: return "https://users.titanwallet.com"
            }
        }
    }
}
```

**Titan (New) - Option 2: API Gateway (RECOMMENDED for future)**
```swift
// Wait for API Gateway to be built, then use single domain:
var baseURL: String {
    switch APIManager.networkEnviroment {
    case .productionTest: return "https://test-api.titanwallet.com/v1"
    case .productionLive: return "https://api.titanwallet.com/v1"
    }
}
```

### Migration Strategy Recommendation

**Phase 1 (Immediate):**
- Use direct microservice calls during development
- Update EndpointItem.swift to route to correct service
- Local development: localhost:8001, localhost:8002, etc.

**Phase 2 (Production):**
- Build API Gateway (Nginx/Kong/AWS API Gateway)
- Consolidate all services behind single domain
- Update mobile apps to use gateway URL
- Gateway handles routing to microservices

---

## Endpoint Mapping Reference

### Complete Mapping Table

| Solid.fi Endpoint | HTTP | Titan Service | Titan Endpoint | Port | Notes |
|------------------|------|---------------|----------------|------|-------|
| **AUTHENTICATION** |
| `/auth/register` | POST | Auth Service | `/auth/register` | 8004 | Auth0 handles SMS OTP, service creates user session |
| `/auth/logout` | POST | Auth Service | `/auth/logout` | 8004 | Invalidates JWT token in Redis |
| **USERS (PERSON/KYC)** |
| `/person` | GET | User Management | `/users/{id}` | 8006 | Changed from person to user |
| `/person` | POST | User Management | `/users` | 8006 | Create user profile |
| `/person/{id}` | PATCH | User Management | `/users/{id}` | 8006 | Update user info |
| `/person/{id}/idv` | POST | User Management | `/users/{id}/kyc` | 8006 | Renamed from idv to kyc |
| `/person/{id}/kyc` | POST | User Management | `/users/{id}/kyc` | 8006 | Submit KYC documents |
| `/person/{id}/kyc` | GET | User Management | `/users/{id}/kyc` | 8006 | Get KYC status |
| **BUSINESS (KYB)** |
| `/business` | GET | User Management | `/businesses` | 8006 | List all businesses |
| `/business` | POST | User Management | `/businesses` | 8006 | Create business entity |
| `/business/{id}` | GET | User Management | `/businesses/{id}` | 8006 | Get business details |
| `/business/{id}` | PATCH | User Management | `/businesses/{id}` | 8006 | Update business |
| `/business/{id}/kyb` | POST | User Management | `/businesses/{id}/kyb` | 8006 | Submit KYB |
| `/business/{id}/kyb` | GET | User Management | `/businesses/{id}/kyb` | 8006 | Get KYB status |
| `/business/{id}/projection` | GET | User Management | `/businesses/{id}/financials` | 8006 | Renamed from projection |
| `/business/{id}/projection` | PATCH | User Management | `/businesses/{id}/financials` | 8006 | Update financials |
| `/business/{id}/ownershipDisclosure` | GET | User Management | `/businesses/{id}/ownership` | 8006 | Shortened endpoint |
| `/business/{id}/ownershipDisclosure` | POST | User Management | `/businesses/{id}/ownership` | 8006 | Generate ownership docs |
| `/business/naicscode` | GET | User Management | `/naics-codes` | 8006 | Top-level endpoint |
| **OWNERS** |
| `/owner` | POST | User Management | `/businesses/{businessId}/owners` | 8006 | Nested under business |
| `/owner?businessId={id}` | GET | User Management | `/businesses/{id}/owners` | 8006 | Nested endpoint |
| `/owner/{id}` | GET | User Management | `/owners/{id}` | 8006 | Get owner details |
| `/owner/{id}` | PATCH | User Management | `/owners/{id}` | 8006 | Update owner |
| `/owner/{id}/kyc` | POST | User Management | `/owners/{id}/kyc` | 8006 | Submit owner KYC |
| `/owner/{id}/kyc` | GET | User Management | `/owners/{id}/kyc` | 8006 | Get owner KYC status |
| **ACCOUNTS** |
| `/account` | POST | Blnk Ledger | `/balances` | 5001 | Backend creates Blnk balance |
| `/account?businessId={id}` | GET | Blnk Ledger | `/balances?metadata.businessId={id}` | 5001 | Query by metadata |
| `/account/{id}` | GET | Blnk Ledger | `/balances/{id}` | 5001 | Get account/balance |
| `/account/{id}/statement` | GET | Blnk Ledger | `/balances/{id}/transactions` | 5001 | Transactions = statement |
| `/account/{id}/statement/{id}?export=pdf` | GET | Backend Service | `/statements/{id}/pdf` | TBD | New service needed |
| **CONTACTS** |
| `/contact` | POST | User Management | `/contacts` | 8006 | Create contact |
| `/contact` | GET | User Management | `/contacts?accountId={id}` | 8006 | List contacts |
| `/contact/{id}` | GET | User Management | `/contacts/{id}` | 8006 | Get contact |
| `/contact/{id}` | PATCH | User Management | `/contacts/{id}` | 8006 | Update contact |
| `/contact/{id}` | DELETE | User Management | `/contacts/{id}` | 8006 | Delete contact |
| `/contact/{id}/debitcard/token` | POST | ACH Service | `/ach/link-token` | 8003 | Changed to Plaid link token |
| **PAYMENTS (SEND MONEY)** |
| `/send/ach` | POST | Payment Router | `/payments` | 8002 | Unified payment endpoint |
| `/send/check` | POST | Payment Router | `/payments` | 8002 | Use paymentType: "check" |
| `/send/domestic_wire` | POST | Payment Router | `/payments` | 8002 | Use paymentType: "wire" |
| `/send/intrabank` | POST | Payment Router | `/payments` | 8002 | Use paymentType: "internal" |
| **PAYMENTS (RECEIVE MONEY)** |
| `/receive/ach` | POST | ACH Service | `/ach/pull` | 8003 | Plaid ACH pull |
| `/receive/debitpull` | POST | ACH Service | `/ach/pull` | 8003 | Same as ACH pull |
| `/receive/check` | POST | Backend Service | `/receive/check` | TBD | Remote check deposit (future) |
| `/receive/check/{id}/files` | POST | Backend Service | `/receive/check/{id}/files` | TBD | Upload check images |
| **HANDLE RESOLUTION (NEW)** |
| N/A | GET | HRS | `/handles/resolve?handle={handle}` | 8001 | Resolves @alice to user/account |
| N/A | POST | HRS | `/handles` | 8001 | Create new @handle |
| N/A | PATCH | HRS | `/handles/{handle}` | 8001 | Update @handle mapping |
| N/A | DELETE | HRS | `/handles/{handle}` | 8001 | Delete @handle |
| **CARDS** |
| `/card` | POST | Backend Service | `/cards` | TBD | Card issuance (future) |
| `/card` | GET | Backend Service | `/cards?accountId={id}` | TBD | List cards |
| `/card/{id}` | GET | Backend Service | `/cards/{id}` | TBD | Get card details |
| `/card/{id}` | PATCH | Backend Service | `/cards/{id}` | TBD | Update card |
| `/card/{id}` | DELETE | Backend Service | `/cards/{id}` | TBD | Cancel card |
| `/card/{id}/unredact` | GET | Backend Service | `/cards/{id}/unredact` | TBD | VGS secure PAN reveal |
| `/card/{id}/activate` | PATCH | Backend Service | `/cards/{id}/activate` | TBD | Activate card |
| `/card/{id}/show-token` | POST | Backend Service | `/cards/{id}/show-token` | TBD | VGS show token |
| `/card/{id}/pintoken` | POST | Backend Service | `/cards/{id}/pin-token` | TBD | Get PIN change token |
| `/card/{id}/provision` | POST | Backend Service | `/cards/{id}/wallet-provision` | TBD | Apple/Google Pay provisioning |
| `/card/atm` | GET | Backend Service | `/cards/atm-locations` | TBD | ATM locator |
| **TRANSACTIONS** |
| `/account/{id}/transaction` | GET | Blnk Ledger | `/balances/{id}/transactions` | 5001 | List transactions |
| `/account/{id}/transaction/{txId}` | GET | Blnk Ledger | `/transactions/{txId}` | 5001 | Get transaction detail |
| `/account/{id}/transaction/{txId}?export=pdf` | GET | Backend Service | `/transactions/{txId}/pdf` | TBD | PDF export |
| **PLAID (ACH)** |
| `/account/{id}/plaid-token` | POST | ACH Service | `/ach/link-token` | 8003 | Create Plaid Link token |
| `/account/{id}/plaid-account` | POST | ACH Service | `/ach/exchange-token` | 8003 | Exchange public token |
| **PROGRAM** |
| `/program/{id}` | GET | User Management | `/programs/{id}` | 8006 | BIN sponsor programs |

---

## Code Examples (Swift)

### Example 1: Resolve @handle (NEW Titan Feature)

**Use Case:** User enters `@alice` in "Send Money" screen, app resolves to actual user/account

```swift
// NEW: HandleResolutionService.swift
import Alamofire

class HandleResolutionService {
    let baseURL = "http://localhost:8001" // Dev environment

    func resolveHandle(_ handle: String, completion: @escaping (Result<ResolvedHandle, Error>) -> Void) {
        let endpoint = "\(baseURL)/handles/resolve"
        let parameters: [String: String] = ["handle": handle]

        AF.request(endpoint,
                   method: .get,
                   parameters: parameters,
                   headers: getHeaders())
            .validate()
            .responseDecodable(of: ResolvedHandleResponse.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data.handle))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    private func getHeaders() -> HTTPHeaders {
        let token = AppData.session.accessToken ?? ""
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json"
        ]
    }
}

// Models
struct ResolvedHandleResponse: Codable {
    let handle: ResolvedHandle
    let resolvedIn: String // "2.3ms" for sub-10ms SLA
}

struct ResolvedHandle: Codable {
    let handle: String        // "@alice"
    let userId: String        // UUID
    let accountId: String     // Blnk balance ID
    let displayName: String?  // "Alice Johnson"
    let isActive: Bool
}

// Usage in SendMoneyViewController.swift
class SendMoneyViewController: UIViewController {
    @IBOutlet weak var handleTextField: UITextField!
    let handleService = HandleResolutionService()

    @IBAction func onLookupHandle(_ sender: Any) {
        guard let handle = handleTextField.text, !handle.isEmpty else { return }

        showLoadingIndicator()

        handleService.resolveHandle(handle) { [weak self] result in
            self?.hideLoadingIndicator()

            switch result {
            case .success(let resolvedHandle):
                // Show user info, proceed to amount entry
                self?.showResolvedUser(resolvedHandle)

            case .failure(let error):
                // Show error: "Handle not found" or network error
                self?.showError("Could not find \(handle)")
            }
        }
    }

    func showResolvedUser(_ handle: ResolvedHandle) {
        // Update UI with resolved user info
        recipientNameLabel.text = handle.displayName ?? handle.handle
        recipientAccountId = handle.accountId
        // Enable "Next" button
    }
}
```

### Example 2: Send Payment via @handle

**Old Solid.fi Way:**
```swift
// OLD: PaymentViewController.swift (Solid.fi)
func sendPayment() {
    let endpoint = EndpointItem.paymentMethod("ach")
    let params: [String: Any] = [
        "fromAccountId": sourceAccountId,
        "toContactId": contactId,  // Required contact lookup first
        "amount": amount,
        "currency": "USD"
    ]

    APIManager.makeRequest(endpoint: endpoint, params: params) { result in
        // Handle response
    }
}
```

**New Titan Way (using @handle):**
```swift
// NEW: PaymentViewController.swift (Titan)
func sendPaymentToHandle() {
    let endpoint = "http://localhost:8002/payments"  // Payment Router
    let params: [String: Any] = [
        "fromHandle": "@bob",      // Current user's handle
        "toHandle": "@alice",      // Recipient's handle (no contact needed!)
        "amount": "25.50",
        "currency": "USD",
        "paymentType": "rtp",      // Real-Time Payment
        "reference": "Lunch split"
    ]

    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(AppData.session.accessToken ?? "")",
        "Content-Type": "application/json"
    ]

    AF.request(endpoint,
               method: .post,
               parameters: params,
               encoding: JSONEncoding.default,
               headers: headers)
        .validate()
        .responseDecodable(of: PaymentResponse.self) { response in
            switch response.result {
            case .success(let payment):
                // Payment created instantly!
                self.showSuccess("Sent \(payment.amount) to \(payment.toHandle)")

            case .failure(let error):
                self.showError("Payment failed: \(error.localizedDescription)")
            }
        }
}

struct PaymentResponse: Codable {
    let id: String           // Payment UUID
    let fromHandle: String   // "@bob"
    let toHandle: String     // "@alice"
    let amount: String       // "25.50"
    let currency: String     // "USD"
    let paymentType: String  // "rtp"
    let status: String       // "completed" or "pending"
    let reference: String
    let createdAt: String    // ISO timestamp
}
```

### Example 3: Create User with KYC (Migrated Endpoint)

**Old Solid.fi Way:**
```swift
// OLD: KYCViewModel.swift (Solid.fi)
func submitKYC(personId: String) {
    let endpoint = EndpointItem.submitKYC(personId)
    let params: [String: Any] = [
        "ssn": ssnEncrypted,
        "firstName": firstName,
        "lastName": lastName,
        "dob": dateOfBirth
    ]

    APIManager.makeRequest(endpoint: endpoint, params: params) { result in
        // ...
    }
}
```

**New Titan Way:**
```swift
// NEW: KYCViewModel.swift (Titan - User Management Service)
func submitKYC(userId: String) {
    let endpoint = "http://localhost:8006/users/\(userId)/kyc"  // User Management
    let params: [String: Any] = [
        "ssn": ssnEncrypted,        // Still encrypted with AES-256-GCM
        "firstName": firstName,
        "lastName": lastName,
        "dateOfBirth": dateOfBirth,
        "address": [
            "line1": address.line1,
            "city": address.city,
            "state": address.state,
            "postalCode": address.zip
        ]
    ]

    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(AppData.session.accessToken ?? "")",
        "Content-Type": "application/json"
    ]

    AF.request(endpoint,
               method: .post,
               parameters: params,
               encoding: JSONEncoding.default,
               headers: headers)
        .validate()
        .responseDecodable(of: KYCResponse.self) { response in
            switch response.result {
            case .success(let kycData):
                // KYC submitted, check status
                self.checkKYCStatus(userId: userId)

            case .failure(let error):
                self.delegate?.kycSubmissionFailed(error)
            }
        }
}

struct KYCResponse: Codable {
    let id: String
    let userId: String
    let status: String  // "pending", "approved", "rejected"
    let submittedAt: String
}
```

### Example 4: ACH Pull Funds (Plaid Integration)

**Old Solid.fi Way:**
```swift
// OLD: FundViewController.swift (Solid.fi)
func initiatePlaid(accountId: String) {
    let endpoint = EndpointItem.getPlaidTempToken(accountId)

    APIManager.makeRequest(endpoint: endpoint) { result in
        guard let linkToken = result["linkToken"] as? String else { return }
        self.launchPlaid(linkToken: linkToken)
    }
}

func pullFunds(amount: Double) {
    let endpoint = EndpointItem.pullFundsIn
    let params: [String: Any] = [
        "accountId": titanAccountId,
        "plaidAccountId": externalBankAccountId,
        "amount": amount,
        "currency": "USD"
    ]

    APIManager.makeRequest(endpoint: endpoint, params: params) { result in
        // Handle ACH pull
    }
}
```

**New Titan Way:**
```swift
// NEW: FundViewController.swift (Titan - ACH Service)
func initiatePlaid(userId: String) {
    let endpoint = "http://localhost:8003/ach/link-token"  // ACH Service
    let params: [String: Any] = ["user_id": userId]

    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(AppData.session.accessToken ?? "")",
        "Content-Type": "application/json"
    ]

    AF.request(endpoint,
               method: .post,
               parameters: params,
               encoding: JSONEncoding.default,
               headers: headers)
        .validate()
        .responseDecodable(of: LinkTokenResponse.self) { response in
            switch response.result {
            case .success(let data):
                self.launchPlaid(linkToken: data.linkToken)

            case .failure(let error):
                self.showError("Failed to initialize Plaid")
            }
        }
}

func pullFunds(userId: String, accountId: String, amount: Double) {
    let endpoint = "http://localhost:8003/ach/pull"  // ACH Service
    let params: [String: Any] = [
        "user_id": userId,
        "account_id": accountId,      // Plaid account ID
        "amount": amount,
        "currency": "USD",
        "description": "Add funds to Titan Wallet"
    ]

    let headers: HTTPHeaders = [
        "Authorization": "Bearer \(AppData.session.accessToken ?? "")",
        "Content-Type": "application/json"
    ]

    AF.request(endpoint,
               method: .post,
               parameters: params,
               encoding: JSONEncoding.default,
               headers: headers)
        .validate()
        .responseDecodable(of: ACHTransactionResponse.self) { response in
            switch response.result {
            case .success(let transaction):
                // ACH pull initiated
                self.showSuccess("Funds transfer initiated: \(transaction.status)")

            case .failure(let error):
                self.showError("ACH pull failed")
            }
        }
}

struct LinkTokenResponse: Codable {
    let linkToken: String
    let expiration: String
}

struct ACHTransactionResponse: Codable {
    let transactionId: String
    let status: String      // "pending", "completed", "failed"
    let amount: Double
    let currency: String
    let direction: String   // "pull" or "push"
    let message: String?
}
```

### Example 5: Updating EndpointItem.swift for Microservices

```swift
// UPDATED: EndpointItem.swift (Titan - Microservices)

enum TitanEndpointItem {
    // HANDLE RESOLUTION
    case resolveHandle(String)
    case createHandle

    // PAYMENTS
    case createPayment
    case getPayment(String)

    // USER MANAGEMENT
    case createUser
    case getUser(String)
    case updateUser(String)
    case submitKYC(String)
    case getKYC(String)

    // ACH SERVICE
    case createLinkToken
    case exchangePublicToken
    case achPull
    case achPush
}

extension TitanEndpointItem: EndPointType {
    var baseURL: String {
        switch self {
        case .resolveHandle, .createHandle:
            return "http://localhost:8001"  // HRS

        case .createPayment, .getPayment:
            return "http://localhost:8002"  // Payment Router

        case .createUser, .getUser, .updateUser, .submitKYC, .getKYC:
            return "http://localhost:8006"  // User Management

        case .createLinkToken, .exchangePublicToken, .achPull, .achPush:
            return "http://localhost:8003"  // ACH Service
        }
    }

    var path: String {
        switch self {
        // HRS
        case .resolveHandle(let handle):
            return "/handles/resolve?handle=\(handle)"
        case .createHandle:
            return "/handles"

        // Payments
        case .createPayment:
            return "/payments"
        case .getPayment(let id):
            return "/payments/\(id)"

        // User Management
        case .createUser:
            return "/users"
        case .getUser(let id):
            return "/users/\(id)"
        case .updateUser(let id):
            return "/users/\(id)"
        case .submitKYC(let userId):
            return "/users/\(userId)/kyc"
        case .getKYC(let userId):
            return "/users/\(userId)/kyc"

        // ACH
        case .createLinkToken:
            return "/ach/link-token"
        case .exchangePublicToken:
            return "/ach/exchange-token"
        case .achPull:
            return "/ach/pull"
        case .achPush:
            return "/ach/push"
        }
    }

    var httpMethod: HTTPMethod {
        switch self {
        case .createHandle, .createPayment, .createUser, .submitKYC,
             .createLinkToken, .exchangePublicToken, .achPull, .achPush:
            return .post

        case .updateUser:
            return .put

        default:
            return .get
        }
    }

    var headers: HTTPHeaders? {
        let token = AppData.session.accessToken ?? ""
        return [
            "Authorization": "Bearer \(token)",
            "Content-Type": "application/json",
            "Cache-Control": "no-cache, no-store"
        ]
    }

    var url: URL {
        return URL(string: self.baseURL + self.path)!
    }

    var encoding: ParameterEncoding {
        return JSONEncoding.default
    }
}
```

---

## Code Examples (Kotlin)

### Example 1: Resolve @handle (Kotlin - Android)

```kotlin
// NEW: HandleResolutionService.kt
package com.titanwallet.services

import com.titanwallet.models.ResolvedHandle
import retrofit2.Response
import retrofit2.http.GET
import retrofit2.http.Query
import retrofit2.http.Header

interface HandleResolutionAPI {
    @GET("handles/resolve")
    suspend fun resolveHandle(
        @Query("handle") handle: String,
        @Header("Authorization") token: String
    ): Response<ResolvedHandleResponse>
}

data class ResolvedHandleResponse(
    val handle: ResolvedHandle,
    val resolvedIn: String  // "2.3ms"
)

data class ResolvedHandle(
    val handle: String,        // "@alice"
    val userId: String,        // UUID
    val accountId: String,     // Blnk balance ID
    val displayName: String?,  // "Alice Johnson"
    val isActive: Boolean
)

// Repository
class HandleRepository(private val api: HandleResolutionAPI) {
    suspend fun resolveHandle(handle: String): Result<ResolvedHandle> {
        return try {
            val token = "Bearer ${SessionManager.getAccessToken()}"
            val response = api.resolveHandle(handle, token)

            if (response.isSuccessful) {
                response.body()?.let {
                    Result.success(it.handle)
                } ?: Result.failure(Exception("Empty response"))
            } else {
                Result.failure(Exception("Handle not found"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

// Usage in SendMoneyViewModel.kt
class SendMoneyViewModel(
    private val handleRepo: HandleRepository
) : ViewModel() {

    private val _resolvedHandle = MutableLiveData<ResolvedHandle?>()
    val resolvedHandle: LiveData<ResolvedHandle?> = _resolvedHandle

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    fun lookupHandle(handle: String) {
        viewModelScope.launch {
            val result = handleRepo.resolveHandle(handle)

            result.fold(
                onSuccess = { resolvedHandle ->
                    _resolvedHandle.value = resolvedHandle
                },
                onFailure = { error ->
                    _error.value = "Could not find $handle"
                }
            )
        }
    }
}

// SendMoneyActivity.kt
class SendMoneyActivity : AppCompatActivity() {
    private lateinit var binding: ActivitySendMoneyBinding
    private val viewModel: SendMoneyViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivitySendMoneyBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.lookupButton.setOnClickListener {
            val handle = binding.handleEditText.text.toString()
            if (handle.isNotEmpty()) {
                viewModel.lookupHandle(handle)
            }
        }

        viewModel.resolvedHandle.observe(this) { handle ->
            handle?.let {
                // Show resolved user
                binding.recipientNameText.text = it.displayName ?: it.handle
                binding.nextButton.isEnabled = true
            }
        }

        viewModel.error.observe(this) { error ->
            error?.let {
                Toast.makeText(this, it, Toast.LENGTH_SHORT).show()
            }
        }
    }
}
```

### Example 2: Send Payment (Kotlin)

```kotlin
// PaymentService.kt
package com.titanwallet.services

import retrofit2.Response
import retrofit2.http.POST
import retrofit2.http.Body
import retrofit2.http.Header

interface PaymentAPI {
    @POST("payments")
    suspend fun createPayment(
        @Body request: CreatePaymentRequest,
        @Header("Authorization") token: String
    ): Response<PaymentResponse>
}

data class CreatePaymentRequest(
    val fromHandle: String,     // "@bob"
    val toHandle: String,       // "@alice"
    val amount: String,         // "25.50"
    val currency: String,       // "USD"
    val paymentType: String,    // "rtp"
    val reference: String       // "Lunch split"
)

data class PaymentResponse(
    val id: String,
    val fromHandle: String,
    val toHandle: String,
    val amount: String,
    val currency: String,
    val paymentType: String,
    val status: String,         // "completed" or "pending"
    val reference: String,
    val createdAt: String
)

// Repository
class PaymentRepository(private val api: PaymentAPI) {
    suspend fun sendPayment(
        fromHandle: String,
        toHandle: String,
        amount: String,
        reference: String
    ): Result<PaymentResponse> {
        return try {
            val token = "Bearer ${SessionManager.getAccessToken()}"
            val request = CreatePaymentRequest(
                fromHandle = fromHandle,
                toHandle = toHandle,
                amount = amount,
                currency = "USD",
                paymentType = "rtp",
                reference = reference
            )

            val response = api.createPayment(request, token)

            if (response.isSuccessful) {
                response.body()?.let {
                    Result.success(it)
                } ?: Result.failure(Exception("Empty response"))
            } else {
                Result.failure(Exception("Payment failed"))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}

// ViewModel
class PaymentViewModel(
    private val paymentRepo: PaymentRepository
) : ViewModel() {

    private val _paymentResult = MutableLiveData<PaymentResponse?>()
    val paymentResult: LiveData<PaymentResponse?> = _paymentResult

    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error

    fun sendPayment(toHandle: String, amount: String, note: String) {
        viewModelScope.launch {
            val myHandle = UserPreferences.getMyHandle() // "@bob"

            val result = paymentRepo.sendPayment(
                fromHandle = myHandle,
                toHandle = toHandle,
                amount = amount,
                reference = note
            )

            result.fold(
                onSuccess = { payment ->
                    _paymentResult.value = payment
                },
                onFailure = { error ->
                    _error.value = error.message
                }
            )
        }
    }
}
```

### Example 3: Retrofit Configuration for Microservices

```kotlin
// NetworkModule.kt
package com.titanwallet.network

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object NetworkModule {

    // Base URLs for each microservice
    private const val HRS_BASE_URL = "http://10.0.2.2:8001/"          // Android emulator localhost
    private const val PAYMENT_BASE_URL = "http://10.0.2.2:8002/"
    private const val ACH_BASE_URL = "http://10.0.2.2:8003/"
    private const val AUTH_BASE_URL = "http://10.0.2.2:8004/"
    private const val USER_MGMT_BASE_URL = "http://10.0.2.2:8006/"

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    // Handle Resolution Service API
    val handleResolutionAPI: HandleResolutionAPI by lazy {
        Retrofit.Builder()
            .baseUrl(HRS_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(HandleResolutionAPI::class.java)
    }

    // Payment Router API
    val paymentAPI: PaymentAPI by lazy {
        Retrofit.Builder()
            .baseUrl(PAYMENT_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(PaymentAPI::class.java)
    }

    // ACH Service API
    val achAPI: ACHAPI by lazy {
        Retrofit.Builder()
            .baseUrl(ACH_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(ACHAPI::class.java)
    }

    // User Management API
    val userAPI: UserAPI by lazy {
        Retrofit.Builder()
            .baseUrl(USER_MGMT_BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(UserAPI::class.java)
    }
}
```

---

## Authentication Flow

### Solid.fi Auth (Old)

```
1. User enters phone number
2. App → Solid.fi: POST /auth/register { phone: "+15551234567" }
3. Solid.fi sends SMS OTP via internal SMS service
4. User enters OTP code
5. App → Solid.fi: POST /auth/verify { phone: "+15551234567", code: "123456" }
6. Solid.fi returns access token (JWT)
7. App stores token in Keychain/SharedPreferences
```

### Titan Auth (New with Auth0)

```
1. User enters phone number
2. App → Auth0 SDK: auth0.passwordlessWithSMS(phoneNumber)
3. Auth0 sends SMS OTP (configured in Auth0 dashboard)
4. User enters OTP code
5. Auth0 SDK validates OTP and returns Auth0 access token
6. App → Titan Auth Service: POST /auth/register {
     phoneNumber: "+15551234567",
     auth0Token: "eyJ..."
   }
7. Auth Service:
   - Validates Auth0 token
   - Creates user in User Management service
   - Generates Titan JWT token
   - Stores session in Redis
8. Auth Service returns Titan access token
9. App stores Titan token in Keychain/SharedPreferences
10. All subsequent API calls use Titan token in Authorization header
```

### Swift Implementation (Auth0 + Titan)

```swift
// Auth0Manager.swift
import Auth0

class Auth0Manager {
    static let shared = Auth0Manager()
    private let auth0 = Auth0.authentication()

    func loginWithSMS(phoneNumber: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Step 1: Request SMS OTP from Auth0
        auth0
            .startPasswordless(phoneNumber: phoneNumber, type: .Code)
            .start { result in
                switch result {
                case .success:
                    // SMS sent, now wait for user to enter code
                    completion(.success("OTP sent"))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    func verifyOTP(phoneNumber: String, code: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Step 2: Verify OTP and get Auth0 token
        auth0
            .login(phoneNumber: phoneNumber, code: code, audience: "https://api.titanwallet.com")
            .start { result in
                switch result {
                case .success(let credentials):
                    // Got Auth0 token, now register with Titan backend
                    self.registerWithTitan(auth0Token: credentials.accessToken, completion: completion)

                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }

    private func registerWithTitan(auth0Token: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Step 3: Register with Titan Auth Service
        let endpoint = "http://localhost:8004/auth/register"
        let params: [String: Any] = [
            "auth0Token": auth0Token
        ]

        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]

        AF.request(endpoint,
                   method: .post,
                   parameters: params,
                   encoding: JSONEncoding.default,
                   headers: headers)
            .validate()
            .responseDecodable(of: TitanAuthResponse.self) { response in
                switch response.result {
                case .success(let authData):
                    // Store Titan access token
                    AppData.session.accessToken = authData.accessToken
                    AppData.session.userId = authData.userId
                    completion(.success(authData.accessToken))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

struct TitanAuthResponse: Codable {
    let accessToken: String   // Titan JWT token
    let refreshToken: String
    let userId: String
    let expiresIn: Int        // Seconds until expiration
}

// Usage in LoginViewController.swift
class LoginViewController: UIViewController {
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var otpTextField: UITextField!

    @IBAction func onSendOTP(_ sender: Any) {
        guard let phone = phoneTextField.text, !phone.isEmpty else { return }

        showLoadingIndicator()

        Auth0Manager.shared.loginWithSMS(phoneNumber: phone) { [weak self] result in
            self?.hideLoadingIndicator()

            switch result {
            case .success:
                self?.showOTPField()
                self?.showMessage("OTP sent to \(phone)")

            case .failure(let error):
                self?.showError("Failed to send OTP: \(error.localizedDescription)")
            }
        }
    }

    @IBAction func onVerifyOTP(_ sender: Any) {
        guard let phone = phoneTextField.text,
              let code = otpTextField.text, !code.isEmpty else { return }

        showLoadingIndicator()

        Auth0Manager.shared.verifyOTP(phoneNumber: phone, code: code) { [weak self] result in
            self?.hideLoadingIndicator()

            switch result {
            case .success(let token):
                // Login successful, navigate to home
                self?.navigateToHome()

            case .failure(let error):
                self?.showError("Invalid OTP")
            }
        }
    }
}
```

---

## Error Handling

### Solid.fi Error Format (Old)

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Amount is required",
    "details": {}
  }
}
```

### Titan Error Format (New)

```json
{
  "error": {
    "code": "BAD_REQUEST",
    "message": "invalid request body",
    "statusCode": 400,
    "timestamp": "2025-12-30T23:25:20Z",
    "path": "/payments"
  }
}
```

### Swift Error Handling

```swift
// TitanError.swift
struct TitanError: Codable, Error {
    let code: String
    let message: String
    let statusCode: Int
    let timestamp: String
    let path: String

    var localizedDescription: String {
        return message
    }
}

// APIManager.swift extension
extension APIManager {
    static func handleTitanError(_ data: Data?) -> String {
        guard let data = data else {
            return "Unknown error occurred"
        }

        do {
            let decoder = JSONDecoder()
            let errorResponse = try decoder.decode(TitanErrorResponse.self, from: data)
            return errorResponse.error.message
        } catch {
            return "Failed to parse error response"
        }
    }
}

struct TitanErrorResponse: Codable {
    let error: TitanError
}

// Usage
AF.request(endpoint, method: .post, parameters: params)
    .validate()
    .response { response in
        switch response.result {
        case .success:
            // Handle success
            break

        case .failure:
            let errorMessage = APIManager.handleTitanError(response.data)
            self.showError(errorMessage)
        }
    }
```

---

## Migration Checklist

### Phase 1: Update Base URLs and Endpoints

- [ ] Update `EndpointItem.swift` or create `TitanEndpointItem.swift`
- [ ] Add microservice base URLs (HRS, Payment Router, ACH, User Management)
- [ ] Update all endpoint paths to match Titan API
- [ ] Test connectivity to all services (localhost or test environment)

### Phase 2: Update Authentication

- [ ] Integrate Auth0 SDK for iOS/Android
- [ ] Configure Auth0 Client ID and Domain in AppMetaData.json
- [ ] Update login flow to use Auth0 passwordless SMS
- [ ] Call Titan Auth Service after Auth0 verification
- [ ] Store Titan JWT token in Keychain/SharedPreferences
- [ ] Update all API calls to use Titan token

### Phase 3: Implement @handle Features (NEW)

- [ ] Create Handle Resolution Service integration
- [ ] Update "Send Money" flow to support @handle lookup
- [ ] Add @handle display in transaction history
- [ ] Allow users to create their @handle during onboarding
- [ ] Add @handle to user profile screen
- [ ] Implement @handle QR code generation (optional)

### Phase 4: Update Payment Flows

- [ ] Migrate `/send/ach` → Payment Router `/payments` (type: "ach")
- [ ] Migrate `/send/intrabank` → Payment Router `/payments` (type: "internal")
- [ ] Migrate `/send/domestic_wire` → Payment Router `/payments` (type: "wire")
- [ ] Update payment request models to include `fromHandle` and `toHandle`
- [ ] Test payment creation and status tracking

### Phase 5: Update ACH/Plaid Integration

- [ ] Migrate Plaid link token creation to ACH Service
- [ ] Update public token exchange endpoint
- [ ] Update ACH pull funds flow
- [ ] Update ACH push funds flow (send money out)
- [ ] Test Plaid Link UI integration

### Phase 6: Update User/KYC/KYB Flows

- [ ] Migrate `/person` endpoints → `/users` (User Management)
- [ ] Update KYC submission endpoint
- [ ] Update KYB (business) endpoints
- [ ] Update owner/beneficial owner endpoints
- [ ] Test KYC verification flow

### Phase 7: Update Transaction History

- [ ] Migrate transaction list endpoint to Blnk Ledger API
- [ ] Update transaction detail endpoint
- [ ] Parse and display @handle in transaction UI
- [ ] Test pagination and filtering

### Phase 8: Error Handling and Monitoring

- [ ] Update error parsing to match Titan error format
- [ ] Add logging for all API calls
- [ ] Implement retry logic for failed requests
- [ ] Add analytics tracking (Segment)
- [ ] Test error scenarios (network failures, invalid tokens, etc.)

### Phase 9: Testing

- [ ] Unit tests for all updated API calls
- [ ] Integration tests with backend services
- [ ] End-to-end tests for critical flows (login, send money, pull funds)
- [ ] Test on iOS simulator and physical device
- [ ] Test on Android emulator and physical device
- [ ] Performance testing for @handle resolution (verify sub-10ms SLA)

### Phase 10: Production Deployment

- [ ] Replace localhost URLs with production Titan service URLs
- [ ] Configure production Auth0 credentials
- [ ] Update AppMetaData.json for production environment
- [ ] Submit iOS app to App Store
- [ ] Submit Android app to Google Play Store
- [ ] Monitor app for errors and crashes (Firebase Crashlytics)

---

## Summary

### Key Changes from Solid.fi → Titan

1. **Monolithic → Microservices**: Apps now call multiple service endpoints instead of one
2. **New Feature: @handle**: Users can send/receive money using human-readable handles (@alice)
3. **Auth0 Integration**: Passwordless SMS OTP now handled by Auth0 instead of Solid.fi
4. **Endpoint Changes**: Many endpoints renamed (e.g., `/person` → `/users`, `/account` → `/balances`)
5. **Payment Simplification**: All payment types go through single `/payments` endpoint with `paymentType` parameter
6. **Blnk Ledger**: Accounts and transactions now managed by Blnk instead of Solid.fi proprietary system

### Migration Effort Estimate

- **iOS App**: 40-60 hours (2-3 days for 1 developer with existing code)
- **Android App**: 40-60 hours (2-3 days for 1 developer)
- **Testing**: 20 hours per platform
- **Total**: ~1 week per platform with thorough testing

### Next Steps

1. Start with iOS consumer app (already forked to titan-consumer-ios)
2. Update EndpointItem.swift for microservices
3. Integrate Auth0 SDK
4. Test @handle resolution and payments
5. Repeat for Android consumer app
6. Fork and update merchant apps (both iOS and Android)

---

**Questions?** Contact Pushkar or refer to:
- Titan Backend Services README: `/titan-backend-services/README.md`
- Auth0 Setup Guide: `/docs/AUTH0_SETUP_GUIDE.md`
- Mobile Fork Strategy: `/docs/MOBILE_APP_FORK_STRATEGY.md`
