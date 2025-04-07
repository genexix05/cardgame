// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/music_provider.dart';
import 'auth/login_screen.dart';
import 'home_screen.dart';

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

  @override
  void initState() {
    super.initState();

    // Iniciar la música de carga
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      musicProvider.playLoadingMusic();
    });

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

  @override
  void dispose() {
    if (_animationController.isAnimating) {
      _animationController.stop();
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);

      try {
        if (authProvider.isAuthenticated) {
          await musicProvider.stopMusic();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          await musicProvider.stopMusic();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        }
      } catch (e) {
        print("Error al navegar: $e");
        await musicProvider.stopMusic();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      print("Error en _checkAuthState: $e");
      final musicProvider = Provider.of<MusicProvider>(context, listen: false);
      await musicProvider.stopMusic();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (_showTapToContinue) {
            _checkAuthState();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen de fondo
            Image.asset(
              'assets/images/dragon_ball_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error al cargar la imagen: $error');
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
