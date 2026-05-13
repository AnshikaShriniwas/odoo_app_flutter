# oaf-001 — Production-Ready WebView with Offline & Error Handling

## Metadata
- **ID**: oaf-001
- **Type**: feature
- **Status**: specification
- **Complexity**: MEDIUM
- **Created**: 2026-05-12
- **Quality Gates**: all-approved

---

## Planning

### Description
The app is a Flutter WebView wrapper around an Odoo URL. Currently it has no internet connectivity handling and no proper URL error screen. When the device is offline or the URL fails to load, the app shows a blank/broken WebView with no feedback to the user.

### Goal
Make the app production-ready by detecting no-internet state (using `flutter_offline`) and URL load errors, showing appropriate screens with a Retry action for both cases. Also add Android back-button WebView history navigation.

### Objectives
- Detect offline state and show a branded "No Internet Connection" screen
- Detect URL load failures (network errors and HTTP errors) and show a "Failed to Load Page" screen
- Provide a Retry button on both error screens
- Handle Android back button to navigate WebView history before exiting
- Add `mounted` guards and `isForMainFrame` checks for correctness

### Deliverables
- `pubspec.yaml` updated with `flutter_offline: ^3.1.0`
- `lib/main.dart` rewritten with `OfflineBuilder`, `_NoInternetScreen`, `_ErrorScreen`, `PopScope`

---

## Specification

### Complexity Score: MEDIUM

### Complexity Rationale
2 files touched. Cross-cutting concern (connectivity affects whole screen lifecycle). New package integration. Multiple new state variables and widget classes. No new routes or data models.

### Code Changes Required
| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | modify | Add `flutter_offline: ^6.0.0` dependency |
| `lib/main.dart` | modify | Add `OfflineBuilder` wrapping, `_hasError` state, `_retry()`, `PopScope`, `_NoInternetScreen`, `_ErrorScreen`; add `onReceivedHttpError`; add `isForMainFrame` guard on error callbacks; add `cacheEnabled: true` to settings |

### Implementation Notes
- `flutter_offline`'s `OfflineBuilder` wraps the entire `OdooWebView` build. When `connectivity == ConnectivityResult.none`, it returns `_NoInternetScreen` (full `Scaffold`); otherwise returns the WebView `child`.
- `debounceDuration: const Duration(seconds: 2)` prevents UI flashing on transient network changes.
- `_hasError` is set to `true` only in `onReceivedError` and `onReceivedHttpError` when `request.isForMainFrame == true`, preventing sub-resource failures from triggering the error screen.
- `_hasError` is reset to `false` in `onLoadStart` to clear stale error state on retry.
- `_retry()` guards with `if (!mounted) return` before `setState` and uses null-safe `?.reload()`.
- `PopScope(canPop: false)` wraps the `OfflineBuilder`. Back button checks `canGoBack()` → goes back in history; else calls `SystemNavigator.pop()` to exit.
- `cacheEnabled: true` added to `InAppWebViewSettings` for better offline-resume behaviour.
- `flutter_offline` re-exports `connectivity_plus`, so `ConnectivityResult` is available from a single import.

---

## Test Cases

### Unit Tests
| # | Test Name | Input / Condition | Expected Result | Status |
|---|-----------|-------------------|-----------------|--------|
| 1 | test_retry_resets_error_state | `_hasError = true`, call `_retry()` | `_hasError == false`, `_isLoading == true` | pending |
| 2 | test_retry_with_null_controller | `_webViewController == null`, call `_retry()` | No exception thrown | pending |

### Widget Tests
| # | Test Name | Steps | Expected Result | Status |
|---|-----------|-------|-----------------|--------|
| 1 | test_offline_screen_shown | Mock connectivity as `none` | `_NoInternetScreen` renders with wifi-off icon and "No Internet Connection" text | pending |
| 2 | test_error_screen_shown | Set `_hasError = true` | `_ErrorScreen` renders with error icon and "Failed to Load Page" text | pending |
| 3 | test_retry_button_on_error_screen | Error screen visible, tap Retry | `_hasError` resets, WebView body shown | pending |

### Edge Cases
| # | Scenario | Expected Behaviour | Status |
|---|----------|--------------------|--------|
| 1 | Sub-resource (image/ad) load fails | `isForMainFrame == false` → error screen NOT shown, WebView continues | pending |
| 2 | `onReceivedError` fires after widget unmounted | `mounted` guard → `setState` not called, no crash | pending |
| 3 | Back button pressed when offline screen shown | `_webViewController` null → `canGoBack()` false → `SystemNavigator.pop()` exits app | pending |
| 4 | Retry tapped while still offline | `_webViewController?.reload()` is no-op (null-safe); OfflineBuilder auto-transitions when connectivity returns | pending |

