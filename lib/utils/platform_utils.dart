import 'dart:io';
import 'package:flutter/foundation.dart';

class PlatformUtils {
  /// Detecta si la aplicación se está ejecutando en un simulador de iOS
  static bool get isIOSSimulator {
    if (kIsWeb) return false;
    if (!Platform.isIOS) return false;

    // Múltiples métodos para detectar simulador iOS
    return Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
        Platform.environment['SIMULATOR_ROOT'] != null ||
        Platform.environment['SIMULATOR_UDID'] != null ||
        Platform.environment['SIMULATOR_RUNTIME_VERSION'] != null ||
        // Verificar si el modelo del dispositivo contiene "Simulator"
        _isSimulatorByModel();
  }

  /// Método auxiliar para detectar simulador por modelo
  static bool _isSimulatorByModel() {
    try {
      // En simuladores, el modelo suele contener "Simulator" o "x86_64"
      final environment = Platform.environment;
      return environment.values.any((value) =>
          value.toLowerCase().contains('simulator') ||
          value.toLowerCase().contains('x86_64'));
    } catch (e) {
      return false;
    }
  }

  /// Detecta si la aplicación se está ejecutando en un emulador de Android
  static bool get isAndroidEmulator {
    if (kIsWeb) return false;
    if (!Platform.isAndroid) return false;

    // En emuladores, estas variables de entorno suelen estar presentes
    return Platform.environment['ANDROID_EMULATOR'] != null ||
        Platform.environment['ANDROID_AVD_NAME'] != null;
  }

  /// Detecta si estamos en cualquier tipo de simulador/emulador
  static bool get isSimulator => isIOSSimulator || isAndroidEmulator;

  /// Detecta si estamos en un dispositivo físico
  static bool get isPhysicalDevice => !isSimulator;

  /// Obtiene información del dispositivo para debugging
  static Map<String, String> get deviceInfo {
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'isSimulator': isSimulator.toString(),
      'isIOSSimulator': isIOSSimulator.toString(),
      'isAndroidEmulator': isAndroidEmulator.toString(),
      'environment': Platform.environment.toString(),
    };
  }
}
