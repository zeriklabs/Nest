import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'web_avatar_helper.dart';

Color getAvatarColor(String name) {
  final List<Color> colors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEC4899), // Pink
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFEF4444), // Red
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFF97316), // Orange
    const Color(0xFF06B6D4), // Cyan
  ];
  if (name.trim().isEmpty) return colors[0];
  final int hash = name.trim().codeUnits.fold(0, (prev, elem) => prev + elem);
  return colors[hash % colors.length];
}

Widget buildUserAvatar({
  required String? name,
  required String? photoUrl,
  required double size,
  TextStyle? textStyle,
}) {
  final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'N';
  final firstLetter = displayName[0].toUpperCase();
  final bgColor = getAvatarColor(displayName);

  final Widget fallbackContainer = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: bgColor,
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: Text(
      firstLetter,
      style: textStyle ?? TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: size * 0.4,
      ),
    ),
  );

  String? effectiveUrl = photoUrl?.trim();
  if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
    if (effectiveUrl.contains('googleusercontent.com') && !effectiveUrl.contains('=s')) {
      effectiveUrl = '$effectiveUrl=s200-c';
    }

    if (kIsWeb) {
      return buildWebAvatarWidget(
        url: effectiveUrl,
        size: size,
        fallback: fallbackContainer,
      );
    }

    return ClipOval(
      child: Image.network(
        effectiveUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallbackContainer,
      ),
    );
  }

  return fallbackContainer;
}

class UserAvatar extends StatelessWidget {
  final String? name;
  final String? photoUrl;
  final double size;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = 40.0,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return buildUserAvatar(
      name: name,
      photoUrl: photoUrl,
      size: size,
      textStyle: textStyle,
    );
  }
}
