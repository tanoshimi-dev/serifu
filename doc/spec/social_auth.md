# Social Authentication Flow Spec

## Overview

Serifu supports three social login providers: Google, LINE, and Apple (iOS only).
All flows follow the same pattern: the mobile client authenticates with the provider, obtains a token/credential, sends it to the backend for verification, and receives a JWT.

---

## Architecture: Two Approaches to Social Login

### Approach A: Native SDK (Client-Side Token) — Current Serifu

```
Mobile App                    Provider (Google/LINE/Apple)           Backend
    |                                    |                              |
    |--- 1. Open native login flow ----->|                              |
    |                                    |                              |
    |<-- 2. Return token/credential -----|                              |
    |                                    |                              |
    |--- 3. POST /auth/{provider} ---------------------------------->  |
    |       { token: "...", name: "..." }                               |
    |                                    |                              |
    |                                    |<-- 4. Verify token -------->|
    |                                    |                              |
    |<-- 5. Return JWT + user ---------------------------------------- |
```

- Client handles the entire OAuth flow via native SDK
- Backend only verifies the token and creates/links the user
- Simpler backend (no OAuth state, no callback URLs)
- Depends on native SDK platform support

### Approach B: Server-Side OAuth (WebView) — ChatShare Reference

```
Mobile App                    Backend                         Provider
    |                            |                               |
    |--- 1. GET /auth/line/url ->|                               |
    |                            |--- 2. Generate OAuth URL ---->|
    |<-- 3. Return { url, state }|                               |
    |                            |                               |
    |--- 4. Open URL in WebView -------------------------------->|
    |                            |                               |
    |<-- 5. User authenticates, redirect to callback ----------->|
    |                            |                               |
    |--- 6. Backend receives callback with auth code ----------->|
    |                            |--- 7. Exchange code --------->|
    |                            |<-- 8. Return access token ----|
    |                            |--- 9. Verify + get profile -->|
    |                            |                               |
    |<-- 10. Return JWT + user --|                               |
```

- Backend manages OAuth state and code exchange
- Mobile opens OAuth URL in an in-app WebView
- Works on all platforms (no native SDK needed)
- More complex backend, but avoids Chrome Custom Tab redirect issues

### Comparison

| Aspect | Native SDK (Serifu) | Server-Side OAuth (ChatShare) |
|--------|---------------------|-------------------------------|
| Android emulator | LINE: broken (Chrome blocks `lineauth://` redirect) | Works (WebView handles redirects internally) |
| Physical device | Works (app-to-app auth) | Works |
| iOS | Works | Works |
| Backend complexity | Simple (verify token only) | Complex (OAuth URL, callback, code exchange) |
| Dependencies | `flutter_line_sdk`, `google_sign_in`, `sign_in_with_apple` | `webview_flutter` only |
| Security | Token stays on client briefly | Auth code exchanged server-side (more secure) |
| Offline token refresh | Not supported (SDK handles tokens) | Backend controls refresh |

---

## Current Implementation: Serifu (Approach A)

### Provider-Specific Flows

#### Google Login

```
1. Client: GoogleSignIn → returns Google ID Token (JWT)
2. Client: POST /api/v1/auth/google { token: idToken }
3. Backend: GET https://oauth2.googleapis.com/tokeninfo?id_token={token}
4. Backend: Verify audience matches GOOGLE_CLIENT_ID
5. Backend: Extract sub, email, name, picture
6. Backend: findOrCreateSocialUser("google", sub, email, name, picture)
7. Backend: Generate JWT, return { token, user }
```

