import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/platform_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    // Configurar GoogleSignIn según la plataforma
    // Detect web platform and set client ID accordingly
    bool isRunningOnWeb = identical(0, 0.0);
    _googleSignIn = GoogleSignIn(
      clientId: isRunningOnWeb
        ? '1074439862642-joo805hjq6e8rc8llbavh3bgmt2brv8r.apps.googleusercontent.com'
        : null, // solo en web
      scopes: ['openid','email', 'profile'],
      // En simulador iOS, forzar el uso del navegador web
      forceCodeForRefreshToken: PlatformUtils.isIOSSimulator,
    );

    // Debug info para simulador
    if (PlatformUtils.isSimulator) {
      print('🔧 Ejecutándose en simulador/emulador');
      print('📱 Info del dispositivo: ${PlatformUtils.deviceInfo}');
    }
  }

  // Obtener el usuario actual
  User? get currentUser => _auth.currentUser;

  // Obtener el stream de cambios de autenticación
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Verificar si el usuario está conectado
  bool get isLoggedIn => currentUser != null;

  // Registro con correo electrónico y contraseña
  Future<User?> registerWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Crear documento de usuario en Firestore con rol predeterminado
      if (result.user != null) {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'role': 'user', // Asignar rol de usuario por defecto
          'createdAt': DateTime.now(),
          'lastLogin': DateTime.now(),
          'displayName': result.user!.displayName ?? '',
          'photoURL': result.user!.photoURL ?? '',
        }, SetOptions(merge: true));

        // Inicializar la colección del usuario con valores predeterminados
        await firestore.collection('users').doc(result.user!.uid).set({
          'coins': 1000, // Monedas iniciales
          'gems': 50, // Gemas iniciales
          'cards': {}, // Inicializar mapa de cartas vacío
          'resources': {'coins': 1000, 'gems': 50}, // Inicializar recursos
          'totalCards': 0, // Inicializar contador de cartas
          'rarityDistribution': {
            'common': 0,
            'uncommon': 0,
            'rare': 0,
            'superRare': 0,
            'ultraRare': 0,
            'legendary': 0,
          }, // Inicializar distribución de rareza
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return result.user;
    } catch (e) {
      print('Error en el registro: $e');
      rethrow; // Relanzar el error para que pueda ser manejado en el Provider
    }
  }

  // Inicio de sesión con correo electrónico y contraseña
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar el último acceso en Firestore
      if (result.user != null) {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(result.user!.uid).update({
          'lastLogin': DateTime.now(),
        });
      }

      return result.user;
    } catch (e) {
      print('Error en el inicio de sesión: $e');
      rethrow; // Relanzar el error para que pueda ser manejado en el Provider
    }
  }

  // Inicio de sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      print('🚀 Iniciando Google Sign-In...');

      // Determinar si estamos en web o en plataforma móvil
      bool isWebPlatform = kIsWeb;

      // Mostrar información del simulador si aplica
      if (PlatformUtils.isIOSSimulator) {
        print('⚠️ Ejecutándose en simulador iOS - usando navegador web');
      }

      GoogleSignInAccount? googleUser;
      
      // Usar enfoque diferente para web vs móvil
      if (isWebPlatform) {
        // Para web, intentar primero con signInSilently
        googleUser = await _googleSignIn.signInSilently();
        
        // Si no hay sesión activa, usar signIn (aunque sea desconsejado)
        if (googleUser == null) {
          // Nota: Esto sigue utilizando signIn que será removido en Q2 2024
          // TODO: Migrar a renderButton cuando sea posible
          googleUser = await _googleSignIn.signIn();
        }
      } else {
        // Para móvil, usar el flujo normal
        googleUser = await _googleSignIn.signIn();
      }

      // Usuario canceló o no se pudo obtener
      if (googleUser == null) {
        print('❌ Usuario canceló el inicio de sesión con Google');
        return null;
      }

      print('✅ Usuario seleccionado: ${googleUser.email}');

      // Intentar obtener los tokens de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // En web, es posible que no tengamos idToken según la documentación
      if (googleAuth.accessToken == null) {
        throw Exception('No se pudo obtener el access token de Google');
      }

      // Para web, podemos no tener idToken, pero necesitamos al menos accessToken
      AuthCredential credential;
      if (googleAuth.idToken != null) {
        // Método preferido: usar tanto accessToken como idToken
        credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
      } else if (isWebPlatform) {
        // Solo para web: si no hay idToken, usar el método alternativo con solo accessToken
        // Crear un provider específico para Google y setear accessToken
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'access_type': 'offline'});
        
        // Firmar directamente con el provider en lugar de usar credential
        final UserCredential result = await _auth.signInWithPopup(googleProvider);
        
        // Procesar el resultado igual que abajo
        await _processGoogleSignInResult(result);
        return result.user;
      } else {
        // En móvil siempre deberíamos tener idToken
        throw Exception('No se pudo obtener el id token de Google');
      }

      print('🔑 Tokens obtenidos correctamente');

      // Iniciar sesión con las credenciales
      final UserCredential result = await _auth.signInWithCredential(credential);
      
      // Procesar el resultado
      await _processGoogleSignInResult(result);
      
      print('🎉 Autenticación exitosa: ${result.user?.email}');
      return result.user;
    } catch (e) {
      print('❌ Error en el inicio de sesión con Google: $e');

      // Manejo específico de errores del simulador
      if (PlatformUtils.isIOSSimulator) {
        if (e.toString().contains('network_error') ||
            e.toString().contains('connection') ||
            e.toString().contains('interrupted') ||
            e.toString().contains('NSURLErrorDomain') ||
            e.toString().contains('The network connection was lost')) {
          throw Exception('Error de conexión en el simulador iOS.\n\n'
              'Soluciones recomendadas:\n'
              '• Verifica que el WiFi esté funcionando correctamente\n'
              '• Reinicia el simulador de iOS\n'
              '• Prueba con Safari en el simulador para verificar conectividad\n'
              '• Considera usar un dispositivo físico para mejores resultados\n\n'
              'Este es un problema común en simuladores de iOS.');
        }
      }

      // Otros errores comunes de Google Sign-In
      if (e.toString().contains('sign_in_canceled')) {
        return null; // Usuario canceló, no es un error
      }

      if (e.toString().contains('sign_in_failed')) {
        throw Exception('Error en el proceso de autenticación con Google.\n'
            'Intenta nuevamente o verifica tu conexión a internet.');
      }

      // Manejo específico para errores web
      if (kIsWeb && e.toString().contains('No se pudieron obtener los tokens')) {
        throw Exception('Error en la autenticación web con Google.\n'
            'Esto suele ocurrir debido a limitaciones del navegador o configuraciones de seguridad.\n'
            'Intenta usar otro navegador o actualizar el existente.');
      }

      rethrow;
    }
  }

  // Método auxiliar para procesar el resultado de autenticación con Google
  Future<void> _processGoogleSignInResult(UserCredential result) async {
    if (result.user != null) {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      // Verificar si el usuario ya existe
      final userDoc = await firestore.collection('users').doc(result.user!.uid).get();

      // Si no existe, crear documento con rol predeterminado
      if (!userDoc.exists) {
        await firestore.collection('users').doc(result.user!.uid).set({
          'email': result.user!.email ?? '',
          'role': 'user', // Asignar rol de usuario por defecto
          'createdAt': DateTime.now(),
          'lastLogin': DateTime.now(),
          'displayName': result.user!.displayName ?? '',
          'photoURL': result.user!.photoURL ?? '',
        }, SetOptions(merge: true));

        // Inicializar la colección del usuario con valores predeterminados
        await firestore.collection('users').doc(result.user!.uid).set({
          'coins': 1000, // Monedas iniciales
          'gems': 50, // Gemas iniciales
          'cards': {}, // Inicializar mapa de cartas vacío
          'resources': {'coins': 1000, 'gems': 50}, // Inicializar recursos
          'totalCards': 0, // Inicializar contador de cartas
          'rarityDistribution': {
            'common': 0,
            'uncommon': 0,
            'rare': 0,
            'superRare': 0,
            'ultraRare': 0,
            'legendary': 0,
          }, // Inicializar distribución de rareza
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Si ya existe, actualizar solo el último acceso
        await firestore.collection('users').doc(result.user!.uid).update({
          'lastLogin': DateTime.now(),
        });
      }
    }
  }

  // Inicio de sesión con Apple (implementación simplificada)
  Future<User?> signInWithApple() async {
    try {
      // Implementación específica para iOS/macOS
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final UserCredential result =
          await _auth.signInWithProvider(appleProvider);

      // Crear o actualizar documento de usuario en Firestore con rol predeterminado
      if (result.user != null) {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        // Verificar si el usuario ya existe
        final userDoc =
            await firestore.collection('users').doc(result.user!.uid).get();

        // Si no existe, crear documento con rol predeterminado
        if (!userDoc.exists) {
          await firestore.collection('users').doc(result.user!.uid).set({
            'email': result.user!.email ?? '',
            'role': 'user', // Asignar rol de usuario por defecto
            'createdAt': DateTime.now(),
            'lastLogin': DateTime.now(),
            'displayName': result.user!.displayName ?? '',
            'photoURL': result.user!.photoURL ?? '',
          }, SetOptions(merge: true));

          // Inicializar la colección del usuario con valores predeterminados
          await firestore.collection('users').doc(result.user!.uid).set({
            'coins': 1000, // Monedas iniciales
            'gems': 50, // Gemas iniciales
            'cards': {}, // Inicializar mapa de cartas vacío
            'resources': {'coins': 1000, 'gems': 50}, // Inicializar recursos
            'totalCards': 0, // Inicializar contador de cartas
            'rarityDistribution': {
              'common': 0,
              'uncommon': 0,
              'rare': 0,
              'superRare': 0,
              'ultraRare': 0,
              'legendary': 0,
            }, // Inicializar distribución de rareza
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Si ya existe, actualizar solo el último acceso
          await firestore.collection('users').doc(result.user!.uid).update({
            'lastLogin': DateTime.now(),
          });
        }
      }

      return result.user;
    } catch (e) {
      print('Error en el inicio de sesión con Apple: $e');
      return null;
    }
  }

  // Inicio de sesión anónimo (para visitantes)
  Future<User?> signInAnonymously() async {
    try {
      final UserCredential result = await _auth.signInAnonymously();

      // Crear o actualizar documento de usuario en Firestore con rol predeterminado
      if (result.user != null) {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;
        // Verificar si el usuario ya existe
        final userDoc =
            await firestore.collection('users').doc(result.user!.uid).get();

        // Si no existe, crear documento con rol predeterminado
        if (!userDoc.exists) {
          await firestore.collection('users').doc(result.user!.uid).set({
            'email': 'anónimo',
            'role': 'visitor', // Asignar rol de visitante por defecto
            'createdAt': DateTime.now(),
            'lastLogin': DateTime.now(),
            'displayName': 'Usuario anónimo',
            'photoURL': '',
          }, SetOptions(merge: true));

          // Inicializar la colección del usuario con valores predeterminados
          await firestore.collection('users').doc(result.user!.uid).set({
            'coins':
                500, // Monedas iniciales para visitantes (menos que usuarios registrados)
            'gems':
                20, // Gemas iniciales para visitantes (menos que usuarios registrados)
            'cards': {}, // Inicializar mapa de cartas vacío
            'resources': {'coins': 500, 'gems': 20}, // Inicializar recursos
            'totalCards': 0, // Inicializar contador de cartas
            'rarityDistribution': {
              'common': 0,
              'uncommon': 0,
              'rare': 0,
              'superRare': 0,
              'ultraRare': 0,
              'legendary': 0,
            }, // Inicializar distribución de rareza
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } else {
          // Si ya existe, actualizar solo el último acceso
          await firestore.collection('users').doc(result.user!.uid).update({
            'lastLogin': DateTime.now(),
          });
        }
      }

      return result.user;
    } catch (e) {
      print('Error en el inicio de sesión anónimo: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error al cerrar sesión: $e');
    }
  }

  // Restablecer contraseña
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Error al restablecer contraseña: $e');
      return false;
    }
  }

  // Actualizar perfil del usuario
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      await currentUser?.updatePhotoURL(photoURL);
      return true;
    } catch (e) {
      print('Error al actualizar perfil: $e');
      return false;
    }
  }

  // Guardar el token de usuario en local storage
  Future<void> saveUserToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userToken', token);
  }

  // Obtener el token de usuario del local storage
  Future<String?> getUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }

  // Eliminar el token de usuario del local storage
  Future<void> removeUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userToken');
  }
}
