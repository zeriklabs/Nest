import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget getWebAvatarWidget({
  required String url,
  required double size,
  required Widget fallback,
}) {
  return WebImageAvatar(
    url: url,
    size: size,
    fallback: fallback,
  );
}

class WebImageAvatar extends StatefulWidget {
  final String url;
  final double size;
  final Widget fallback;

  const WebImageAvatar({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  State<WebImageAvatar> createState() => _WebImageAvatarState();
}

class _WebImageAvatarState extends State<WebImageAvatar> {
  late String _viewType;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _registerView();
  }

  @override
  void didUpdateWidget(WebImageAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _hasError = false;
      _registerView();
    }
  }

  void _registerView() {
    final String url = widget.url;
    _viewType = 'avatar-img-${url.hashCode}-${DateTime.now().microsecondsSinceEpoch}';

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '50%'
        ..style.pointerEvents = 'none'
        ..referrerPolicy = 'no-referrer';

      img.onError.listen((event) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });

      return img;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback;
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipOval(
        child: IgnorePointer(
          child: HtmlElementView(viewType: _viewType),
        ),
      ),
    );
  }
}
