import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapWebView extends StatelessWidget {
  final WebViewController controller;

  const MapWebView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: controller);
  }
}
