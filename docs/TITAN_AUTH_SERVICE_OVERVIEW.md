# Titan Auth Service - Complete Overview

**Service:** Auth Service
**Port:** 8004
**Purpose:** JWT-based authentication with Redis session management
**Tech Stack:** Go + PostgreSQL + Redis + JWT

---

## What is the Titan Auth Service?

The Titan Auth Service is a **lightweight, production-ready authentication microservice** that provides JWT (JSON Web Token) based authentication for all Titan Wallet applications (consumer apps, merchant apps, admin dashboard).

Think of it as the **"login server"** for your entire platform.

---

## Why Replace Auth0?

The ios-wallet-app currently uses **Auth0** (a third-party authentication service) for passwordless login via SMS OTP. Here's why we'd replace it with Titan Auth Service:

| Feature | Auth0 | Titan Auth Service |
|---------|-------|-------------------|
| **Cost** | $$$$ (paid SaaS) | Free (self-hosted) |
| **Control** | Limited | Full control |
| **Customization** | Limited | Fully customizable |
| **Data Privacy** | Third-party | Internal |
| **Integration** | External API calls | Direct database |
| **Vendor Lock-in** | Yes | No |
| **Phone Auth** | Built-in SMS OTP | Need to add Twilio/SNS |

**Recommendation:** For MVP, you could **keep Auth0** initially (faster), then migrate to Titan Auth Service later for cost savings and control.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│              Titan Auth Service (Port 8004)         │
├─────────────────────────────────────────────────────┤
│                                                      │
│  POST /auth/register  ──▶ Create new user           │
│  POST /auth/login     ──▶ Authenticate user         │
│  POST /auth/refresh   ──▶ Refresh access token      │
│  POST /auth/logout    ──▶ Invalidate tokens         │
│  GET  /auth/verify    ──▶ Verify JWT token          │
│  GET  /health         ──▶ Health check              │
│                                                      │
├─────────────────────────────────────────────────────┤
│                   Dependencies                       │
├─────────────────────────────────────────────────────┤
│  PostgreSQL (5432)  - User credentials storage      │
│  Redis (6379)       - Refresh token storage         │
└─────────────────────────────────────────────────────┘
```

---

## API Endpoints

### 1. **POST /auth/register** - Create New User

**Request:**
```json
{
  "phone": "+14155551234",
  "password": "MySecurePassword123"
}
```

**Response (201 Created):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2025-12-31T15:30:00Z",
  "user_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

**What it does:**
- Validates phone number and password (min 8 chars)
- Hashes password with bcrypt
- Creates user in PostgreSQL
- Generates access token (24 hour expiry)
- Generates refresh token (7 day expiry)
- Stores refresh token in Redis

**Errors:**
- 409 Conflict - User already exists
- 400 Bad Request - Invalid input

---

### 2. **POST /auth/login** - Authenticate User

**Request:**
```json
{
  "phone": "+14155551234",
  "password": "MySecurePassword123"
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2025-12-31T15:30:00Z",
  "user_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

**What it does:**
- Looks up user by phone number
- Verifies password with bcrypt
- Updates last login timestamp
- Generates new access + refresh tokens
- Stores refresh token in Redis

**Errors:**
- 401 Unauthorized - Invalid credentials

---

### 3. **POST /auth/refresh** - Refresh Access Token

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response (200 OK):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_at": "2025-12-31T15:30:00Z",
  "user_id": "123e4567-e89b-12d3-a456-426614174000"
}
```

**What it does:**
- Verifies refresh token signature
- Checks if refresh token exists in Redis (not revoked)
- Generates new access token + refresh token
- Replaces old refresh token in Redis

**Use case:** When access token expires (after 24 hours), use refresh token to get new one without re-login

**Errors:**
- 401 Unauthorized - Invalid or expired refresh token

---

### 4. **POST /auth/logout** - Logout User

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

**What it does:**
- Extracts user ID from JWT access token
- Deletes refresh token from Redis
- User must re-login to get new tokens

---

### 5. **GET /auth/verify** - Verify JWT Token

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Response (200 OK):**
```json
{
  "valid": true,
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "phone": "+14155551234"
}
```

**What it does:**
- Validates JWT signature
- Checks expiration
- Returns user info from token

**Use case:** Other microservices (Payment Router, User Management, etc.) call this to verify incoming requests

**Errors:**
- 401 Unauthorized - Invalid or expired token

---

### 6. **GET /health** - Health Check

**Response (200 OK):**
```json
{
  "status": "healthy",
  "service": "auth-service"
}
```

---

## JWT Token Details

### Access Token (24 hour expiry)
```json
{
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "phone": "+14155551234",
  "exp": 1735660800,
  "iat": 1735574400,
  "sub": "123e4567-e89b-12d3-a456-426614174000"
}
```

**Signature:** HMAC-SHA256 with configurable secret

### Refresh Token (7 day expiry)
- Same structure as access token
- Longer expiration (7 days vs 24 hours)
- Stored in Redis with key: `refresh_token:{user_id}`
- Revoked on logout

---

## Security Features

### ✅ Password Security
- **bcrypt hashing** - Industry standard, slow hashing to prevent brute force
- **bcrypt.DefaultCost** - Cost factor 10 (~100ms to hash)
- Password minimum length: 8 characters

### ✅ Token Security
- **JWT with HMAC-SHA256** - Cryptographically signed tokens
- **Short access token expiry** - 24 hours (limits exposure)
- **Refresh token rotation** - New refresh token on each refresh
- **Redis storage** - Refresh tokens can be revoked instantly

### ✅ Session Management
- **Logout revokes refresh token** - Forces re-authentication
- **Redis TTL** - Tokens auto-expire after 7 days
- **Token verification** - All protected endpoints verify JWT

### ⚠️ Current Limitations
- **No rate limiting** - Vulnerable to brute force (add in production)
- **No 2FA** - Only password authentication
- **No password reset** - Need to add email/SMS verification
- **No account lockout** - After failed login attempts
- **No password complexity** - Only length requirement

---

## Database Schema

### PostgreSQL - `users` table

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

CREATE INDEX idx_users_phone ON users(phone);
```

