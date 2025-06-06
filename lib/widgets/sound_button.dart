import 'package:flutter/material.dart';
import '../utils/audio_service.dart';

class SoundButton extends StatelessWidget {
  final Widget child;
  final Future<void> Function()? onPressed;
  final ButtonStyle? style;
  final bool enabled;

  const SoundButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.style,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled
          ? () async {
              final audioService = AudioService();
              // Reproducir el sonido sin esperar que termine
              audioService.playButtonClickSound();
              // Ejecutar la acción del botón si existe
              if (onPressed != null) {
                await onPressed!();
              }
            }
          : null,
      style: style,
      child: child,
    );
  }
}
