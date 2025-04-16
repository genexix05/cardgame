import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  late AudioPlayer _audioPlayer;
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
      debugPrint('Intentando reproducir sonido de botón');
      await _audioPlayer.play(AssetSource(_buttonClickSound));
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

  Future<void> _stopMusicCompletely() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Deteniendo música completamente');
      await _musicPlayer.stop();
      await _musicPlayer.release();
      await Future.delayed(const Duration(milliseconds: 100));
      debugPrint('Música detenida completamente');
    } catch (e) {
      debugPrint('Error al detener música completamente: $e');
      await initialize();
    }
  }

  Future<void> switchToLoadingMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Cambiando a música de carga');
      await _stopMusicCompletely();
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
      await _stopMusicCompletely();
      if (_isAudioEnabled) {
        await playMenuMusic();
      }
    } catch (e) {
      debugPrint('Error al cambiar a música de menú: $e');
      await initialize();
    }
  }

  Future<void> playMenuMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Intentando reproducir música de menú');
      await _musicPlayer.play(AssetSource(_menuMusic), volume: 0.5);
      debugPrint('Música de menú reproducida');
    } catch (e) {
      debugPrint('Error al reproducir música de menú: $e');
      await initialize();
    }
  }

  Future<void> playLoadingMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      debugPrint('Intentando reproducir música de carga');
      await _musicPlayer.play(AssetSource(_loadingMusic), volume: 0.5);
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
    _musicPlayer.dispose();
  }
}
