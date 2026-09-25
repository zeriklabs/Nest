import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// Modelo para los temas de la app
class AppThemeData {
  final String name;
  final Color backgroundColor;
  final Color cardColor;
  final Brightness brightness;

  const AppThemeData({
    required this.name,
    required this.backgroundColor,
    required this.cardColor,
    required this.brightness,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'backgroundColor': backgroundColor.value,
    'cardColor': cardColor.value,
    'brightness': brightness.index,
  };
}

// Temas simplificados (Sin variantes)
const AppThemeData darkTheme = AppThemeData(
  name: 'Deep Dark', 
  backgroundColor: Color(0xFF0F0F11), 
  cardColor: Color(0xFF18181B),
  brightness: Brightness.dark,
);

const AppThemeData lightTheme = AppThemeData(
  name: 'Pure White', 
  backgroundColor: Colors.white, 
  cardColor: Color(0xFFFAFAFA), 
  brightness: Brightness.light,
);

// Colores de énfasis disponibles
const appAccentColors = [
  Color(0xFF6366F1), // Indigo (Predeterminado)
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Green
  Color(0xFFF59E0B), // Orange
  Color(0xFFEF4444), // Red
  Color(0xFFEC4899), // Pink
  Color(0xFF8B5CF6), // Purple
  Color(0xFF06B6D4), // Cyan
];

Locale determineInitialLocale() {
  final ui.Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
  if (deviceLocale.languageCode.startsWith('es')) {
    return const Locale('es');
  }
  return const Locale('en');
}
