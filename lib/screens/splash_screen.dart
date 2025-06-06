// ignore_for_file: deprecated_member_use

import 'dart:async'; // Para Completer
import 'dart:convert';
import 'dart:typed_data'; // Para ByteData y Uint8List
import 'dart:ui' as ui;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:particular/particular.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_modal.dart';
import 'main_navigation_screen.dart';
import 'auth/complete_profile_screen.dart';
import '../utils/transitions.dart';
import '../utils/audio_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _showTapToContinue = false;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  final bool _isFirstBuild = true;
  final ParticularController _particleController = ParticularController();

  @override
  void initState() {
    super.initState();

    _initializeAnimations();
    _loadParticleAssets(); // Cargar partículas
    _startLoadingMusic();
  }

  void _initializeAnimations() {
    // Configurar el controlador de animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Crear la animación de opacidad que va de 0.4 a 1.0
    _opacityAnimation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Iniciar la animación inmediatamente
    _animationController.repeat(reverse: true);

    // Mostrar el mensaje de "toca para continuar" después de 2 segundos
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showTapToContinue = true;
        });
      }
    });
  }

  Future<void> _loadParticleAssets() async {
    try {
      // Load particle configs file
      String jsonString =
          await rootBundle.loadString("assets/animations/snow.json");
      final configsData = jsonDecode(jsonString);

      // Load particle texture file
      // Asegúrate que "textureFileName" en tu snow.json apunte a "texture.png"
      // o ajusta la ruta aquí directamente si es necesario.
      final String texturePath =
          "assets/animations/${configsData["textureFileName"]}";
      ByteData bytes = await rootBundle.load(texturePath);
      ui.Image texture = await _loadUIImage(bytes.buffer.asUint8List());

      // Add particles layer
      _particleController.addLayer(
        configsData: configsData,
      );
    } catch (e) {
      print("Error al cargar assets de partículas: $e");
      // Opcional: agregar una capa de partículas por defecto o ninguna si falla la carga
    }
  }

  Future<ui.Image> _loadUIImage(Uint8List list) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(list, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  void _startLoadingMusic() {
    // Iniciar la música de carga
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final audioService = AudioService();
        await audioService.initialize();
        await audioService.switchToLoadingMusic();
      }
    });
  }

  @override
  void dispose() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!_showTapToContinue) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final audioService = AudioService();

    try {
      if (!mounted) return;

      // Solo mostrar el modal de autenticación si el usuario no está autenticado
      if (!authProvider.isAuthenticated) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const AuthModal(),
        );

        if (result == true && mounted) {
          if (authProvider.user?.displayName == null ||
              authProvider.user!.displayName!.isEmpty) {
            Navigator.of(context).pushReplacement(
              CustomPageRoute(
                child: const CompleteProfileScreen(),
                settings: const RouteSettings(name: '/complete-profile'),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              CustomPageRoute(
                child: const MainNavigationScreen(),
                settings:
                    const RouteSettings(name: MainNavigationScreen.routeName),
              ),
            );
          }
        }
      } else {
        // Si el usuario está autenticado, ir directamente a MainNavigationScreen
        Navigator.of(context).pushReplacement(
          CustomPageRoute(
            child: const MainNavigationScreen(),
            settings: const RouteSettings(name: MainNavigationScreen.routeName),
          ),
        );
      }
    } catch (e) {
      print("Error al manejar el tap: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo
            Image.asset(
              'assets/images/dragon_ball_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF7F00),
                        Color(0xFFFF5722),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Efecto de partículas
            Particular(
              controller: _particleController,
            ),
            // Contenido centrado
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_showTapToContinue)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          colors: [
                            const Color.fromARGB(255, 255, 213, 89)
                                .withOpacity(0.0),
                            const Color(0xFFFFC107).withOpacity(0.8),
                            const Color(0xFFFFD700).withOpacity(0.9),
                            const Color(0xFFFFC107).withOpacity(0.8),
                            const Color(0xFFFFC107).withOpacity(0.0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.0),
                            ],
                          ),
                        ),
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _opacityAnimation.value,
                              child: const Text(
                                'Toca para continuar',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Saiyan',
                                  letterSpacing: 1,
                                  height: 1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 30.0),
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
