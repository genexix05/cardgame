import 'package:flutter/material.dart';
import 'game_theme.dart';

/// Estilos para las pantallas de batalla
class BattleStyles {
  /// Decoración para el campo de batalla
  static BoxDecoration battleFieldDecoration = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF2C5364),
        Color(0xFF203A43),
        Color(0xFF0F2027),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.5),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
    border: Border.all(
      color: Colors.white24,
      width: 2,
    ),
  );

  /// Decoración para el área del jugador
  static BoxDecoration playerAreaDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        GameTheme.primaryColor.withOpacity(0.4),
        GameTheme.primaryDarkColor.withOpacity(0.2),
      ],
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: GameTheme.primaryColor.withOpacity(0.5),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: GameTheme.primaryColor.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  /// Decoración para el área del oponente
  static BoxDecoration opponentAreaDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.red.withOpacity(0.4),
        Colors.redAccent.withOpacity(0.2),
      ],
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.red.withOpacity(0.5),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.red.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  /// Decoración para las acciones de batalla
  static BoxDecoration actionButtonDecoration({bool isActive = true}) {
    return BoxDecoration(
      gradient: isActive
          ? GameTheme.primaryGradient
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.shade700,
                Colors.grey.shade600,
              ],
            ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: isActive
              ? GameTheme.primaryColor.withOpacity(0.5)
              : Colors.black.withOpacity(0.3),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
      border: Border.all(
        color: Colors.white30,
        width: 1.5,
      ),
    );
  }

  /// Decoración para el panel de información de batalla
  static BoxDecoration battleInfoPanelDecoration = BoxDecoration(
    color: Colors.black.withOpacity(0.6),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Colors.white24,
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Estilo para el texto del turno
  static TextStyle turnText = const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 3.0,
        color: Colors.black87,
      ),
    ],
  );

  /// Estilo para el texto de acción
  static TextStyle actionText = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
    shadows: [
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 2.0,
        color: Colors.black54,
      ),
    ],
  );

  /// Animación de daño
  static Widget damageAnimation({
    required Widget child,
    required int damage,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: GameEffects.medium,
          curve: Curves.elasticOut,
          builder: (context, value, _) {
            return Transform.translate(
              offset: Offset(0, -20 * value),
              child: Opacity(
                opacity: 1.0 - value,
                child: Text(
                  '-$damage',
                  style: TextStyle(
                    fontSize: 24 + (value * 10),
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 3,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Animación de carta seleccionada
  static Widget selectedCardAnimation({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.08),
      duration: GameEffects.fast,
      curve: GameEffects.cardCurve,
      builder: (context, value, _) {
        return Transform.scale(
          scale: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: GameTheme.accentColor.withOpacity(0.7),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Estilo para barras de vida
  static BoxDecoration healthBarDecoration({
    required double percentage, // 0.0 a 1.0
  }) {
    // Color basado en el porcentaje de vida
    Color healthColor;
    if (percentage > 0.6) {
      healthColor = Colors.green;
    } else if (percentage > 0.3) {
      healthColor = Colors.orange;
    } else {
      healthColor = Colors.red;
    }

    return BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: Colors.white30,
        width: 1,
      ),
      color: Colors.grey[800],
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Estilo para el relleno de la barra de vida
  static BoxDecoration healthFillDecoration({
    required double percentage, // 0.0 a 1.0
  }) {
    // Color basado en el porcentaje de vida
    Color healthColor;
    if (percentage > 0.6) {
      healthColor = Colors.green;
    } else if (percentage > 0.3) {
      healthColor = Colors.orange;
    } else {
      healthColor = Colors.red;
    }

    return BoxDecoration(
      borderRadius: BorderRadius.circular(5),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          healthColor.withOpacity(0.8),
          healthColor,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: healthColor.withOpacity(0.4),
          blurRadius: 4,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
