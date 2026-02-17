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
      secondary: Color.fromARGB(255, 36, 32, 32),
      error: kErrorColor,
    ),
    // Inputs: borde naranja en focus también en tema claro
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: Color.fromARGB(255, 170, 169, 169)),
      labelStyle: const TextStyle(color: Color.fromARGB(255, 147, 146, 146)),
      floatingLabelStyle: const TextStyle(color: kPrimaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kErrorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kErrorColor, width: 1.6),
      ),
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
      foregroundColor: const Color(0xFFE0E0E0),
      elevation: 0,
    ),
    // Íconos claros sobre fondo oscuro
    iconTheme: const IconThemeData(color: Color(0xFFE0E0E0)),
    // Tipografías legibles en oscuro
    textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
      bodyColor: const Color(0xFFE0E0E0),
      displayColor: const Color(0xFFE0E0E0),
      fontSizeFactor: 0.8,
    ),
    // Esquema de colores coherente en oscuro
    colorScheme: base.colorScheme.copyWith(
      primary: kPrimaryColor,
      secondary: const Color.fromARGB(255, 45, 41, 41),
      error: const Color.fromARGB(255, 202, 106, 106),
      surface: const Color(0xFF1E1E1E),
      background: const Color(0xFF121212),
      onSurface: const Color(0xFFE0E0E0),
      onPrimary: Colors.white,
    ),
    // Inputs: fondo oscuro (relleno) y bordes coherentes para que el texto blanco sea legible
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1F1F1F),
      hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
      labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
      floatingLabelStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      prefixStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      suffixStyle: const TextStyle(color: Color(0xFFE0E0E0)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimaryColor, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kErrorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kErrorColor, width: 1.6),
      ),
    ),
    // Tarjetas/paneles con superficie más clara que el fondo
    cardColor: const Color(0xFF1E1E1E),
    // Bottom bar con mejor contraste y acentos
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Color.fromARGB(255, 180, 178, 178),
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
