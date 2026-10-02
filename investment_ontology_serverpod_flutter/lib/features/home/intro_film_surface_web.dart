import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../design/tokens.dart';
import 'intro_film_placeholder.dart';

class FilmSurface extends StatefulWidget {
  const FilmSurface({super.key, required this.progress, required this.reduced});
  final double progress;
  final bool reduced;
  @override
  State<FilmSurface> createState() => _FilmSurfaceState();
}

class _FilmSurfaceState extends State<FilmSurface> {
  web.HTMLVideoElement? _video;
  final _listeners = <String, JSFunction>{};
  final _abort = web.AbortController();
  Timer? _timeout;
  bool _ready = false;
  bool _failed = false;

  void _fail() {
    if (!mounted || _ready || _failed) return;
    setState(() => _failed = true);
  }

  void _checkFrame() {
    final video = _video;
    if (!mounted || video == null || video.seeking || video.readyState < 2) {
      return;
    }
    if (_ready) return;
    _timeout?.cancel();
    setState(() => _ready = true);
  }

  void _listen(
    web.HTMLVideoElement video,
    String event,
    void Function() action,
  ) {
    final listener = ((web.Event _) => action()).toJS;
    _listeners[event] = listener;
    video.addEventListener(event, listener);
  }

  String? _objectUrl;

  Future<void> _loadVideo(web.HTMLVideoElement video) async {
    try {
      final response = await web.window
          .fetch(
            'intro/connected-understanding.mp4'.toJS,
            web.RequestInit(signal: _abort.signal),
          )
          .toDart;
      if (!response.ok) {
        _fail();
        return;
      }
      final blob = await response.blob().toDart;
      if (!mounted) return;
      _objectUrl = web.URL.createObjectURL(blob);
      video.src = _objectUrl!;
    } catch (_) {
      _fail();
    }
  }

  void _seek() {
    final video = _video;
    if (video == null || !video.duration.isFinite || video.duration <= 0) {
      return;
    }
    final target = .05 + (video.duration - .1) * widget.progress;
    if ((video.currentTime - target).abs() > .035) video.currentTime = target;
  }

  @override
  void didUpdateWidget(FilmSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _seek();
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _abort.abort();
    for (final entry in _listeners.entries) {
      _video?.removeEventListener(entry.key, entry.value);
    }
    _video?.pause();
    _video?.removeAttribute('src');
    _video?.load();
    if (_objectUrl != null) web.URL.revokeObjectURL(_objectUrl!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.surface,
    child: Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: HtmlElementView.fromTagName(
            tagName: 'video',
            onElementCreated: (element) {
              final video = element as web.HTMLVideoElement;
              _video = video;
              video.poster = 'intro/poster.jpg';
              video.style.pointerEvents = 'none';
              video.muted = true;
              video.preload = 'auto';
              video.setAttribute('playsinline', '');
              video.setAttribute('aria-label', '흩어진 데이터가 기업 관계망으로 이어지는 영상');
              video.style.width = '100%';
              video.style.height = '100%';
              video.style.objectFit = 'cover';
              _listen(video, 'loadedmetadata', _seek);
              _listen(video, 'loadeddata', _checkFrame);
              _listen(video, 'seeked', _checkFrame);
              _listen(video, 'canplay', _checkFrame);
              _listen(video, 'error', _fail);
              // A slow/blocked download must never leave an endless loading state.
              // If it finishes later, the decoded frame can still replace the poster.
              _timeout = Timer(const Duration(seconds: 30), _fail);
              _loadVideo(video);
            },
          ),
        ),
        if (!_ready)
          IgnorePointer(child: IntroFilmPlaceholder(failed: _failed)),
      ],
    ),
  );
}
