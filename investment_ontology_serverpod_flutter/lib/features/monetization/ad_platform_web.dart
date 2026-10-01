import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'ad_config.dart';

@JS('alfinderAds.mount')
external JSPromise<JSBoolean> _mount(
  web.HTMLElement element,
  JSString publisher,
  JSString slot,
  JSBoolean testMode,
);
@JS('alfinderAds.dispose')
external void _dispose(web.HTMLElement element);

class AdPlatform extends StatefulWidget {
  const AdPlatform({
    super.key,
    required this.config,
    required this.onUnavailable,
  });
  final AdConfig config;
  final VoidCallback onUnavailable;
  @override
  State<AdPlatform> createState() => _AdPlatformState();
}

class _AdPlatformState extends State<AdPlatform> {
  web.HTMLElement? _element;
  bool _disposed = false;
  Future<void> _created(Object value) async {
    final element = value as web.HTMLElement;
    _element = element;
    element.style.width = '100%';
    element.style.height = '100px';
    final config = widget.config;
    try {
      final shown = await _mount(
        element,
        config.publisher.toJS,
        config.slot.toJS,
        config.testMode.toJS,
      ).toDart;
      if (!_disposed && !shown.toDart) widget.onUnavailable();
    } catch (_) {
      if (!_disposed) widget.onUnavailable();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final element = _element;
    if (element != null) {
      try {
        _dispose(element);
      } catch (_) {
        element.textContent = '';
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
    tagName: 'div',
    onElementCreated: _created,
  );
}
