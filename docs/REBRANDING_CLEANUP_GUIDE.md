# Complete Solid → Titan Rebranding Cleanup Guide

**Current Status:** Functional rebranding complete, but many internal "Solid" references remain
**Impact:** 474 iOS files + 1,328 Android files contain "Solid" references
**Risk Level:** 🔴 HIGH - Improper renaming will break builds

---

## ✅ What's Already Done

1. **User-Facing Branding**
   - ✅ App names changed to "Titan Wallet" / "Titan Merchant"
   - ✅ Auth0 credentials updated
   - ✅ API base URLs changed to titanwallet.com
   - ✅ Support URLs updated
   - ✅ Color scheme changed to purple gradient

2. **API Integration**
   - ✅ iOS EndpointItem.swift routes to Titan microservices
   - ✅ Android native-lib.cpp updated with Titan URLs

3. **Documentation**
   - ✅ README files rewritten for Titan
   - ✅ API integration guide created

## 🔴 What Still References "Solid"

### iOS Apps (474 files affected)

#### Critical Infrastructure (DO NOT RENAME - Will break build)
```
Solid/                           # Main Xcode project folder
Solid.xcodeproj                  # Xcode project file
Solid.xcworkspace                # CocoaPods workspace
Solid/Solid/                     # Source code root
```

**Why not rename:** Xcode projects are complex - renaming breaks:
- Build schemes
- CocoaPods integration
- Framework search paths
- Code signing configuration
- Git history

#### Code That Should Be Renamed (Safe, but tedious)
```swift
// Class names
class SolidViewController
class SolidAPIManager
class SolidConstants

// Comments
// Created by Solid iOS Team

// String literals
let appName = "Solid"
"Welcome to Solid"

// URL schemes
"solid://callback"

// Bundle identifiers (in Info.plist)
com.solidfi.wallet
```

#### Package/Module Names (Risky to rename)
```
import Solid
@testable import Solid
```

### Android Apps (1,328 files affected)

#### Critical Infrastructure (DO NOT RENAME - Will break build)
```
Package names:
us.solid.android.core
us.solid.android.presentation
us.solid.android.network

Native library functions:
Java_us_solid_android_core_secure_Keys_*
```

**Why not rename:** Android package names are:
- Used in AndroidManifest.xml
- Referenced in R.java resource files
- Part of JNI native function signatures
- Tied to existing Play Store app ID

#### Code That Can Be Renamed (Safe)
```kotlin
// Comments
// Created by Solid Team

// String resources
<string name="app_name">Solid</string>

// Variable names
val solidApiClient = ...
val solidBaseUrl = ...

// Log tags
Log.d("SolidApp", "...")
```

---

## 📋 Recommended Cleanup Strategy

### Phase 1: User-Visible Strings (SAFE - No Build Impact)

**iOS:**
```bash
cd titan-consumer-ios

# Update display strings in code
find . -type f -name "*.swift" -exec sed -i '' 's/"Solid"/"Titan"/g' {} \;
find . -type f -name "*.swift" -exec sed -i '' "s/'Solid'/'Titan'/g" {} \;

# Update comments
find . -type f -name "*.swift" -exec sed -i '' 's/Solid iOS Team/Titan iOS Team/g' {} \;
find . -type f -name "*.swift" -exec sed -i '' 's/Solid Team/Titan Team/g' {} \;

# Update UI strings
find . -name "*.strings" -exec sed -i '' 's/Solid/Titan/g' {} \;
```

**Android:**
```bash
cd titan-consumer-android

# Update strings.xml files
find . -name "strings.xml" -exec sed -i '' 's/>Solid</>Titan</g' {} \;

# Update comments
find . -name "*.kt" -exec sed -i '' 's/Solid Team/Titan Team/g' {} \;

# Update log tags (be careful not to break code)
find . -name "*.kt" -exec sed -i '' 's/"Solid/"Titan/g' {} \;
```

**Testing:** Build and run app - should work fine.

---

### Phase 2: Internal Variable Names (MEDIUM RISK)

**Example safe renames:**
```swift
// Before
let solidApiManager = SolidAPIManager()
var solidToken: String?

// After
let titanApiManager = TitanAPIManager()
var titanToken: String?
```

**How to do it safely:**
1. Use Xcode's refactoring tools (Right-click → Refactor → Rename)
2. Rename one class at a time
3. Build and test after each rename
4. Commit after each successful rename

**Android:**
```kotlin
// Before
val solidClient = SolidHttpClient()

// After
val titanClient = TitanHttpClient()
```

Use Android Studio's refactoring (Shift+F6) to rename symbols safely.

---

### Phase 3: Class Names (HIGH RISK - Time Intensive)

**iOS Classes to Consider Renaming:**
```
SolidAPIManager → TitanAPIManager
SolidConstants → TitanConstants
SolidNetworkClient → TitanNetworkClient
```

**Process:**
1. Open in Xcode
2. Select class name
3. Editor → Refactor → Rename
4. Xcode will find all references
5. Review changes carefully
6. Build and test
7. Commit

**Android Classes:**
```kotlin
SolidApplication → TitanApplication
SolidActivity → TitanActivity
```

