// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/widgets.dart';

class WebHelper {
  static html.EventListener? _listener;

  static void registerViewFactory(String viewId, String src) {
    ui_web.platformViewRegistry.registerViewFactory(
      viewId,
      (int id) => html.IFrameElement()
        ..src = src
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  static void setupMessageListener({
    required VoidCallback onGoogleSignIn,
    required VoidCallback onViewDemo,
    required VoidCallback onSupport,
  }) {
    _listener = (html.Event event) {
      if (event is html.MessageEvent) {
        if (event.data == 'google-signin') {
          onGoogleSignIn();
        } else if (event.data == 'view-demo') {
          onViewDemo();
        } else if (event.data == 'support') {
          onSupport();
        }
      }
    };
    html.window.addEventListener('message', _listener!);
  }

  static void disposeMessageListener() {
    if (_listener != null) {
      html.window.removeEventListener('message', _listener!);
      _listener = null;
    }
  }
}
