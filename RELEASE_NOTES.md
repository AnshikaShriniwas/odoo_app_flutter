# Release Notes — Zehntech Housing Society (odoo_app_flutter)

## [Unreleased]

### Features
- **oaf-001**: Added offline detection via `flutter_offline` — shows branded "No Internet Connection" screen with auto-recovery when connectivity returns
- **oaf-001**: Added URL error screen ("Failed to Load Page") with Retry for network and HTTP errors on the main frame
- **oaf-001**: Added Android back-button WebView history navigation — goes back in page history before exiting the app

### Internal
- **oaf-001**: Upgraded `connectivityBuilder` to `List<ConnectivityResult>` API (`flutter_offline` v6)
- **oaf-001**: Added `cacheEnabled: true` to `InAppWebViewSettings` for better resume behaviour
- **oaf-001**: Added `mounted` guards and `isForMainFrame` checks to all WebView error callbacks

---

## [1.0.0+1] — Initial release
