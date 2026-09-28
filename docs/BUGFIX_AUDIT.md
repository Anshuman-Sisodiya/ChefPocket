# September 2026 repair audit

## Changes

### iOS

- Added the supplied dark artwork as an appearance variant of the primary app icon, and retained the alternate icon for app-specific appearance choices and older iOS releases. Xcode 16+ is required to compile the appearance asset correctly. iOS Home Screen icon preferences can override automatic light/dark behavior.
- Recheck appearance when the app becomes active and when appearance settings change.
- Replaced direct client Gemini calls with the shared import service; observe loading state, prevent concurrent requests, show service errors, and store import access in Keychain.
- Shared/deep links and clipboard imports now open the import form rather than silently discarding errors. Share-extension URLs use query-item encoding so nested `&` parameters survive.
- Recipe details start at their actual serving count. Grocery/share ingredient quantities scale; per-serving nutrition remains per serving.
- Cooking timers use a deadline and resume correctly after leaving the screen. These remain foreground timers, without background notification delivery.
- Fixed randomized `hashValue` backup identifiers and filtered deleted recipes during backup merging. Corrected text that claimed authenticated Google synchronization. Real Google login and verified cloud delivery remain unimplemented.

### Android

- Added manual recipe creation with validation, profile/diet settings, system/light/dark appearance selection, and the existing iOS translation dictionaries for matching interface labels. Recipes and newly added/unmatched labels remain in English.
- Added native file backup export and restore for the Android format, including recipes, favorites, groceries, and thali. Restore merges; it does not erase the current kitchen. iOS and Android full backup formats are not interchangeable yet.
- Added actual serving counts and fractional ingredient scaling, including grocery exports. Nutrition displays per-serving values.
- Added all six selectable thali slots, clearing slots, dietary filtering for automatic selection, and thali grocery export.
- Added recipe selection for cooking, timer presets/pause/resume/reset, a resettable whistle counter, and keeping the screen awake while cooking. Android timer state survives rotation through the ViewModel, but not process death.
- Cookbook controls scroll with an adaptive grid. Macro rows wrap. Import/manual/settings dialogs constrain tablet width and account for the keyboard. System Back returns from cooking/details.
- Fixed Kotlin defaults bypassed by Gson, deleted bundled recipes reappearing, case-sensitive video-ID deduplication, and duplicate grocery entries with matching units. Random selection respects an empty requested scope. Search includes tags.
- Imports use the same backend and show actionable errors; Android cancels its HTTP request when its coroutine is cancelled.
- Debug builds use a separate `.debug` application ID and normal debug signing, so testing does not require replacing the installed release app. Android 6/API 23 is the new minimum for secure Keystore access-token storage.

## Verification

- Android debug APK compiles.
- Android regression tests cover legacy/null defaults, serving calculations, invalid ingredient quantities, and video URL identity.
- Android lint has no errors. Existing dependency/target-SDK, manifest, and style warnings remain; target SDK modernization requires release testing.
- Backend tests cover URL allowlisting, redirect rejection, caption parsing, recipe validation, retry limits, provider fallback, native YouTube media input, authentication and rate limits.
- No real provider calls were made: credentials have not been supplied.
- No Android device/emulator is connected; layout and gesture behavior still need device testing.
- iOS has not been compiled in this Windows environment. Use the Xcode 16+ workflow or a Mac and test Home Screen appearance on a device. The share extension's existing responder-chain app-opening approach also needs device verification.

## Release work still required

1. Host the service over HTTPS and configure paid/appropriately provisioned provider access. See [import setup](IMPORT_SERVICE.md).
2. Provide real account authentication and cloud synchronization across platforms. Do not treat local email entry as authentication.
3. Test iOS on a Mac/device, and Android on small/large screens, landscape, large font sizes, and both appearances.
4. Finish localization of remaining interface text and decide whether cross-platform backup compatibility is required.
5. Review the existing tracked Android release keystore and hardcoded signing passwords before distribution. They were already in the repository; this change does not rotate the release signing identity or remove existing installations' update path.
