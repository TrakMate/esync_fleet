import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';

class GrafanaPanel extends StatelessWidget {
  final String url;
  final double height;

  GrafanaPanel({super.key, required this.url, this.height = 600}) {
    // Register iframe only once per URL
    ui.platformViewRegistry.registerViewFactory(url, (int viewId) {
      final iframe =
          html.IFrameElement()
            ..src = url
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..allowFullscreen = true;

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: HtmlElementView(viewType: url),
    );
  }
}

String grafanaUrl({
  required int panelId,
  required String imei,
  required bool isDark,
}) {
  return 'https://g.trakmatesolutions.com/d-solo/qVOdvb7Vz/device-details'
      '?panelId=$panelId'
      '&orgId=2'
      '&var-imei=$imei'
      '&theme=${isDark ? 'dark' : 'light'}'
      '&kiosk'
      '&refresh=10s';
}
