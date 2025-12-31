# Auth0 Setup Guide - Titan Wallet

**Purpose:** Get Auth0 Client ID and Domain for iOS/Android apps
**Time:** 15 minutes
**Cost:** Free (up to 7,000 monthly active users)

---

## 🎯 What You'll Get

After this setup, you'll have:
- ✅ Auth0 Client ID (e.g., `abc123xyz456`)
- ✅ Auth0 Domain (e.g., `titan-wallet.us.auth0.com`)
- ✅ Passwordless SMS authentication configured
- ✅ Test environment ready

---

## Step 1: Create Auth0 Account (5 min)

### 1.1 Sign Up

Go to: **https://auth0.com/signup**

**Choose:**
- Personal account (for now)
- Email + password OR sign up with Google/GitHub

### 1.2 Complete Profile
- Company name: **Titan Wallet** (or your choice)
- Account type: **Personal** or **Company**
- Role: **Developer** or **Founder**

### 1.3 Choose Region
- **United States** (recommended for US-based app)
- This affects where your data is stored

**Click:** "Create Account"

---

## Step 2: Create Application (3 min)

After signup, you'll be in the Auth0 Dashboard.

### 2.1 Create Application

1. Click **"Applications" → "Applications"** in left sidebar
2. Click **"Create Application"** button
3. Fill in:
   - **Name:** `Titan Wallet Consumer - Test`
   - **Application Type:** Select **"Native"** (for iOS/Android)
4. Click **"Create"**

### 2.2 Get Your Credentials ⭐

You'll see the "Quick Start" screen. Click the **"Settings"** tab.

**Copy these two values:**

```
Domain: titan-wallet.us.auth0.com
         ^^^^^^^^^^^^^ (your tenant name will be different)

Client ID: abc123xyz456789
           ^^^^^^^^^^^^^^^^ (long random string)
```

**Keep this page open!** You'll need these values.

---

## Step 3: Configure Application Settings (5 min)

Still in the "Settings" tab:

### 3.1 Application URIs

Scroll down to find these fields:

**Allowed Callback URLs:**
```
com.titanwallet.consumer://titan-wallet.us.auth0.com/ios/com.titanwallet.consumer/callback,
titanwallet://callback
```

**Allowed Logout URLs:**
```
com.titanwallet.consumer://titan-wallet.us.auth0.com/ios/com.titanwallet.consumer/logout,
titanwallet://logout
```

**Allowed Web Origins:**
```
file://*
```

### 3.2 Advanced Settings

Scroll down to **"Advanced Settings"** → Click to expand

**Grant Types:** Ensure these are checked:
- ✅ Implicit
- ✅ Authorization Code
- ✅ Refresh Token
- ✅ Password (for testing)

### 3.3 Save Changes

**Scroll to bottom** → Click **"Save Changes"**

---

## Step 4: Enable Passwordless SMS (2 min) ⭐

### 4.1 Navigate to Passwordless

1. In left sidebar: **"Authentication" → "Passwordless"**
2. You'll see **SMS** option
3. Click **"SMS"** to configure

### 4.2 Configure SMS Provider

**For Testing (Free):**
- Auth0 provides a built-in SMS service for testing
- Limited to a few messages per day
- **Toggle:** Turn **ON** the SMS option

**For Production (Paid):**
- You'll need Twilio or another SMS provider
- We'll set this up later

### 4.3 Customize SMS Template (Optional)

**Default message:**
```
Your verification code is: ######
```

**Custom message:**
```
Your Titan Wallet verification code is: ######

This code expires in 5 minutes.
```

**Click:** "Save"

---

## Step 5: Update iOS App Configuration (2 min)

Now you have:
- ✅ Domain: `titan-wallet.us.auth0.com` (example)
- ✅ Client ID: `abc123xyz456789` (example)

### 5.1 Update AppMetaData.json

Open: `/Users/pushkar/Downloads/rtpayments/titan-consumer-ios/Solid/Solid/Source/Classes/Utilities/App Utils/AppMetaData.json`

**Replace these values:**

```json
{
  "env": {
    "prodtest": {
      "auth0ClientId": "YOUR_ACTUAL_CLIENT_ID_HERE",
      "auth0Domain": "your-tenant-name.us.auth0.com",
      "auth0Audience": "https://api-test.titanwallet.com"
    }
  }
}
```

**Example with real values:**