### Redis - Token Storage

```
Key pattern: refresh_token:{user_id}
Value: JWT refresh token string
TTL: 7 days (604800 seconds)
```

---

## How to Use in iOS App

### Replace Auth0 Flow

**Before (Auth0 - Passwordless SMS):**
```swift
// 1. User enters phone number
// 2. Auth0 sends SMS with code
// 3. User enters code
// 4. Auth0 returns token
```

**After (Titan Auth - Password):**
```swift
// 1. User registers with phone + password
// 2. User logs in with phone + password
// 3. Titan Auth returns JWT tokens
// 4. Store tokens in Keychain
```

### Swift Implementation Example

```swift
import Foundation

class TitanAuthService {
    let baseURL = "http://localhost:8004"

    // Register new user
    func register(phone: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["phone": phone, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw AuthError.registrationFailed
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Store tokens in Keychain
        KeychainHelper.save(authResponse.accessToken, for: "access_token")
        KeychainHelper.save(authResponse.refreshToken, for: "refresh_token")

        return authResponse
    }

    // Login existing user
    func login(phone: String, password: String) async throws -> AuthResponse {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["phone": phone, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Store tokens in Keychain
        KeychainHelper.save(authResponse.accessToken, for: "access_token")
        KeychainHelper.save(authResponse.refreshToken, for: "refresh_token")

        return authResponse
    }

    // Refresh access token
    func refreshToken() async throws -> AuthResponse {
        guard let refreshToken = KeychainHelper.get("refresh_token") else {
            throw AuthError.noRefreshToken
        }

        let url = URL(string: "\(baseURL)/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.refreshFailed
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)

        // Update tokens in Keychain
        KeychainHelper.save(authResponse.accessToken, for: "access_token")
        KeychainHelper.save(authResponse.refreshToken, for: "refresh_token")

        return authResponse
    }

    // Logout user
    func logout() async throws {
        guard let accessToken = KeychainHelper.get("access_token") else {
            throw AuthError.noAccessToken
        }

        let url = URL(string: "\(baseURL)/auth/logout")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.logoutFailed
        }

        // Clear tokens from Keychain
        KeychainHelper.delete("access_token")
        KeychainHelper.delete("refresh_token")
    }
}

struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let userID: UUID

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case userID = "user_id"
    }
}

enum AuthError: Error {
    case registrationFailed
    case invalidCredentials
    case refreshFailed
    case logoutFailed
    case noAccessToken
    case noRefreshToken
}
```

### Attach Token to API Requests

```swift
class APIClient {
    func makeAuthenticatedRequest(url: URL) async throws -> Data {
        guard let accessToken = KeychainHelper.get("access_token") else {
            throw APIError.unauthorized
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // If token expired, try to refresh
        if httpResponse.statusCode == 401 {
            let authService = TitanAuthService()
            _ = try await authService.refreshToken()

            // Retry request with new token
            return try await makeAuthenticatedRequest(url: url)
        }

        return data
    }
}
```

---

## Configuration

### Environment Variables

```bash
# Server
PORT=8004

# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=blnk
POSTGRES_PASSWORD=blnk_dev_password
POSTGRES_DB=blnk
POSTGRES_SSLMODE=disable

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# JWT Secret (CHANGE IN PRODUCTION!)
JWT_SECRET=your-secret-key-change-in-production

# Logging
LOG_LEVEL=info
```

