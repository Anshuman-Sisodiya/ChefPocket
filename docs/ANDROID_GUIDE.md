# 🤖 ChefPocket Android Developer & User Guide

## 1. Technical Overview
ChefPocket for Android is built with **100% native Jetpack Compose and Material Design 3**. It offers zero-compromise feature and design parity with the iOS version while adhering to Google's Android standards and Material 3 design tokens.

- **Package Name**: `com.chefpocket.app`
- **Minimum SDK**: API 21 (Android 5.0 Lollipop)
- **Target SDK**: API 34 (Android 14)
- **Architecture**: Unidirectional Data Flow (UDF) with MVVM
- **Language**: Kotlin 1.9.24
- **UI Framework**: Jetpack Compose with Material 3 (1.2.1)
- **Networking**: OkHttp 4.12.0 + Kotlin Coroutines

---

## 2. Key Android Features

### 2.1 System Share Sheet Target (`ACTION_SEND`)
When watching a cooking video on **YouTube Shorts** or **Instagram Reels**, tap the system **Share** button and select **ChefPocket**.
- `MainActivity` intercepts the shared text via `Intent.ACTION_SEND`.
- Extracts the canonical URL and triggers the AI Recipe Extractor modal.

### 2.2 Deep Link Support
ChefPocket handles the custom deep-link scheme:
```
chefpocket://import?url=https://youtube.com/shorts/...
```

### 2.3 Countertop Cook Mode Screen Lock
During Countertop Cook Mode, the screen is prevented from sleeping by setting `FLAG_KEEP_SCREEN_ON` on the window:
```kotlin
activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
```
When exiting Cook Mode, the flag is cleared automatically to preserve battery life.

---

## 3. Installation & Sideloading

### 3.1 Direct APK Installation
1. Download the latest compiled APK (`ChefPocket.apk`) from [GitHub Releases](https://github.com/Anshuman-Sisodiya/ChefPocket/releases).
2. Open the downloaded APK on your Android device.
3. If prompted to allow installation from unknown sources, toggle **Allow from this source**.

### 3.2 Bypassing the Play Protect Warning
Because ChefPocket is an open-source sideloaded APK signed with an independent developer key (rather than distributed through the Google Play Store), Google Play Protect may display a warning:
> *"Harmful app blocked: This app is fake"*

**To install immediately:**
1. Tap **"More details" ∨** on the warning dialog.
2. Tap **"Install anyway"**.
3. The app will install cleanly and run at full native performance.

---

## 4. MIUI / Xiaomi / Redmi Compatibility
Older and current versions of Xiaomi MIUI / HyperOS Package Installer crash with `android.view.InflateException` when external sideloaded APKs use vector XML drawables inside `<adaptive-icon>`.

**How ChefPocket resolves this:**
1. **Multi-Density PNG Mipmaps**: Icons are provided as pre-rasterized PNG bitmaps across `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, and `xxxhdpi`.
2. **Omission of anydpi-v26 Vector Drawables**: Eliminates the out-of-process inflater crash in Xiaomi's `miui.os.PackageInstaller`.
3. **Dual V1 + V2/V3 APK Signing**: By setting `minSdk = 21`, Android Gradle Plugin (AGP) unconditionally generates both legacy JAR signatures (V1) and modern APK Signature Schemes (V2 & V3), ensuring full compatibility with MIUI's installer verification daemon.

---

## 5. Google Play Protect Security & False-Positive Hardening

ChefPocket has been strictly hardened against all common automated security heuristics:

| Security Parameter | Configuration | Purpose |
| :--- | :--- | :--- |
| **Startup Clipboard Access** | **Completely Removed** | Play Protect flags apps reading `ClipboardManager` in `onCreate()` as clipboard-stealing trojans. Link imports now strictly use user paste or the Android Share Sheet. |
| **Cleartext Traffic** | `usesCleartextTraffic="false"` | Prohibits unencrypted HTTP traffic. All network requests use TLS 1.3/HTTPS. |
| **Network Security Config** | `network_security_config.xml` | Enforces certificate pinning and system CA trust. |
| **User-Agent** | Clean Android Mobile UA | Replaced spoofed desktop/iOS headers with standard Android client headers. |
| **Permissions** | Minimal (3 permissions) | Only `INTERNET`, `ACCESS_NETWORK_STATE`, and `VIBRATE`. No SMS, Contacts, Storage, Camera, or Accessibility permissions. |
| **Application Backup** | `allowBackup="false"` | Prevents extraction of local recipe stores via ADB backup. |

---

## 6. Official Play Protect Appeal Information

If you maintain a fork or submit a re-scan to Google, use these exact parameters for the [Google Play Protect Appeal Form](https://support.google.com/googleplay/android-developer/contact/protectappeals):

- **Package Name**: `com.chefpocket.app`
- **Application Name**: `ChefPocket`
- **APK SHA-256 Hash**: `459aa624c76939fa7b2fafba525c768e907e3379d1f2701be14ba4eda35e318e`
- **APK Download URL**: `https://github.com/Anshuman-Sisodiya/ChefPocket/releases/download/v1.4.0/ChefPocket.apk`
- **Appeal Description (680 / 1000 characters)**:
```text
Dear Play Protect Team,

Please review a false positive on my open-source recipe app, ChefPocket (com.chefpocket.app).

App Summary:
- ChefPocket is a personal cooking companion, thali planner, and grocery organizer.
- It connects to Google Gemini API (generativelanguage.googleapis.com) to parse user-provided recipe text.
- Open source: https://github.com/Anshuman-Sisodiya/ChefPocket

Security Profile:
1. Permissions: Only INTERNET, ACCESS_NETWORK_STATE, and VIBRATE. No SMS, contacts, camera, or accessibility permissions.
2. Privacy: Zero banking or credential data handled. Recipes are kept strictly on-device.
3. Network: usesCleartextTraffic is false; HTTPS only.
4. Target SDK: 34 (Android 14).

Please whitelist this APK. Thank you.
```

---

## 7. Building from Source

### Prerequisites
- JDK 17 (Eclipse Temurin or OpenJDK)
- Android SDK 34 (`build-tools;34.0.0`, `platforms;android-34`)
- Gradle 8.7+

### Build Commands
```bash
# 1. Navigate to android directory
cd android

# 2. Build release APK
./gradlew :app:assembleRelease

# 3. Output location
# android/app/build/outputs/apk/release/app-release.apk

# 4. Verify APK signatures
apksigner verify --verbose android/app/build/outputs/apk/release/app-release.apk
```
