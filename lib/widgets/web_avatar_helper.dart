import 'package:flutter/material.dart';

import 'web_avatar_helper_stub.dart'
    if (dart.library.html) 'web_avatar_helper_web.dart';

Widget buildWebAvatarWidget({
  required String url,
  required double size,
  required Widget fallback,
}) {
  return getWebAvatarWidget(url: url, size: size, fallback: fallback);
}
