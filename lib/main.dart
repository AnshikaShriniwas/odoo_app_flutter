import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zehntech Housing Society',
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
  double _progress = 0;

  static const String _url =
      "https://runbot299.odoo.com/runbot/static/build/110373506-19-0/logs/build/html/";
  // "https://110373505-19-0-design-theme.runbot256.odoo.com/";
  // "https://110376268-saas-19-1-all.runbot176.odoo.com/";
  // "https://110373502-19-0-all.runbot104.odoo.com/odoo"; //   'https://apps.odoo.com/apps/modules/19.0/zehntech_housing_society_management';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF714B67),
          title: const Text(
            'Zehntech Housing Society',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _webViewController?.reload(),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : null,
        ),
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
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() => _isLoading = true);
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
                setState(() => _progress = progress / 100);
              },
              onReceivedError: (controller, request, error) {
                setState(() => _isLoading = false);
              },
            ),
            // if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
