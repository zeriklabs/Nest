import 'dart:ui';
import 'package:flutter/material.dart';
import 'nest_icon.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isSimplified;
  final bool useMaterial3;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isSimplified = false,
    this.useMaterial3 = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> items = [];
    
    if (isSimplified) {
      items.addAll([
        _NavBarItem(
          icon: Icons.home_rounded,
          isSelected: selectedIndex == 0,
          onTap: () => onItemSelected(0),
          compact: true,
          useMaterial3: useMaterial3,
        ),
        _NavBarItem(
          icon: Icons.groups_rounded,
          isSelected: selectedIndex == 2,
          onTap: () => onItemSelected(2),
          compact: true,
          useMaterial3: useMaterial3,
        ),
      ]);
    } else {
      items.addAll([
        _NavBarItem(
          icon: Icons.home_rounded,
          isSelected: selectedIndex == 0,
          onTap: () => onItemSelected(0),
          useMaterial3: useMaterial3,
        ),
        _NavBarItem(
          icon: Icons.format_list_bulleted_rounded,
          isSelected: selectedIndex == 1,
          onTap: () => onItemSelected(1),
          useMaterial3: useMaterial3,
        ),
        _NavBarItem(
          icon: Icons.groups_rounded,
          isSelected: selectedIndex == 2,
          onTap: () => onItemSelected(2),
          useMaterial3: useMaterial3,
        ),
        _NavBarItem(
          icon: Icons.description_rounded,
          isSelected: selectedIndex == 3,
          onTap: () => onItemSelected(3),
          useMaterial3: useMaterial3,
        ),
        _NavBarItem(
          icon: Icons.schedule_outlined,
          isSelected: selectedIndex == 4,
          onTap: () => onItemSelected(4),
          useMaterial3: useMaterial3,
        ),
      ]);
    }

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1C) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: isSimplified ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
        children: isSimplified && items.length >= 2 
          ? [
              items[0],
              const SizedBox(width: 12),
              items[1],
            ]
          : items,
      ),
    );
  }
}


class _NavBarItem extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;
  final bool useMaterial3;

  const _NavBarItem({
    this.icon,
    this.customIcon,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
    this.useMaterial3 = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    final primaryAccent = colorScheme.primary;
    final secondaryAccent = colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: (useMaterial3 && isSelected) ? (compact ? 20 : 24) : (compact ? 10 : 14),
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: (useMaterial3 && isSelected) 
            ? primaryAccent.withOpacity(isDark ? 0.15 : 0.1) 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: customIcon ?? (isSelected
          ? ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  secondaryAccent,
                  primaryAccent,
                ],
              ).createShader(bounds),
              child: Icon(
                icon,
                color: Colors.white,
                size: compact ? 26 : 28,
              ),
            )
          : Icon(
              icon,
              color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
              size: compact ? 26 : 28,
            )),
      ),
    );
  }
}

