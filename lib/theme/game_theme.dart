import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tema del juego con estilos mejorados y efectos visuales
class GameTheme {
  /// Colores principales del juego
  static const Color primaryColor = Color(0xFFFF7F00);
  static const Color primaryDarkColor = Color(0xFFFF5722);
  static const Color accentColor = Color(0xFFFFC107);
  static const Color secondaryColor = Color(0xFF2196F3);

  /// Colores para rareza de cartas
  static const Color commonColor = Color(0xFF8E8E8E);
  static const Color uncommonColor = Color(0xFF2E7D32);
  static const Color rareColor = Color(0xFF1976D2);
  static const Color superRareColor = Color(0xFF9C27B0);
  static const Color legendaryColor = Color(0xFFFFD700);

  /// Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, primaryDarkColor],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, Color(0xFFFF9800)],
  );

  static const LinearGradient legendaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
  );

  // Tema Material para la aplicación
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: accentColor,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      fontFamily: 'Roboto',
      useMaterial3: true,

      // AppBar mejorado
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        shadowColor: Colors.black38,
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24, width: 2),
          ),
        ),
      ),

      // Tarjetas con efecto 3D
      cardTheme: CardTheme(
        elevation: 6,
        shadowColor: Colors.black38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: Colors.white,
        clipBehavior: Clip.antiAlias,
      ),

      // Iconos brillantes
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),

      // Textos
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Color(0xFF212121),
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.25,
          color: Color(0xFF212121),
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.15,
          color: Color(0xFF212121),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          letterSpacing: 0.5,
          color: Color(0xFF424242),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          letterSpacing: 0.25,
          color: Color(0xFF424242),
        ),
      ),

      // Diálogos y modales
      dialogTheme: DialogTheme(
        elevation: 16,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Tema oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: accentColor,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: 'Roboto',
      useMaterial3: true,

      // AppBar mejorado
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        backgroundColor: primaryDarkColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        shadowColor: Colors.black54,
      ),

      // Botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryDarkColor,
          elevation: 8,
          shadowColor: primaryDarkColor.withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.white24, width: 2),
          ),
        ),
      ),

      // Tarjetas con efecto 3D
      cardTheme: CardTheme(
        elevation: 8,
        shadowColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        surfaceTintColor: const Color(0xFF2C2C2C),
        clipBehavior: Clip.antiAlias,
      ),

      // Iconos brillantes
      iconTheme: const IconThemeData(
        color: accentColor,
        size: 24,
      ),

      // Textos
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.25,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.15,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          letterSpacing: 0.5,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          letterSpacing: 0.25,
          color: Colors.white70,
        ),
      ),

      // Diálogos y modales
      dialogTheme: DialogTheme(
        elevation: 16,
        backgroundColor: const Color(0xFF212121),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// Estilos reutilizables para widgets del juego
class GameStyles {
  // Decoración para contenedores con apariencia metálica
  static BoxDecoration metallicContainer = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFE0E0E0), Color(0xFFC0C0C0), Color(0xFFD8D8D8)],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
      const BoxShadow(
        color: Colors.white54,
        blurRadius: 4,
        offset: Offset(-2, -2),
      ),
    ],
    border: Border.all(color: Colors.white38, width: 2),
  );

  // Decoración para paneles de cristal
  static BoxDecoration glassPanel({Color baseColor = Colors.blue}) {
    return BoxDecoration(
      color: baseColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: baseColor.withOpacity(0.2),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    );
  }

  // Decoración para botones de juego
  static BoxDecoration gameButton = BoxDecoration(
    gradient: GameTheme.primaryGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: GameTheme.primaryColor.withOpacity(0.5),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
    border: Border.all(color: Colors.white38, width: 2),
  );

  // Estilo de texto para títulos de juego
  static TextStyle gameTitle = const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.5,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: Offset(2, 2),
        blurRadius: 3.0,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
    ],
  );

  // Estilo de texto para subtítulos
  static TextStyle gameSubtitle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 2.0,
        color: Color.fromARGB(180, 0, 0, 0),
      ),
    ],
  );
}

/// Clase para efectos de animación
class GameEffects {
  // Duración común para animaciones rápidas
  static const Duration fast = Duration(milliseconds: 200);

  // Duración común para animaciones medias
  static const Duration medium = Duration(milliseconds: 500);

  // Duración común para animaciones lentas
  static const Duration slow = Duration(milliseconds: 800);

  // Curva para animaciones de cartas
  static const Curve cardCurve = Curves.easeOutBack;

  // Curva para botones
  static const Curve buttonCurve = Curves.elasticOut;

  // Curva para transiciones suaves
  static const Curve easeInOut = Curves.easeInOutCubic;
}
