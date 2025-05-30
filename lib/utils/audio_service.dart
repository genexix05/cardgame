import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late AudioPlayer _audioPlayer;
  // Lista de reproductores para sonidos de botón
  final List<AudioPlayer> _buttonAudioPlayers = [];
  int _currentButtonPlayerIndex = 0;
  static const int _maxButtonPlayers =
      3; // Número de reproductores para botones

  late AudioPlayer _musicPlayer;
  bool _isAudioEnabled = true;
  bool _isInitialized = false;

  // URLs de los efectos de sonido
  static const String _buttonClickSound = 'sounds/button_click.mp3';
  static const String _cardRevealSound = 'sounds/card_reveal.mp3';
  static const String _packOpenSound = 'sounds/pack_open.mp3';
  static const String _menuMusic = 'audio/menu_music.mp3';
  static const String _loadingMusic = 'audio/loading_music.mp3';

  bool get isAudioEnabled => _isAudioEnabled;

  // Método directo para iniciar música del menú
  Future<void> startMenuMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Iniciando música del menú directamente');
      await playMenuMusic();
    } catch (e) {
      debugPrint('Error al iniciar música del menú: $e');
    }
  }

  // Método de prueba simple para reproducir música sin fade
  Future<void> testPlayMenuMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('PRUEBA: Reproduciendo música del menú sin fade');
      await _musicPlayer.play(AssetSource(_menuMusic), volume: 0.3);
      debugPrint('PRUEBA: Música del menú iniciada con volumen 0.3');
    } catch (e) {
      debugPrint('PRUEBA: Error al reproducir música del menú: $e');
      debugPrint('PRUEBA: Tipo de error: ${e.runtimeType}');
    }
  }

  Future<void> toggleAudio() async {
    try {
      _isAudioEnabled = !_isAudioEnabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('audio_enabled', _isAudioEnabled);

      if (!_isAudioEnabled) {
        await stopMusic();
      }
    } catch (e) {
      debugPrint('Error al alternar audio: $e');
    }
  }

  Future<void> initialize() async {
    try {
      debugPrint('Iniciando inicialización de AudioService');

      // Inicializar los reproductores primero
      _audioPlayer = AudioPlayer();

      // Inicializar el pool de reproductores para botones
      _buttonAudioPlayers.clear();
      for (int i = 0; i < _maxButtonPlayers; i++) {
        _buttonAudioPlayers.add(AudioPlayer());
      }

      _musicPlayer = AudioPlayer();

      // Configurar el reproductor de música
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);

      // Forzar audio habilitado
      _isAudioEnabled = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('audio_enabled', true);

      _isInitialized = true;
      debugPrint('AudioService inicializado correctamente');
    } catch (e) {
      debugPrint('Error crítico al inicializar AudioService: $e');
      _isInitialized = false;
      // Intentar reinicializar si hay error
      await Future.delayed(const Duration(milliseconds: 100));
      await initialize();
    }
  }

  Future<void> playButtonClickSound() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Usamos el siguiente reproductor disponible del pool
      final currentPlayer = _buttonAudioPlayers[_currentButtonPlayerIndex];

      // Rotamos al siguiente reproductor para la próxima llamada
      _currentButtonPlayerIndex =
          (_currentButtonPlayerIndex + 1) % _maxButtonPlayers;

      debugPrint(
          'Intentando reproducir sonido de botón con player #$_currentButtonPlayerIndex');

      // No usamos await para que no bloquee
      currentPlayer.play(AssetSource(_buttonClickSound));

      debugPrint('Sonido de botón reproducido');
    } catch (e) {
      debugPrint('Error al reproducir sonido de botón: $e');
      // Intentar reinicializar si hay error
      await initialize();
    }
  }

  Future<void> playCardRevealSound() async {
    try {
      debugPrint('Intentando reproducir sonido de carta');
      await _audioPlayer.play(AssetSource(_cardRevealSound));
      debugPrint('Sonido de carta reproducido');
    } catch (e) {
      debugPrint('Error al reproducir sonido de carta: $e');
    }
  }

  Future<void> playPackOpenSound() async {
    try {
      debugPrint('Intentando reproducir sonido de sobre');
      await _audioPlayer.play(AssetSource(_packOpenSound));
      debugPrint('Sonido de sobre reproducido');
    } catch (e) {
      debugPrint('Error al reproducir sonido de sobre: $e');
    }
  }

  Future<void> _fadeOutMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Iniciando fade out de música');

      const int steps = 10;
      const Duration duration = Duration(milliseconds: 500);
      final Duration stepDuration =
          Duration(milliseconds: duration.inMilliseconds ~/ steps);

      // Reducir el volumen gradualmente desde 0.5
      for (var i = steps; i >= 0; i--) {
        final double newVolume = 0.5 * (i / steps);
        await _musicPlayer.setVolume(newVolume);
        await Future.delayed(stepDuration);
      }

      // Detener la música completamente
      await _musicPlayer.stop();
      debugPrint('Fade out de música completado');
    } catch (e) {
      debugPrint('Error en fade out de música: $e');
      await _musicPlayer.stop();
    }
  }

  Future<void> switchToLoadingMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Cambiando a música de carga');
      await _fadeOutMusic();
      await Future.delayed(const Duration(milliseconds: 100));
      if (_isAudioEnabled) {
        await playLoadingMusic();
      }
    } catch (e) {
      debugPrint('Error al cambiar a música de carga: $e');
      await initialize();
    }
  }

  Future<void> switchToMenuMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Cambiando a música de menú');

      // Detener música actual si está reproduciéndose
      try {
        await _musicPlayer.stop();
        debugPrint('Música anterior detenida');
      } catch (e) {
        debugPrint('No había música reproduciéndose: $e');
      }

      await Future.delayed(const Duration(milliseconds: 100));
      // Siempre reproducir música del menú ya que se fuerza audio habilitado en initialize
      await playMenuMusic();
    } catch (e) {
      debugPrint('Error al cambiar a música de menú: $e');
      await initialize();
    }
  }

  Future<void> playMenuMusic() async {
    try {
      if (!_isInitialized) {
        debugPrint('AudioService no inicializado, inicializando...');
        await initialize();
      }
      debugPrint(
          'Intentando reproducir música de menú - Audio habilitado: $_isAudioEnabled');
      debugPrint('Ruta del archivo: $_menuMusic');

      await _musicPlayer.play(AssetSource(_menuMusic), volume: 0.0);
      debugPrint('Archivo de música cargado, iniciando fade in...');

      // Fade in gradual
      const int steps = 10;
      const Duration duration = Duration(milliseconds: 500);
      final Duration stepDuration =
          Duration(milliseconds: duration.inMilliseconds ~/ steps);

      for (var i = 1; i <= steps; i++) {
        final double newVolume = 0.5 * (i / steps);
        await _musicPlayer.setVolume(newVolume);
        await Future.delayed(stepDuration);
      }
      debugPrint(
          'Música de menú reproducida exitosamente con volumen final: 0.5');
    } catch (e) {
      debugPrint('Error al reproducir música de menú: $e');
      debugPrint('Tipo de error: ${e.runtimeType}');
      await initialize();
    }
  }

  Future<void> playLoadingMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Intentando reproducir música de carga');
      await _musicPlayer.play(AssetSource(_loadingMusic), volume: 0.0);
      // Fade in gradual
      const int steps = 10;
      const Duration duration = Duration(milliseconds: 500);
      final Duration stepDuration =
          Duration(milliseconds: duration.inMilliseconds ~/ steps);

      for (var i = 1; i <= steps; i++) {
        final double newVolume = 0.5 * (i / steps);
        await _musicPlayer.setVolume(newVolume);
        await Future.delayed(stepDuration);
      }
      debugPrint('Música de carga reproducida');
    } catch (e) {
      debugPrint('Error al reproducir música de carga: $e');
      await initialize();
    }
  }

  Future<void> stopMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Deteniendo música');
      await _musicPlayer.stop();
      debugPrint('Música detenida');
    } catch (e) {
      debugPrint('Error al detener música: $e');
      await initialize();
    }
  }

  void dispose() {
    _audioPlayer.dispose();
    // Liberar todos los reproductores del pool de botones
    for (final player in _buttonAudioPlayers) {
      player.dispose();
    }
    _musicPlayer.dispose();
  }
}
