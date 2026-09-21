# 🔒 Security & Privacy Policy

## 1. Core Philosophy: Zero Telemetry, Total Privacy
ChefPocket is designed with a strict **local-first, zero-telemetry architecture**. We believe that your cooking habits, dietary choices, grocery shopping lists, and kitchen routines are deeply personal data.

- **No Third-Party Analytics**: ChefPocket contains zero tracking SDKs (no Google Analytics, no Firebase Analytics, no Facebook SDK, no Mixpanel).
- **No Advertising Networks**: Zero ad SDKs or tracking beacons.
- **Local-First Storage**: All 434 bundled recipes, user-created recipes, favorites, thali plans, and grocery checklists are saved exclusively on your physical device.
- **No Background Data Ingestion**: The app never inspects the clipboard automatically or transmits device identifiers.

---

## 2. Permissions Audit

ChefPocket requests only the absolute minimum permissions required for core culinary features:

### Android (`AndroidManifest.xml`)
| Permission | Level | Reason |
| :--- | :--- | :--- |
| `android.permission.INTERNET` | Normal | Making HTTPS calls to the official Google Gemini API for video recipe formatting. |
| `android.permission.ACCESS_NETWORK_STATE` | Normal | Checking if device has active internet connectivity before attempting AI extraction. |
| `android.permission.VIBRATE` | Normal | Haptic feedback for tactile buttons and cooker whistle completion alerts. |

**Permissions ChefPocket explicitly DOES NOT request:**
- ❌ No Camera (`android.permission.CAMERA`)
- ❌ No Microphone or Audio Recording
- ❌ No Location (`ACCESS_FINE_LOCATION`)
- ❌ No Contacts or Accounts reading
- ❌ No SMS or Call Logs
- ❌ No Storage permissions (`READ_EXTERNAL_STORAGE` / `MANAGE_EXTERNAL_STORAGE`)
- ❌ No Accessibility Service permissions

### iOS
- **Network**: Standard network access for Gemini REST API calls.
- **Haptics**: `UIImpactFeedbackGenerator` for whistle counter and button taps.
- Zero permissions requested in `Info.plist` for Camera, Contacts, Microphone, or Location.

---

## 3. Network Security & API Keys

1. **Strict TLS 1.3 / HTTPS Only**:
   - `android:usesCleartextTraffic="false"` is enforced.
   - All network calls to `generativelanguage.googleapis.com` use encrypted TLS 1.3.
2. **API Key Confidentiality**:
   - Users can optionally provide their own personal Google Gemini API key for unlimited extractions.
   - User keys are stored strictly in private on-device storage (`EncryptedSharedPreferences` / private app sandbox) and are never transmitted to any third-party server.
3. **Backup Protection**:
   - `android:allowBackup="false"` is configured on Android to prevent unauthorized database extraction through ADB backups.
