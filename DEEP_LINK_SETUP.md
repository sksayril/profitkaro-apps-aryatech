# Deep Link Setup for Referral Codes

## Overview
This app supports deep linking for referral codes with multiple URL formats. When users click a referral link, the app will:
1. **If app is installed**: Open the app and save the referral code
2. **If app is NOT installed**: Redirect to Play Store to download the app

## Supported URL Formats

The app supports the following referral URL formats:

### Path Format:
- `https://apiprofit.seotube.in/refer/VYD62W`

### Query Parameter Formats:
- `https://apiprofit.seotube.in/refer?code=VYD62W`
- `https://apiprofit.seotube.in/refer?refer=VYD62W`

### Custom Scheme:
- `profitkaro://refer?code=VYD62W`

## Android Configuration

### ✅ Already Configured:
- Deep link intent filters in `AndroidManifest.xml`
- Custom scheme support (`profitkaro://refer`)
- HTTPS deep link support (`https://apiprofit.seotube.in`)

## Web Server Setup

### Required: Backend API Endpoint

You need to create a backend endpoint that:

1. **Validates the referral code** exists in your database
2. **Returns appropriate HTML page** based on validation result:
   - **200 OK**: Returns `web_referral_redirect.html` (if code is valid)
   - **400 Bad Request**: Returns `web_referral_error_400.html` (if code is missing/invalid)
   - **404 Not Found**: Returns `web_referral_error_404.html` (if code doesn't exist)

### Web Redirect Page Flow

The `web_referral_redirect.html` page will:

1. **Extract referral code** from URL (supports all formats)
2. **Try Android Intent URL**: `intent://refer?code=VYD62W#Intent;scheme=profitkaro;package=com.profitkaro;S.refer=VYD62W;end`
3. **Fallback to custom scheme**: `profitkaro://refer?code=VYD62W`
4. **Final fallback**: Redirect to Play Store with referrer: `https://play.google.com/store/apps/details?id=com.profitkaro&referrer=VYD62W`

### Server Configuration Example (Apache .htaccess)

```apache
RewriteEngine On

# Handle /refer/CODE format
RewriteRule ^refer/([A-Z0-9]+)$ /api/referral.php?code=$1 [L,QSA]

# Handle /refer?code=CODE or /refer?refer=CODE
RewriteCond %{QUERY_STRING} ^(code|refer)=([A-Z0-9]+)$
RewriteRule ^refer$ /api/referral.php?code=%2 [L,QSA]
```

### Server Configuration Example (Nginx)

```nginx
# Handle /refer/CODE format
location ~ ^/refer/([A-Z0-9]+)$ {
    rewrite ^/refer/(.*)$ /api/referral.php?code=$1 last;
}

# Handle query parameters
location = /refer {
    if ($arg_code) {
        rewrite ^ /api/referral.php?code=$arg_code last;
    }
    if ($arg_refer) {
        rewrite ^ /api/referral.php?code=$arg_refer last;
    }
}
```

### Backend API Example (PHP)

```php
<?php
// api/referral.php
$code = strtoupper(trim($_GET['code'] ?? ''));

if (empty($code)) {
    http_response_code(400);
    include 'web_referral_error_400.html';
    exit;
}

// Validate code in database
$isValid = validateReferralCode($code); // Your validation function

if (!$isValid) {
    http_response_code(404);
    include 'web_referral_error_404.html';
    exit;
}

// Code is valid, serve redirect page
http_response_code(200);
include 'web_referral_redirect.html';
?>
```

## How It Works

1. **User clicks referral link**: `https://apiprofit.seotube.in/refer/VYD62W`
2. **Backend validates code**: Checks if code exists in database
3. **If valid**: Serves redirect HTML page
4. **Redirect page tries to open app**: Uses Intent URL → Custom scheme → Play Store
5. **If app installed**: Android opens app, referral code is saved automatically
6. **If app NOT installed**: Redirects to Play Store with referrer parameter
7. **After installation**: When user opens app and signs up, referral code is auto-filled

## Testing

### Test Deep Link - Path Format:
```bash
adb shell am start -a android.intent.action.VIEW -d "https://apiprofit.seotube.in/refer/TEST123" com.profitkaro
```

### Test Deep Link - Query Format:
```bash
adb shell am start -a android.intent.action.VIEW -d "https://apiprofit.seotube.in/refer?code=TEST123" com.profitkaro
```

### Test Custom Scheme:
```bash
adb shell am start -a android.intent.action.VIEW -d "profitkaro://refer?code=TEST123" com.profitkaro
```

## Play Store URL

Package Name: `com.profitkaro`
Play Store URL: `https://play.google.com/store/apps/details?id=com.profitkaro`
With Referrer: `https://play.google.com/store/apps/details?id=com.profitkaro&referrer=VYD62W`

## Files Provided

- `web_referral_redirect.html` - Main redirect page (200 OK)
- `web_referral_error_400.html` - Invalid code error page (400 Bad Request)
- `web_referral_error_404.html` - Code not found error page (404 Not Found)

## Notes

- The referral code is automatically saved in local storage when the app opens
- The code is auto-filled in the signup form
- The code is cleared after successful signup
- All URL formats are supported and automatically detected