Use Android Studio's "Refactor → Rename" feature.

---

### Phase 4: File Names (RISKY)

Renaming files can break:
- Build scripts
- Resource references
- CocoaPods podspec files

**Safe approach:**
1. Create new file with Titan name
2. Copy contents from Solid file
3. Update all references to point to new file
4. Delete old file
5. Build and test

---

## 🚫 What NOT to Rename

### iOS - DO NOT TOUCH:
```
Solid.xcodeproj/               # Xcode project
Solid.xcworkspace/             # CocoaPods workspace
Solid/Solid/ (folder names)    # Build paths hardcoded
Info.plist → CFBundleIdentifier # Requires new provisioning profile
```

### Android - DO NOT TOUCH:
```
Package names: us.solid.*      # Breaks JNI, R.java, manifest
applicationId in build.gradle  # Tied to Play Store listing
native-lib.cpp function names  # JNI signature matching
```

### Both Platforms - DO NOT TOUCH:
```
Git history commits             # Don't rewrite history
node_modules/ or Pods/         # Third-party dependencies
.git/                          # Git metadata
```

---

## 🧪 Testing Strategy

After each rename phase:

**iOS:**
```bash
cd titan-consumer-ios/Solid
pod install
open Solid.xcworkspace
# Build (Cmd+B) - must succeed
# Run on simulator (Cmd+R) - must launch
# Test login flow
# Test one payment flow
```

**Android:**
```bash
cd titan-consumer-android
./gradlew clean build
# Must build successfully
# Run on emulator
# Test login
# Test core features
```

---

## 📊 Effort Estimate

| Phase | Effort | Risk | Priority |
|-------|--------|------|----------|
| Phase 1: Strings | 2-3 hours | Low | High |
| Phase 2: Variables | 8-10 hours | Medium | Medium |
| Phase 3: Classes | 20-30 hours | High | Low |
| Phase 4: Files | 10-15 hours | High | Low |
| **Total** | **40-58 hours** | **Varies** | - |

---

## 🎯 Recommended Approach

### Option A: Quick Win (Recommended for MVP)
**Focus:** Phase 1 only - Clean up user-visible strings
**Effort:** 2-3 hours
**Result:** Apps look fully rebranded to users
**Codebase:** Still has internal "Solid" references (acceptable)

### Option B: Partial Cleanup
**Focus:** Phase 1 + Phase 2
**Effort:** 10-13 hours
**Result:** UI + code variables use "Titan"
**Codebase:** Classes/files still reference "Solid"

### Option C: Complete Rebrand
**Focus:** All phases
**Effort:** 40-58 hours
**Result:** Zero "Solid" references anywhere
**Risk:** High chance of breaking something
**Testing:** Requires extensive regression testing

---

## 🚀 Quick Start Script (Phase 1 - Safe Changes Only)

I can run this for you right now to clean up the most visible references:

```bash
#!/bin/bash
# Safe rebrand script - Phase 1 only

echo "🎯 Cleaning up user-visible Solid references..."

# iOS Consumer App
cd titan-consumer-ios
find Solid/Solid/Source -name "*.swift" -exec sed -i '' 's/"Solid Wallet"/"Titan Wallet"/g' {} \;
find Solid/Solid/Source -name "*.swift" -exec sed -i '' 's/Solid iOS Team/Titan iOS Team/g' {} \;

# iOS Merchant App
cd ../titan-merchant-ios
find Solid/Solid/Source -name "*.swift" -exec sed -i '' 's/"Solid"/"Titan"/g' {} \;
find Solid/Solid/Source -name "*.swift" -exec sed -i '' 's/Solid iOS Team/Titan iOS Team/g' {} \;

# Android Consumer
cd ../titan-consumer-android
find . -name "strings.xml" -exec sed -i '' 's/>Solid Wallet</>Titan Wallet</g' {} \;

# Android Merchant
cd ../titan-merchant-android
find . -name "strings.xml" -exec sed -i '' 's/>Solid</>Titan</g' {} \;

echo "✅ Phase 1 cleanup complete!"
```

---

## ❓ Decision Point

**What do you want to do?**

1. **Run Phase 1 cleanup now** (2-3 hours, safe, high impact)
2. **Full cleanup later** (40+ hours, risky, requires testing)
3. **Leave as-is** (Internal code keeps "Solid" references - totally fine for MVP)

For an MVP/production launch, **Option 1 is recommended**. Internal code references don't affect users.

---

## 💡 Professional Opinion

**Keep internal "Solid" references for now.** Here's why:

✅ **Pros of keeping "Solid" in code:**
- Zero risk of breaking builds
- Maintains compatibility with forked codebase
- Easy to merge future Solid.fi updates if needed
- Saves 40+ hours of tedious refactoring
- Users never see internal code

❌ **Cons of keeping "Solid" in code:**
- Confusing for new developers
- Code comments reference wrong company
- Package names don't match brand

**Industry Standard:** Many companies keep original package names after rebrand:
- Instagram → Meta (still com.instagram.*)
- Facebook → Meta (still com.facebook.*)
- Twitter → X (still com.twitter.*)

---

Let me know if you want me to run the **Phase 1 Quick Script** to clean up the most visible references!
