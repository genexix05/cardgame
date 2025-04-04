import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;
  String? get errorMessage => _error; // Alias para mantener compatibilidad

  AuthProvider() {
    try {
      // Retrasamos la inicialización para asegurar que Firebase esté completamente inicializado
      Future.delayed(Duration(seconds: 1), () {
        _initAuthListener();
      });
    } catch (e) {
      print("Error en constructor de AuthProvider: $e");
    }
  }

  Future<void> _initAuthListener() async {
    try {
      // Escuchar cambios en el estado de autenticación de manera más segura
      _authService.authStateChanges().listen((User? user) {
        _user = user;
        notifyListeners();
      }, onError: (error) {
        print("Error en authStateChanges: $error");
        // No cierro la app, solo registro el error
      });
    } catch (e) {
      print("Error al inicializar AuthProvider: $e");
      // No cierro la app, solo registro el error
    }
  }

  // Registro con email y contraseña
  Future<bool> registerWithEmailAndPassword(
      String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user =
          await _authService.registerWithEmailAndPassword(email, password);
      _isLoading = false;
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Inicio de sesión con email y contraseña
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user =
          await _authService.signInWithEmailAndPassword(email, password);
      _isLoading = false;
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Alias para login (compatibilidad con login_screen.dart)
  Future<bool> login(String email, String password) async {
    return signInWithEmailAndPassword(email, password);
  }

  // Inicio de sesión con Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      _isLoading = false;
      _user = user;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Restablecer contraseña
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = _handleAuthError(e);
      notifyListeners();
      return false;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _authService.signOut();
  }

  // Manejar errores de autenticación
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'El email ya está en uso por otra cuenta.';
        case 'invalid-email':
          return 'El formato del email no es válido.';
        case 'user-not-found':
          return 'No existe una cuenta con este email.';
        case 'wrong-password':
          return 'Contraseña incorrecta.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'operation-not-allowed':
          return 'Esta operación no está permitida.';
        case 'account-exists-with-different-credential':
          return 'Ya existe una cuenta con este email utilizando otro método de inicio de sesión.';
        case 'invalid-credential':
          return 'La credencial de autenticación es inválida.';
        case 'user-disabled':
          return 'Este usuario ha sido deshabilitado.';
        case 'too-many-requests':
          return 'Demasiados intentos fallidos. Inténtalo más tarde.';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu conexión a internet.';
        default:
          return 'Error de autenticación: ${error.message}';
      }
    }
    return 'Error de autenticación: $error';
  }
}
