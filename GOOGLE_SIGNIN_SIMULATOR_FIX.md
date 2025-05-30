# Solución para Google Sign-In en Simulador iOS

## Problema
El error "Safari no puede abrir la página porque se ha interrumpido la conexión de red" es común cuando se usa Google Sign-In en simuladores de iOS.

## Soluciones Implementadas

### 1. Detección Automática de Simulador
- **Archivo**: `lib/utils/platform_utils.dart`
- **Función**: Detecta automáticamente si la app se ejecuta en un simulador
- **Métodos de detección**:
  - Variables de entorno del simulador
  - Análisis del modelo del dispositivo
  - Verificación de arquitectura (x86_64)

### 2. Configuración Específica para Simulador
- **Archivo**: `lib/services/auth_service.dart`
- **Mejoras**:
  - `forceCodeForRefreshToken: true` para simuladores
  - Logging detallado para debugging
  - Manejo específico de errores de red

### 3. Configuración de iOS
- **Archivo**: `ios/Runner/Info.plist`
  - URL schemes correctos para Google Sign-In
  - Configuración de `LSApplicationQueriesSchemes`
  - Client ID configurado correctamente

- **Archivo**: `ios/Runner/AppDelegate.swift`
  - Configuración de Google Sign-In en `didFinishLaunchingWithOptions`
  - Manejo de URL callbacks

### 4. Interfaz de Usuario Mejorada
- **Archivo**: `lib/widgets/auth_modal.dart`
- **Mejoras**:
  - Advertencia visual cuando se detecta simulador
  - Botón alternativo "Continuar como visitante" para simuladores
  - Diálogo de ayuda específico para errores del simulador

- **Archivo**: `lib/widgets/simulator_help_dialog.dart`
  - Diálogo especializado con soluciones paso a paso
  - Información específica del dispositivo
  - Guías de troubleshooting

### 5. Manejo de Errores Mejorado
- **Archivo**: `lib/providers/auth_provider.dart`
- **Mejoras**:
  - Detección de errores específicos del simulador
  - Mensajes de error más informativos
  - Método de autenticación anónima como fallback

## Cómo Usar

### En Simulador
1. La app detectará automáticamente que está en un simulador
2. Mostrará una advertencia sobre posibles problemas de conectividad
3. Ofrecerá la opción "Continuar como visitante" como alternativa
4. Si Google Sign-In falla, mostrará un diálogo de ayuda específico

### En Dispositivo Físico
1. Google Sign-In funcionará normalmente
2. No se mostrarán advertencias del simulador
3. Experiencia de usuario estándar

## Soluciones Manuales Adicionales

### Si el problema persiste:

1. **Verificar conectividad**:
   ```bash
   # En el simulador, abrir Safari y navegar a google.com
   ```

2. **Reiniciar simulador**:
   ```bash
   # Device > Erase All Content and Settings
   ```

3. **Limpiar proyecto**:
   ```bash
   flutter clean
   cd ios && rm -rf Pods Podfile.lock
   pod install
   cd .. && flutter run
   ```

4. **Verificar configuración de Firebase**:
   - Asegurar que `GoogleService-Info.plist` esté en `ios/Runner/`
   - Verificar que el Bundle ID coincida
   - Confirmar que el Client ID sea correcto

## Archivos Modificados

- `lib/utils/platform_utils.dart` (nuevo)
- `lib/widgets/simulator_help_dialog.dart` (nuevo)
- `lib/services/auth_service.dart`
- `lib/providers/auth_provider.dart`
- `lib/widgets/auth_modal.dart`
- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`

## Notas Importantes

- El problema es específico de simuladores iOS
- En dispositivos físicos, Google Sign-In funciona normalmente
- La autenticación anónima es una alternativa válida para testing
- Siempre probar en dispositivo físico antes de release

## Debugging

Para ver logs detallados:
```bash
flutter run --verbose
```

Los logs mostrarán:
- Detección de simulador
- Información del dispositivo
- Pasos del proceso de autenticación
- Errores específicos con contexto 