import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal();

  // Bandera para controlar si el audio debe estar desactivado
  static bool _disableAudio = false;

  // Indicador de inicialización
  bool _initialized = false;

  // Jugadores de audio
  AudioPlayer? _packOpenPlayer;
  AudioPlayer? _cardRevealPlayer;

  // Método para inicializar los efectos de sonido
  Future<void> initialize() async {
    // Si el audio ya está desactivado o ya está inicializado, no hacer nada
    if (_disableAudio || _initialized) return;

    try {
      // Crear instancias de AudioPlayer solo si aún no existen
      _packOpenPlayer ??= AudioPlayer();
      _cardRevealPlayer ??= AudioPlayer();

      // Intenta configurar volumen bajo para reducir problemas
      await _packOpenPlayer?.setVolume(0.3);
      await _cardRevealPlayer?.setVolume(0.3);

      try {
        // Intentar cargar los efectos de sonido
        await _packOpenPlayer?.setAsset('assets/sounds/pack_open.mp3');
        await _cardRevealPlayer?.setAsset('assets/sounds/card_reveal.mp3');
        _initialized = true;

        // Log solo en depuración
        if (kDebugMode) {
          print('Audio inicializado correctamente');
        }
      } catch (e) {
        // Error al cargar archivos de sonido
        if (kDebugMode) {
          print('Error al cargar archivos de sonido: $e');
        }

        // Desactivar audio completamente para evitar más intentos
        disableAudio();
      }
    } catch (e) {
      // Error general de inicialización
      if (kDebugMode) {
        print('Error al inicializar efectos de sonido: $e');
      }

      // Desactivar audio completamente
      disableAudio();
    }
  }

  // Método para reproducir el sonido de apertura de sobre
  Future<void> playPackOpenSound() async {
    if (_disableAudio || !_initialized || _packOpenPlayer == null) return;

    try {
      await _packOpenPlayer?.seek(Duration.zero);
      await _packOpenPlayer?.play();
    } catch (e) {
      if (kDebugMode) {
        print('Error al reproducir sonido de apertura: $e');
      }

      // Si hay error al reproducir, desactivar audio
      disableAudio();
    }
  }

  // Método para reproducir el sonido de revelación de carta
  Future<void> playCardRevealSound() async {
    if (_disableAudio || !_initialized || _cardRevealPlayer == null) return;

    try {
      await _cardRevealPlayer?.seek(Duration.zero);
      await _cardRevealPlayer?.play();
    } catch (e) {
      if (kDebugMode) {
        print('Error al reproducir sonido de revelación: $e');
      }

      // Si hay error al reproducir, desactivar audio
      disableAudio();
    }
  }

  // Método para liberar recursos de audio
  void disposeAudio() {
    try {
      _packOpenPlayer?.dispose();
      _cardRevealPlayer?.dispose();

      // Establecer a null para permitir liberación de memoria
      _packOpenPlayer = null;
      _cardRevealPlayer = null;

      _initialized = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error al liberar recursos de audio: $e');
      }
    }
  }

  // Método para habilitar el audio
  static void enableAudio() {
    _disableAudio = false;
  }

  // Método mejorado para desactivar el audio completamente
  static void disableAudio() {
    _disableAudio = true;

    // Asegurar que los recursos se liberen inmediatamente
    _instance.disposeAudio();

    // Importante: también establecer _initialized = false para evitar reintentos
    _instance._initialized = false;
  }

  // Método para verificar si el audio está habilitado
  bool get isAudioEnabled => !_disableAudio && _initialized;
}
