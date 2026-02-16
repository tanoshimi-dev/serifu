# Social Login Setup Guide

## Overview

Mobile app (Flutter) supports social login via Google, LINE, and Apple (iOS only).
After social login, the backend verifies the access token and returns a JWT.

---

## LINE Login

### iOS Setup

- **Info.plist** URL scheme: `line3rdp.app.dev.serifu` (must match `line3rdp.{PRODUCT_BUNDLE_IDENTIFIER}`)
- **Info.plist** LSApplicationQueriesSchemes: `lineauth2`
- LINE SDK initialized in `main.dart` with `LINE_CHANNEL_ID` from `.env`

### Android Setup

- LINE SDK handles callbacks internally via `lineauth://` scheme (registered by the SDK's own `LineAuthenticationCallbackActivity`)
- No additional intent-filter needed in `AndroidManifest.xml`
- `onlyWebLogin: true` is set on Android to skip LINE app attempt on emulator

### LINE Developers Console

- Channel ID: `2009144840`
- iOS bundle ID: `app.dev.serifu`
- Android package name: `app.dev.serifu`
- Android package signature (debug SHA-256): `6a41b8533289d9cc7531badfd58043c13e1efe0eec2e0424890de8e0e952e48d`

### Known Limitation: Android Emulator

LINE login via web (Chrome Custom Tab) does **not** work on Android emulator.
Chrome blocks HTTP 302 redirects to custom URL schemes (`lineauth://`) for security.

**Workarounds:**
- Test on a physical Android device with LINE app installed (app-to-app auth bypasses Chrome)
- Use email/password or Google login for emulator development
- Install LINE on the emulator via Google Play Store (if available)

---

## Google Login

- Uses `google_sign_in` package
- Client IDs configured in `.env`:
  - `GOOGLE_CLIENT_ID` (server/web client ID)
  - `GOOGLE_IOS_CLIENT_ID` (iOS client ID)
- iOS URL scheme in Info.plist: `com.googleusercontent.apps.5421221322-kpqbjqdbd4t89v6jpi6e6r5qmbrdbogi`

---

## Apple Login (iOS only)

- Uses `sign_in_with_apple` package
- Client ID: `app.dev.serifu`
- Only shown on iOS (`Platform.isIOS` check)

---

## API Base URL Configuration

The backend URL is determined by platform (no `.env` override needed for simulators/emulators):

| Platform          | URL                              |
|-------------------|----------------------------------|
| Android emulator  | `http://10.0.2.2:8080/api/v1`   |
| iOS simulator     | `http://localhost:8080/api/v1`   |
| Physical device   | Set `API_BASE_URL` in `.env`     |
| Production        | `https://backend.serifu.dev/api/v1` |

---

## Error Handling

Social login errors are caught in `_handleSocialLogin()` on both `LoginScreen` and `RegisterScreen`:

- **User cancellation** (including LINE SDK `PlatformException(CANCEL)`): silently dismissed, no error shown
- **Connection errors** (`SocketException`, `Connection refused`): shows "Unable to connect to the server. Please try again later."
- **Other errors**: shown as-is with `Exception:` prefix stripped

---

## Key Files

| File | Purpose |
|------|---------|
| `lib/services/social_auth_service.dart` | Google, Apple, LINE login logic |
| `lib/services/auth_service.dart` | Token storage and auth state |
| `lib/api/api_client.dart` | API base URL and HTTP client |
| `lib/screens/login_screen.dart` | Login UI and error handling |
| `lib/screens/register_screen.dart` | Register UI and error handling |
| `lib/main.dart` | LINE SDK initialization |
| `ios/Runner/Info.plist` | iOS URL schemes and queries |
| `android/app/src/main/AndroidManifest.xml` | Android manifest |
| `.env` | API keys and configuration |

---

## Changes Made (2026-02-17)

1. **Fixed iOS LINE login** - Changed URL scheme from `line3rdp.2009144840` (channel ID) to `line3rdp.app.dev.serifu` (bundle ID)
2. **Made API base URL platform-aware** - Reads `API_BASE_URL` from `.env`, falls back to platform-specific defaults
3. **Added LINE SDK cancel handling** - Catches `PlatformException(CANCEL)` in `signInWithLine()`
4. **Improved error messages** - Network errors show user-friendly messages, cancellations are silent
5. **Set `onlyWebLogin` on Android** - Skips LINE app attempt on emulator (no LINE app installed)
