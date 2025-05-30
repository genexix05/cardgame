import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/platform_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;

  AuthService() {
    // Configurar GoogleSignIn según la plataforma
    _googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
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

      // Mostrar información del simulador si aplica
      if (PlatformUtils.isIOSSimulator) {
        print('⚠️ Ejecutándose en simulador iOS - usando navegador web');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Usuario canceló el inicio de sesión con Google');
        return null;
      }

      print('✅ Usuario seleccionado: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('No se pudieron obtener los tokens de Google');
      }

      print('🔑 Tokens obtenidos correctamente');

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result =
          await _auth.signInWithCredential(credential);

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

      rethrow;
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
