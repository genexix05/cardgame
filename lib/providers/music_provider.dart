import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

class MusicProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _volume = 1.0;

  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  Future<void> playMenuMusic() async {
    try {
      await _audioPlayer.setAsset('assets/audio/menu_music.mp3');
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setLoopMode(LoopMode.all);
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al reproducir música: $e');
    }
  }

  Future<void> playLoadingMusic() async {
    try {
      await _audioPlayer.setAsset('assets/audio/loading_music.mp3');
      await _audioPlayer.setVolume(_volume);
      await _audioPlayer.setLoopMode(LoopMode.all);
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al reproducir música: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al detener música: $e');
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      _volume = volume;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al ajustar volumen: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