```json
{
  "env": {
    "prodtest": {
      "auth0ClientId": "abc123xyz456789",
      "auth0Domain": "titan-wallet.us.auth0.com",
      "auth0Audience": "https://api-test.titanwallet.com"
    }
  }
}
```

---

## Step 6: Test Authentication (Optional)

### 6.1 Open App in Xcode

```bash
cd /Users/pushkar/Downloads/rtpayments/titan-consumer-ios/Solid
pod install  # Install dependencies first
open Solid.xcworkspace
```

### 6.2 Build and Run

1. Select **iPhone 14 Pro** simulator
2. Press **Cmd + R** to build and run
3. Click "Login" or "Get Started"
4. Enter phone number (use your real number for testing)
5. You should receive SMS with verification code
6. Enter code and you're in!

### 6.3 Verify in Auth0 Dashboard

Go back to Auth0 Dashboard:
- **Users & Roles → Users**
- You should see your test user listed

---

## 🎉 You're Done!

You now have:
- ✅ Auth0 account configured
- ✅ Client ID and Domain
- ✅ Passwordless SMS enabled
- ✅ iOS app configured
- ✅ Ready to test login

---

## 📋 Quick Reference

### Your Auth0 Credentials

```
Auth0 Dashboard: https://manage.auth0.com
Domain: [YOUR_TENANT].us.auth0.com
Client ID: [YOUR_CLIENT_ID]
```

**Save these in a secure location!**

### Files to Update

**iOS App:**
- `Solid/Solid/Source/Classes/Utilities/App Utils/AppMetaData.json`

**Android App (later):**
- `wise-android-v2-core/src/main/cpp/native-lib.cpp`

---

## 🔒 Production Setup (Later)

Before going to production, you'll need:

### 1. Custom SMS Provider (Twilio)

**Why:** Auth0's built-in SMS is limited

**Steps:**
1. Sign up for Twilio: https://www.twilio.com/try-twilio
2. Get Twilio Account SID and Auth Token
3. In Auth0: Authentication → Passwordless → SMS
4. Configure Twilio credentials
5. Test with production phone numbers

**Cost:** ~$0.0079 per SMS (very cheap)

### 2. Custom Domain (Optional)

Instead of: `titan-wallet.us.auth0.com`
Use: `auth.titanwallet.com`

**Steps:**
1. Auth0 Dashboard → Branding → Custom Domains
2. Add your domain
3. Configure DNS records
4. Update iOS app configuration

### 3. Branding Customization

**Login Page:**
- Auth0 Dashboard → Branding → Universal Login
- Customize logo, colors, background
- Match Titan Wallet brand (#667eea purple gradient)

**Emails:**
- Auth0 Dashboard → Branding → Email Templates
- Customize welcome email, password reset, etc.

### 4. Security Enhancements

**Multi-Factor Authentication (MFA):**
- Auth0 Dashboard → Security → Multi-factor Auth
- Enable TOTP (Google Authenticator) or SMS

**Anomaly Detection:**
- Auth0 Dashboard → Security → Anomaly Detection
- Enable brute force protection
- Enable breached password detection

**Rules (Advanced):**
- Auth0 Dashboard → Auth Pipeline → Rules
- Add custom logic (e.g., check user blacklist, log to analytics)

---

## 🆘 Troubleshooting

### "Unable to send SMS"
- **Cause:** Auth0 built-in SMS has daily limit
- **Fix:** Set up Twilio (see Production Setup above)

### "Invalid Client ID"
- **Cause:** Typo in AppMetaData.json
- **Fix:** Double-check Client ID copied from Auth0 Dashboard

### "Callback URL Mismatch"
- **Cause:** iOS bundle ID doesn't match configured callback
- **Fix:** Ensure Allowed Callback URLs includes your bundle ID

### "User not found"
- **Cause:** First-time login creates user automatically
- **Fix:** This is normal, user will be created on first login

---

## 📞 Support

**Auth0 Documentation:** https://auth0.com/docs
**Auth0 Community:** https://community.auth0.com
**Titan Wallet Support:** support@titanwallet.com

---

## 🔄 Next Steps

After Auth0 is configured:

1. ✅ Test login flow in iOS app
2. ✅ Create GitHub repo and push code
3. ✅ Start API integration with Titan backend
4. ✅ Add @handle support via HRS
5. ✅ Set up Android app (repeat Auth0 steps)

---

**Summary:** Go to auth0.com/signup → Create "Native" app → Get Client ID & Domain → Update AppMetaData.json → Test!