### Test Plan for QA Team
> This section is copied verbatim into the PR description.

**Scope**: Offline state detection, URL error handling, retry flow, back button navigation

**Pre-conditions**:
- Install the app on an Android or iOS device
- Have a Wi-Fi or mobile data connection available

**QA Steps**:
1. Launch the app — confirm the Odoo page loads with a progress bar in the AppBar
2. Disable Wi-Fi and mobile data — confirm "No Internet Connection" screen appears within ~2 seconds
3. Re-enable internet — confirm app automatically transitions back to the WebView and reloads
4. With internet on, load the app and then navigate the WebView to any internal page
5. Press Android back button — confirm it navigates back in WebView history, not exit the app
6. Press back until no history remains — confirm the app exits
7. Point the app at an unreachable URL (simulate by blocking the host in DNS) — confirm "Failed to Load Page" screen appears
8. On the error screen, restore connectivity and tap Retry — confirm the page loads again

**Expected Outcomes**:
- No blank/frozen screen in any offline or error state
- Retry always either reloads or is a safe no-op
- Back button navigates history before exiting

**Out of Scope**:
- Deep-link parameter validation (app has no deep links)
- SSL certificate pinning
- Session / authentication handling

---

## Quality Gates

### Gate 1 — Senior Flutter Developer Review
**Date**: 2026-05-12 | **Status**: approved

| # | Severity | Finding | Location in Spec | Resolution |
|---|----------|---------|-----------------|------------|
| 1 | MEDIUM | `PopScope.onPopInvokedWithResult` is `async` — awaiting inside the callback is safe but the callback signature returns `void`. Await of `canGoBack()` is fine because Dart allows `async void` on event handlers. | Implementation Notes | Advisory only — no spec change required |
| — | — | No HIGH/CRITICAL findings | — | — |

**Verdict**: Approved — no HIGH/CRITICAL architecture or layer-coupling issues. MEDIUM advisory noted; pattern is standard for PopScope + WebView back-navigation.

---

### Gate 2 — Security & Performance Consultant Review
**Date**: 2026-05-12 | **Status**: approved

| # | Severity | Category | Finding | Location in Spec | Mitigation |
|---|----------|----------|---------|-----------------|------------|
| 1 | LOW | Performance | `OfflineBuilder` rebuilds `connectivityBuilder` on every parent rebuild until stream emits. `debounceDuration: 2s` mitigates churn. | Implementation Notes | Advisory — no spec change required |
| — | — | — | No HIGH/CRITICAL security or performance issues | — | — |

**Verdict**: Approved — no hardcoded secrets, no insecure storage, all network via HTTPS, no PII in analytics. No HIGH/CRITICAL performance issues; `isForMainFrame` guard and `cacheEnabled` are positive production additions.

---

### Gate 3 — Pre-Development Sweep
**Date**: 2026-05-12 | **Status**: approved

**Part A — Gate 1 & 2 Resolution Confirmation**
| Finding | Status in Spec | Notes |
|---------|---------------|-------|
| G1-1: async void onPopInvokedWithResult | Confirmed advisory — no spec change | Pattern is standard |
| G2-1: OfflineBuilder rebuild cost | Confirmed advisory — debounceDuration mitigates | No spec change needed |

**Part B — Predicted Implementation Bugs**
| # | Severity | Predicted Bug | Spec Location | Action Taken |
|---|----------|--------------|---------------|--------------|
| 1 | HIGH | `onReceivedError` fires for sub-resources (ads, fonts) causing spurious error screen | Implementation Notes | Already covered by `isForMainFrame` guard; confirmed in Edge Case #1 |
| 2 | HIGH | `setState` called after widget disposed when `evaluateJavascript` completes async | Implementation Notes | Already covered by `if (mounted)` guard in `onLoadStop` |
| 3 | MEDIUM | `_hasError` not cleared when user navigates to a new URL after error | Implementation Notes | Cleared in `onLoadStart` callback — Edge Case already implicit in test_retry_resets_error_state |
| 4 | LOW | `_webViewController?.reload()` called when WebView not in tree (offline state) | Implementation Notes | Null-safe `?.reload()` is a no-op — confirmed in Edge Case #4 |

**Verdict**: Approved — all predicted bugs already addressed in spec. 2 edge cases confirmed existing. Spec is implementation-ready.

---

## Done

### Test Results
(pending — to be filled after implementation)

### Summary
(pending)

### Commit / PR
(pending)
