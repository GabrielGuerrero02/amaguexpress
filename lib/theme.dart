import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amaguexpress/constants/constants.dart';

ThemeData lightThemeData(BuildContext context) {
  return ThemeData.light().copyWith(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: appBarTheme,
    iconTheme: const IconThemeData(color: kContentColorLightTheme),
    textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
        .apply(bodyColor: kContentColorLightTheme, fontSizeFactor: 0.8),
    colorScheme: const ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      error: kErrorColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kContentColorLightTheme.withValues(alpha: (0.7 * 255)),
      unselectedItemColor:
          kContentColorLightTheme.withValues(alpha: (0.32 * 255)),
      selectedIconTheme: const IconThemeData(color: kPrimaryColor),
      showUnselectedLabels: true,
    ),
  );
}

ThemeData darkThemeData(BuildContext context) {
  final base = ThemeData.dark();

  return base.copyWith(
    primaryColor: kPrimaryColor,
    // Fondo oscuro moderno
    scaffoldBackgroundColor: const Color(0xFF121212),
    // AppBar con buen contraste
    appBarTheme: appBarTheme.copyWith(
      backgroundColor: const Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    // Íconos claros sobre fondo oscuro
    iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
    // Tipografías legibles en oscuro
    textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
        .apply(bodyColor: const Color(0xFFE0E0E0), fontSizeFactor: 0.8),
    // Esquema de colores coherente en oscuro
    colorScheme: base.colorScheme.copyWith(
      primary: kPrimaryColor,
      secondary: kSecondaryColor,
      error: kErrorColor,
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      onSurface: const Color(0xFFE0E0E0),
      onPrimary: Colors.white,
    ),
    // Tarjetas/paneles con superficie más clara que el fondo
    cardColor: const Color(0xFF1E1E1E),
    // Bottom bar con mejor contraste y acentos
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Color(0xFF9E9E9E),
      selectedIconTheme: IconThemeData(color: kPrimaryColor),
      showUnselectedLabels: true,
    ),
    // Divisores sutiles
    dividerColor: const Color(0xFF2C2C2C),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF1E1E1E),
      textStyle: TextStyle(color: Color(0xFFE0E0E0)),
    ),
  );
}

const appBarTheme = AppBarTheme(centerTitle: true, elevation: 0);