### Production Security

⚠️ **CRITICAL:** Before deploying to production:

1. **Change JWT_SECRET** to a strong random value:
   ```bash
   openssl rand -base64 32
   ```

2. **Enable HTTPS** - Never send passwords over HTTP

3. **Add rate limiting** - Prevent brute force attacks

4. **Add password complexity rules**

5. **Enable PostgreSQL SSL** - Encrypt database connections

6. **Use secrets manager** - Don't hardcode credentials

---

## Comparison: Auth0 vs Titan Auth Service

### For MVP - Keep Auth0 ✅

**Pros:**
- Already integrated in ios-wallet-app
- Passwordless SMS OTP works out of the box
- No development time needed
- Better UX (no password to remember)

**Cons:**
- Monthly cost (starts at $23/month, scales with users)
- External dependency
- Less control

**Recommendation:** Keep Auth0 for MVP to ship faster, migrate later

---

### For Long-Term - Migrate to Titan Auth

**When to migrate:**
- After validating product-market fit
- When monthly Auth0 costs exceed $100/month
- When you need custom auth flows
- For complete data ownership

**Migration effort:** 1-2 weeks

**Steps:**
1. Add password field to user registration
2. Replace Auth0 SDK calls with Titan Auth API
3. Migrate existing users (one-time password setup flow)
4. Test thoroughly
5. Switch over

---

## Adding SMS OTP to Titan Auth (Future Enhancement)

To match Auth0's passwordless experience:

```go
// 1. Send OTP via Twilio/AWS SNS
func (s *Service) SendOTP(ctx context.Context, phone string) error {
    code := generateOTP() // 6-digit code

    // Store in Redis with 5 min expiry
    key := fmt.Sprintf("otp:%s", phone)
    s.redisClient.Set(ctx, key, code, 5*time.Minute)

    // Send via Twilio
    return s.twilioClient.SendSMS(phone, fmt.Sprintf("Your code: %s", code))
}

// 2. Verify OTP
func (s *Service) VerifyOTP(ctx context.Context, phone, code string) (*AuthResponse, error) {
    key := fmt.Sprintf("otp:%s", phone)
    storedCode, err := s.redisClient.Get(ctx, key)

    if err != nil || storedCode != code {
        return nil, ErrInvalidOTP
    }

    // Create user if doesn't exist, generate tokens
    return s.generateTokens(ctx, userID, phone)
}
```

---

## Testing the Auth Service

### Manual Testing with curl

```bash
# 1. Register
curl -X POST http://localhost:8004/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+14155551234",
    "password": "SecurePassword123"
  }'

# Save the access_token and refresh_token from response

# 2. Login
curl -X POST http://localhost:8004/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+14155551234",
    "password": "SecurePassword123"
  }'

# 3. Verify token
curl -X GET http://localhost:8004/auth/verify \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 4. Refresh token
curl -X POST http://localhost:8004/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "YOUR_REFRESH_TOKEN"
  }'

# 5. Logout
curl -X POST http://localhost:8004/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

---

## Summary

### What is Titan Auth Service?

A **self-hosted JWT authentication microservice** that provides:
- ✅ User registration (phone + password)
- ✅ Login with JWT tokens
- ✅ Token refresh mechanism
- ✅ Logout with token revocation
- ✅ Token verification for other services
- ✅ bcrypt password hashing
- ✅ Redis session management

### Should You Use It for iOS App?

**For MVP:** Keep Auth0 (faster, better UX)
**For Production:** Migrate to Titan Auth (cheaper, more control)

### How Much Work to Integrate?

**If replacing Auth0:**
- Remove Auth0 SDK from Podfile
- Replace `Auth0AuthenticationAPI` calls with `TitanAuthService`
- Add password input UI
- Update token storage logic
- Testing

**Estimated effort:** 3-5 days

### Missing Features to Add

1. **SMS OTP** - For passwordless auth like Auth0
2. **Email verification** - Confirm email addresses
3. **Password reset** - Forgot password flow
4. **Rate limiting** - Prevent brute force
5. **Account lockout** - After failed attempts
6. **2FA** - TOTP/SMS second factor
7. **OAuth providers** - Google, Apple Sign-In
8. **Session management** - View active sessions

---

## Next Steps

Would you like me to:
- **A)** Keep Auth0 in iOS app for now (faster MVP)?
- **B)** Add SMS OTP to Titan Auth Service (1 week)?
- **C)** Create migration plan from Auth0 to Titan Auth?
- **D)** Start forking the iOS app with Auth0 as-is?
