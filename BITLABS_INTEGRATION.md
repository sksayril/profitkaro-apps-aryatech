# BitLabs Offerwall Integration Guide

## ✅ Completed Steps

### 1. Flutter Service Created
- **File:** `lib/core/services/bitlabs_service.dart`
- **Status:** ✅ Complete
- **Features:**
  - BitLabs API credentials configured
  - Method channel setup for native communication
  - User ID management
  - Offerwall display logic
  - Error handling

### 2. API Credentials Configured
- **App/API Token:** `a35d4e74-34a4-4949-bf48-e05dff23baba`
- **Secret Key:** `pS95rv88N216iCzM0qDUPi7G2bQyTw0O`
- **Server to Server Key:** `pNobVtw17qFfP93LQbF5y4QWUCXbaBaf`

### 3. Native Android Integration Started
- **File:** `android/app/src/main/kotlin/com/profitkaro/MainActivity.kt`
- **Status:** ⚠️ Method channel created, SDK integration pending
- **Method Channel:** `bitlabs_offerwall`

### 4. UI Integration Complete
- **File:** `lib/screens/task_offers/task_offers_screen.dart`
- **Status:** ✅ Complete
- **Features:**
  - Popup menu with both Tapjoy and BitLabs options
  - Two buttons in empty state (Tapjoy & BitLabs)
  - Error handling and user feedback

### 5. App Initialization
- **File:** `lib/main.dart`
- **Status:** ✅ BitLabsService.init() added

---

## ⚠️ Pending Steps

### 1. Add BitLabs Android SDK

#### Option A: If BitLabs provides Maven/Gradle dependency
Add to `android/app/build.gradle`:
```gradle
dependencies {
    // ... existing dependencies
    implementation 'com.bitlabs:bitlabs-sdk:X.X.X' // Replace with actual version
}
```

#### Option B: If BitLabs provides AAR file
1. Download BitLabs SDK AAR file
2. Place it in `android/app/libs/` directory
3. Add to `android/app/build.gradle`:
```gradle
dependencies {
    // ... existing dependencies
    implementation files('libs/bitlabs-sdk.aar')
}
```

#### Option C: If BitLabs uses REST API (Web-based)
- The current implementation can be extended to use HTTP requests
- No native SDK needed
- Use `http` package for API calls

---

### 2. Complete Native Android Implementation

Update `MainActivity.kt` in the BitLabs method channel handler:

```kotlin
"init" -> {
    val apiToken = call.argument<String>("apiToken")
    val secretKey = call.argument<String>("secretKey")
    
    // Initialize BitLabs SDK
    // Example (adjust based on actual SDK):
    // BitLabs.init(applicationContext, apiToken, secretKey)
    
    isBitLabsInitialized = true
    result.success(true)
}

"showOfferwall" -> {
    // Show BitLabs offerwall
    // Example (adjust based on actual SDK):
    // BitLabs.showOfferwall(activity)
    
    result.success(true)
}
```

---

### 3. BitLabs Dashboard Configuration

1. **Login to BitLabs Dashboard**
2. **Create/Verify Placement:**
   - Create a placement (e.g., "offerwall_main")
   - Note the exact placement name
3. **Assign Offers:**
   - Ensure offers are **Active** and **Published**
   - Assign offers to the placement
4. **Verify Settings:**
   - Check API Token matches: `a35d4e74-34a4-4949-bf48-e05dff23baba`
   - Verify app is properly linked

---

## 📝 Code Structure

### Flutter Side
```
lib/
  core/
    services/
      bitlabs_service.dart  ✅ Created
  screens/
    task_offers/
      task_offers_screen.dart  ✅ Updated
  main.dart  ✅ Updated
```

### Android Native Side
```
android/app/src/main/kotlin/com/profitkaro/
  MainActivity.kt  ⚠️ Method channel ready, SDK integration pending
```

---

## 🔧 Testing Steps

1. **Add BitLabs SDK to build.gradle**
2. **Complete native implementation in MainActivity.kt**
3. **Rebuild app:** `flutter clean && flutter build apk`
4. **Test offerwall display:**
   - Navigate to Task Offers screen
   - Tap on offerwall button
   - Verify BitLabs offerwall opens

---

## 📚 Resources Needed

1. **BitLabs Android SDK Documentation**
   - SDK initialization
   - Offerwall display methods
   - Callback handlers
   - User ID setting

2. **BitLabs Dashboard Access**
   - Placement configuration
   - Offer management
   - API credentials verification

---

## 🎯 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| Flutter Service | ✅ Complete | Ready to use |
| API Credentials | ✅ Configured | All keys added |
| Method Channel | ✅ Created | Native communication ready |
| UI Integration | ✅ Complete | Both offerwalls accessible |
| Native SDK | ⚠️ Pending | Requires BitLabs SDK |
| Dashboard Setup | ⚠️ Pending | Needs offers configuration |

---

## 🚀 Next Steps

1. **Obtain BitLabs Android SDK:**
   - Download from BitLabs developer portal
   - Or get Maven/Gradle dependency information

2. **Complete Native Integration:**
   - Add SDK dependency to build.gradle
   - Implement SDK initialization in MainActivity.kt
   - Implement offerwall display logic

3. **Configure Dashboard:**
   - Create placement in BitLabs dashboard
   - Assign active offers
   - Verify API credentials

4. **Test & Deploy:**
   - Test offerwall display
   - Verify reward callbacks
   - Deploy to production

---

## 💡 Important Notes

- **BitLabs Service is ready** - Once SDK is added, it will work immediately
- **Method channel is set up** - Just need to connect to actual SDK
- **UI is complete** - Users can access both offerwalls
- **Error handling is in place** - Graceful fallbacks if offerwall fails

---

**Last Updated:** Integration structure complete, awaiting BitLabs SDK for native implementation.