**Token type sent to backend:** Google ID Token (JWT signed by Google)
**Verification:** Google's tokeninfo endpoint validates signature + expiry
**User identifier:** `sub` claim (Google's unique user ID)
**Email provided:** Yes

#### Apple Login (iOS only)

```
1. Client: SignInWithApple → returns Apple Identity Token (JWT)
2. Client: POST /api/v1/auth/apple { token: identityToken, name: "..." }
3. Backend: Parse JWT header, extract kid
4. Backend: GET https://appleid.apple.com/auth/keys (JWKS)
5. Backend: Find matching public key by kid
6. Backend: Verify JWT signature (RS256) with Apple's public key
7. Backend: Verify issuer = "https://appleid.apple.com"
8. Backend: Verify audience = APPLE_CLIENT_ID
9. Backend: Extract sub, email from claims
10. Backend: findOrCreateSocialUser("apple", sub, email, name, "")
11. Backend: Generate JWT, return { token, user }
```

**Token type sent to backend:** Apple Identity Token (JWT signed by Apple's private key)
**Verification:** Fetch Apple JWKS, verify RS256 signature locally
**User identifier:** `sub` claim (Apple's unique user ID)
**Email provided:** Yes (only on first sign-in)
**Name provided:** Only on first sign-in (client sends it)

#### LINE Login

```
1. Client: LineSDK.login() → returns LINE Access Token
2. Client: POST /api/v1/auth/line { token: accessToken, name: "..." }
3. Backend: GET https://api.line.me/oauth2/v2.1/verify?access_token={token}
4. Backend: Verify client_id matches LINE_CHANNEL_ID
5. Backend: GET https://api.line.me/v2/profile (Authorization: Bearer {token})
6. Backend: Extract userId, displayName, pictureUrl
7. Backend: findOrCreateSocialUser("line", userId, "", name, pictureUrl)
8. Backend: Generate JWT, return { token, user }
```

**Token type sent to backend:** LINE Access Token (opaque string)
**Verification:** LINE's verify endpoint checks token validity and issuing channel
**User identifier:** `userId` from LINE profile API
**Email provided:** No (LINE profile API does not return email)

---

## Platform-Specific Login Mechanisms

### Google Sign-In — Why It Works Everywhere (Including Android Emulator)

| Platform | Mechanism |
|----------|-----------|
| iOS | Google Sign-In SDK → system account picker or Safari |
| Android | Google Sign-In SDK → Google Play Services account picker |
| Emulator | Works (Google Play Services available) |

Google Sign-In works on the Android emulator because it **never uses a browser or Chrome Custom Tab**.

```
Google Sign-In Flow on Android:

App Process                  Google Play Services (System Process)
    |                                    |
    |--- 1. startActivityForResult ----->|
    |       (Google Sign-In Intent)      |
    |                                    |
    |       2. Native account picker     |
    |          shown as system dialog    |
    |          (no browser involved)     |
    |                                    |
    |<-- 3. onActivityResult ------------|
    |       (ID Token returned)          |
```

Key differences from LINE:

| Aspect | Google Sign-In | LINE Login (web fallback) |
|--------|---------------|---------------------------|
| Auth UI | Native system dialog (Google Play Services) | Chrome Custom Tab (browser) |
| Token delivery | Activity result (in-process IPC) | URL scheme redirect (`lineauth://`) |
| Browser involved | No | Yes |
| Redirect needed | No | Yes (`lineauth://` blocked by Chrome) |
| Emulator support | Full (Google Play Services pre-installed) | Broken (Chrome security policy) |

Google Play Services is a **system-level service** that runs as a separate process on the device.
It provides the account picker dialog directly — no web page, no browser, no HTTP redirect.
The ID Token is returned via Android's `startActivityForResult` / `onActivityResult` mechanism,
which is in-process IPC (inter-process communication) and completely bypasses the browser.

Even when Google falls back to a web-based flow (rare, when Play Services is outdated),
it uses its own WebView within the Google Sign-In activity — not Chrome Custom Tab.
This WebView handles the OAuth redirect internally without custom scheme issues.

### Apple Sign-In

| Platform | Mechanism |
|----------|-----------|
| iOS | Native AuthenticationServices framework → system dialog |
| Android | Not available (hidden via `Platform.isIOS` check) |

Apple Sign-In also uses a **native system dialog** (AuthenticationServices framework),
similar to Google. No browser or redirect involved. The identity token is returned
directly to the app via the framework's delegate callback.

### LINE Login — The Platform Challenge

| Platform | Mechanism | Status |
|----------|-----------|--------|
| iOS (LINE installed) | App-to-app auth via `line3rdp.{bundleId}://` URL scheme | Working |
| iOS (no LINE) | Safari View Controller → URL scheme redirect | Working |
| Android (LINE installed) | App-to-app auth via LINE app intent | Working (physical device) |
| Android (no LINE) | Chrome Custom Tab → `lineauth://` redirect | **Broken on emulator** |

#### Why LINE Fails on Android Emulator

```
Chrome Custom Tab                          Android System
       |                                        |
       |-- 1. LINE server sends HTTP 302 ------>|
       |       Location: lineauth://authorize   |
       |                                        |
       |-- 2. Chrome BLOCKS custom scheme ----->|  (Security policy)
       |       redirect from HTTP context       |
       |                                        |
       |-- 3. Page stays on consent screen ---->|  (grayed out)
```

Chrome (v80+) blocks HTTP 302 redirects to custom URL schemes for security.
This prevents `lineauth://` from being caught by `LineAuthenticationCallbackActivity`.

**This does NOT affect:**
- Physical devices with LINE app (uses app-to-app auth, no browser involved)
- iOS (Safari View Controller allows custom scheme redirects)
- WebView-based approach (WebView allows custom scheme interception via `shouldOverrideUrlLoading`)

---

## Backend: Account Linking Logic

```
findOrCreateSocialUser(provider, providerID, email, name, avatar)
    |
    |-- 1. SELECT FROM social_accounts WHERE provider = ? AND provider_id = ?
    |       |
    |       +-- Found → Return linked user
    |       |
    |       +-- Not found → Continue
    |
    |-- 2. If email provided:
    |       SELECT FROM users WHERE email = ? AND status = 'active'
    |       |
    |       +-- Found → Link social account to existing user, return user
    |       |
    |       +-- Not found → Continue
    |
    |-- 3. Create new user + social account, return user
```

### Account Linking Matrix

| Scenario | Result |
|----------|--------|
| Same provider + same providerID | Return existing user (repeat login) |
| Different provider + same email | Link to existing user (cross-provider) |
| No matching provider or email | Create new user |
| LINE login (no email) | Always creates new user unless same LINE ID |

---

## Database Schema

### SocialAccount Model

```
social_accounts
├── id          UUID (PK)
├── user_id     UUID (FK → users.id)
├── provider    STRING ("google", "apple", "line")
├── provider_id STRING (provider's unique user ID)
├── email       STRING (may be empty for LINE)
├── name        STRING
├── avatar      STRING
├── created_at  TIMESTAMP
├── updated_at  TIMESTAMP
└── UNIQUE(provider, provider_id)
```

---

## API Endpoints

### POST /api/v1/auth/google

**Request:**
```json
{ "token": "<Google ID Token>", "name": "optional override" }
```

### POST /api/v1/auth/apple

**Request:**
```json
{ "token": "<Apple Identity Token>", "name": "First Last" }
```

### POST /api/v1/auth/line

**Request:**
```json
{ "token": "<LINE Access Token>", "name": "optional override" }
```

### Common Response (all providers)

```json
{
  "success": true,
  "data": {
    "token": "<JWT access token>",
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "Display Name",
      "avatar": "https://...",
      "bio": "",
      "total_likes": 0,
      "status": "active",
      "created_at": "2026-01-30T00:00:00Z",
      "updated_at": "2026-01-30T00:00:00Z"
    }
  }
}
```

---

## Token Verification Summary

| Provider | Token Type | Verification Method | Verified Claims |
|----------|-----------|---------------------|-----------------|
| Google | ID Token (JWT) | Google tokeninfo API | `aud` = GOOGLE_CLIENT_ID |
| Apple | Identity Token (JWT) | Apple JWKS + RSA signature | `iss`, `aud` = APPLE_CLIENT_ID |
| LINE | Access Token (opaque) | LINE verify API | `client_id` = LINE_CHANNEL_ID |

---

## Security Considerations

- **Google:** ID Token is a JWT signed by Google. Backend verifies via Google's endpoint (not locally). Audience check prevents token reuse across apps.
- **Apple:** Identity Token verified locally using Apple's public JWKS keys. RS256 signature ensures token authenticity. Name only sent on first sign-in.
- **LINE:** Access Token is opaque (not JWT). Backend verifies by calling LINE's API. Channel ID check prevents token from other LINE apps. LINE does not provide email — limits account linking.
- **All providers:** Tokens are short-lived and single-use from the mobile client's perspective. Backend generates its own JWT after verification.

---

## Configuration

### Backend .env

```
# JWT
JWT_SECRET=your-jwt-secret
JWT_TTL_HOURS=720

# Google
GOOGLE_CLIENT_ID=...apps.googleusercontent.com

# Apple
APPLE_CLIENT_ID=app.dev.serifu

# LINE
LINE_CHANNEL_ID=2009144840
```

### Mobile .env

```
GOOGLE_CLIENT_ID=...apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=...apps.googleusercontent.com
LINE_CHANNEL_ID=2009144840
APPLE_CLIENT_ID=app.dev.serifu
```

### Platform Configuration

| Platform | Config File | Required Settings |
|----------|------------|-------------------|
| iOS | Info.plist | URL scheme: `line3rdp.app.dev.serifu`, Queries: `lineauth2`, Google URL scheme |
| Android | AndroidManifest.xml | No additional config needed (LINE SDK registers its own activities) |
| LINE Console | developers.line.biz | Package name: `app.dev.serifu`, iOS bundle ID: `app.dev.serifu`, Package signature |

---

## Future: Migrating LINE to Server-Side OAuth (Approach B)

To fix LINE login on Android emulator, the backend would need:

### New Backend Endpoints

```
GET  /api/v1/auth/line/url       → Generate LINE OAuth authorization URL
GET  /api/v1/auth/line/callback  → Handle LINE redirect, exchange code for token
```

### Flow

```
1. Mobile: GET /auth/line/url
2. Backend: Build URL: https://access.line.me/oauth2/v2.1/authorize
     ?response_type=code
     &client_id={LINE_CHANNEL_ID}
     &redirect_uri={BACKEND_URL}/auth/line/callback
     &state={random}
     &scope=profile%20openid
3. Backend: Return { url, state }
4. Mobile: Open URL in WebView
5. User authenticates on LINE web
6. LINE redirects to backend callback with ?code=xxx&state=yyy
7. Backend: POST https://api.line.me/oauth2/v2.1/token
     { grant_type: authorization_code, code, redirect_uri, client_id, client_secret }
8. Backend: Receive access_token, verify, get profile
9. Backend: findOrCreateSocialUser, generate JWT
10. Backend: Redirect to mobile deep link or return via WebView message
```

### Required Backend .env additions

```
LINE_CHANNEL_SECRET=...
LINE_REDIRECT_URL=http://10.0.2.2:8080/api/v1/auth/line/callback
```

This approach matches how ChatShare handles LINE login and works reliably on all platforms including Android emulator.
