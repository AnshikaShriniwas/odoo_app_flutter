import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_offline/flutter_offline.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Housing Society',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF714B67)),
        useMaterial3: true,
      ),
      home: const OdooWebView(),
    );
  }
}

class OdooWebView extends StatefulWidget {
  const OdooWebView({super.key});

  @override
  State<OdooWebView> createState() => _OdooWebViewState();
}

class _OdooWebViewState extends State<OdooWebView> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _hasError = false;
  double _progress = 0;

  static const String _url =
      "https://odoo-ojetrsqik87.forge.zehntech.com/web/login?redirect=%2Fodoo%3F"; // Actual URL
  // "https://110447128-19-0-all.runbot160.odoo.com/web/login";
  // "https://runbot299.odoo.com/runbot/static/build/110373506-19-0/logs/build/html/";
  // "https://110373505-19-0-design-theme.runbot256.odoo.com/";
  // "https://110376268-saas-19-1-all.runbot176.odoo.com/";
  // "https://110373502-19-0-all.runbot104.odoo.com/odoo"; //   'https://apps.odoo.com/apps/modules/19.0/zehntech_housing_society_management';

  void _retry() {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _webViewController?.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        if (await _webViewController?.canGoBack() ?? false) {
          _webViewController?.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: OfflineBuilder(
        debounceDuration: const Duration(seconds: 2),
        connectivityBuilder: (context, connectivity, child) {
          final isOffline = connectivity.every(
            (r) => r == ConnectivityResult.none,
          );
          if (isOffline) {
            return _NoInternetScreen(onRetry: _retry);
          }
          return child;
        },
        child: SafeArea(
          child: Scaffold(
            // appBar: AppBar(
            //   backgroundColor: const Color(0xFF714B67),
            //   title: const Text(
            //     'Zehntech Housing Society',
            //     style: TextStyle(color: Colors.white, fontSize: 18),
            //   ),
            //   actions: [
            //     IconButton(
            //       icon: const Icon(Icons.refresh, color: Colors.white),
            //       onPressed: _retry,
            //     ),
            //   ],
            //   bottom: _isLoading
            //       ? PreferredSize(
            //           preferredSize: const Size.fromHeight(3),
            //           child: LinearProgressIndicator(
            //             value: _progress,
            //             backgroundColor: Colors.white24,
            //             valueColor: const AlwaysStoppedAnimation<Color>(
            //               Colors.white,
            //             ),
            //           ),
            //         )
            //       : null,
            // ),
            body: Stack(
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_url)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    useHybridComposition: true,
                    mediaPlaybackRequiresUserGesture: false,
                    allowsInlineMediaPlayback: true,
                    supportZoom: false,
                    builtInZoomControls: false,
                    displayZoomControls: false,
                    minimumZoomScale: 1.0,
                    maximumZoomScale: 1.0,
                    textZoom: 100,
                    cacheEnabled: true,
                  ),
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    if (mounted) {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                      });
                    }
                  },
                  onLoadStop: (controller, url) async {
                    await controller.evaluateJavascript(
                      source: '''
                        (function() {
                          var meta = document.querySelector('meta[name="viewport"]');
                          if (meta) {
                            meta.content = meta.content
                              .replace(/user-scalable=[^,]*/gi, '')
                              .replace(/maximum-scale=[^,]*/gi, '')
                              .replace(/minimum-scale=[^,]*/gi, '')
                              .replace(/,\\s*,/g, ',')
                              .replace(/^,|,\$/g, '')
                              .trim();
                            meta.content += ', user-scalable=no, maximum-scale=1.0, minimum-scale=1.0';
                          } else {
                            var newMeta = document.createElement('meta');
                            newMeta.name = 'viewport';
                            newMeta.content = 'width=device-width, initial-scale=1.0, user-scalable=no, maximum-scale=1.0, minimum-scale=1.0';
                            document.head.appendChild(newMeta);
                          }
                        })();
                        ''',
                    );
                    if (mounted) setState(() => _isLoading = false);
                  },
                  onProgressChanged: (controller, progress) {
                    if (mounted) setState(() => _progress = progress / 100);
                  },
                  onReceivedError: (controller, request, error) {
                    if (request.isForMainFrame == true && mounted) {
                      setState(() {
                        _isLoading = false;
                        _hasError = true;
                      });
                    }
                  },
                  onReceivedHttpError: (controller, request, response) {
                    if (request.isForMainFrame == true && mounted) {
                      setState(() {
                        _isLoading = false;
                        _hasError = true;
                      });
                    }
                  },
                ),
                if (_hasError) _ErrorScreen(onRetry: _retry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoInternetScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _NoInternetScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                const Text(
                  'No Internet Connection',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please check your network and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF714B67),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'Failed to Load Page',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong.\nPlease try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF714B67),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
