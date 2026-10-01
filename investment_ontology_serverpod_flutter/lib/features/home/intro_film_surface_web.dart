import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../design/tokens.dart';

class FilmSurface extends StatefulWidget {
  const FilmSurface({super.key, required this.progress, required this.reduced});
  final double progress;
  final bool reduced;
  @override
  State<FilmSurface> createState() => _FilmSurfaceState();
}

class _FilmSurfaceState extends State<FilmSurface> {
  web.HTMLVideoElement? _video;
  JSFunction? _loaded;
  String? _objectUrl;

  Future<void> _loadVideo(web.HTMLVideoElement video) async {
    try {
      final response = await web.window
          .fetch('intro/connected-understanding.mp4'.toJS)
          .toDart;
      if (!response.ok) return;
      final blob = await response.blob().toDart;
      if (!mounted) return;
      _objectUrl = web.URL.createObjectURL(blob);
      video.src = _objectUrl!;
    } catch (_) {
      // Keep the first-frame poster when the video cannot be downloaded.
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
    if (_video != null && _loaded != null) {
      _video!.removeEventListener('loadedmetadata', _loaded);
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
    child: IgnorePointer(
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
          _loaded = ((web.Event event) => _seek()).toJS;
          video.addEventListener('loadedmetadata', _loaded);
          _loadVideo(video);
        },
      ),
    ),
  );
}
