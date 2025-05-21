import 'package:flutter/material.dart';
import 'game_theme.dart';

/// Clase que contiene estilos para las cartas del juego
class CardStyles {
  /// Decoración para cartas según su rareza
  static BoxDecoration cardDecoration({
    required String rarity,
    double elevation = 5,
  }) {
    Color borderColor;
    List<Color> gradientColors;

    switch (rarity.toLowerCase()) {
      case 'common':
        borderColor = GameTheme.commonColor;
        gradientColors = [
          GameTheme.commonColor.withOpacity(0.7),
          GameTheme.commonColor.withOpacity(0.2),
        ];
        break;
      case 'uncommon':
        borderColor = GameTheme.uncommonColor;
        gradientColors = [
          GameTheme.uncommonColor.withOpacity(0.7),
          GameTheme.uncommonColor.withOpacity(0.2),
        ];
        break;
      case 'rare':
        borderColor = GameTheme.rareColor;
        gradientColors = [
          GameTheme.rareColor.withOpacity(0.7),
          GameTheme.rareColor.withOpacity(0.2),
        ];
        break;
      case 'super_rare':
        borderColor = GameTheme.superRareColor;
        gradientColors = [
          GameTheme.superRareColor.withOpacity(0.7),
          GameTheme.superRareColor.withOpacity(0.2),
        ];
        break;
      case 'legendary':
        borderColor = GameTheme.legendaryColor;
        gradientColors = [
          const Color(0xFFFFD700),
          const Color(0xFFFFA000),
        ];
        break;
      default:
        borderColor = GameTheme.commonColor;
        gradientColors = [
          GameTheme.commonColor.withOpacity(0.7),
          GameTheme.commonColor.withOpacity(0.2),
        ];
    }

    return BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderColor,
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.5),
          blurRadius: elevation,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ],
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ),
    );
  }

  /// Efecto de brillo para cartas legendarias
  static BoxDecoration legendaryShine = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: GameTheme.legendaryColor,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: GameTheme.legendaryColor.withOpacity(0.6),
        blurRadius: 15,
        spreadRadius: 2,
      ),
    ],
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFFFD700),
        Color(0xFFFFA000),
        Color(0xFFFFD700),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
  );

  /// Estilo para el marco de la carta
  static BoxDecoration cardFrame({Color? color}) {
    return BoxDecoration(
      color: Colors.black.withOpacity(0.7),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: color ?? Colors.white24,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
      ],
    );
  }

  /// Estilo para la tarjeta con efecto 3D
  static Widget card3D({
    required Widget child,
    required String rarity,
    double depth = 3.0,
  }) {
    Color shadowColor;

    switch (rarity.toLowerCase()) {
      case 'common':
        shadowColor = GameTheme.commonColor;
        break;
      case 'uncommon':
        shadowColor = GameTheme.uncommonColor;
        break;
      case 'rare':
        shadowColor = GameTheme.rareColor;
        break;
      case 'super_rare':
        shadowColor = GameTheme.superRareColor;
        break;
      case 'legendary':
        shadowColor = GameTheme.legendaryColor;
        break;
      default:
        shadowColor = GameTheme.commonColor;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.3),
            offset: Offset(depth, depth),
            blurRadius: depth * 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  /// Estilo para la descripción de la carta
  static TextStyle cardDescription = const TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 2.0,
        color: Colors.black54,
      ),
    ],
  );

  /// Estilo para el nombre de la carta
  static TextStyle cardName = const TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 3.0,
        color: Colors.black87,
      ),
    ],
  );

  /// Estilo para las estadísticas de la carta
  static TextStyle cardStats = const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 2.0,
        color: Colors.black87,
      ),
    ],
  );

  /// Container de cristal para información de la carta
  static BoxDecoration glassInfoContainer = BoxDecoration(
    color: Colors.black.withOpacity(0.6),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
    ],
  );
}
