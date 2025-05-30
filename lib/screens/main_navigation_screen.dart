import 'package:flutter/material.dart';

// Pestañas existentes
import 'tabs/packs_tab.dart';
import 'tabs/market_tab.dart';

// Pantallas a crear/modificar
import 'home_screen.dart'; // Se modificará para ser la nueva pantalla de inicio
import 'team_tabs_screen.dart'; // Se creará para la sección "Equipo"

import '../utils/audio_service.dart'; // Para los sonidos de click

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static const routeName =
      '/main-navigation'; // Opcional: para navegación nombrada

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final AudioService _audioService = AudioService(); // Inicializar directamente

  // Lista de pantallas para la navegación
  final List<Widget> _screens = [
    const HomeScreen(), // Nueva pantalla de Inicio (modificada)
    const TeamTabsScreen(), // Nueva pantalla con pestañas para Equipo
    const PacksTab(), // Pantalla de Sobres existente
    const MarketTab(), // Pantalla de Mercado existente
  ];

  @override
  void initState() {
    super.initState();
    // AudioService se inicializa a través de su patrón singleton y
    // sus métodos internos manejan la inicialización si es necesario.
    // Por ejemplo, playButtonClickSound verifica y llama a initialize().

    // Inicializar y reproducir música del menú
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _audioService.initialize();
        // Usar método de prueba temporalmente
        await _audioService.testPlayMenuMusic();
      }
    });
  }

  void _onTabTapped(int index) async {
    if (_currentIndex == index) {
      return; // No hacer nada si se pulsa la pestaña actual
    }
    setState(() {
      _currentIndex = index;
    });
    // playButtonClickSound internamente se asegura de que AudioService esté inicializado.
    await _audioService.playButtonClickSound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100 + MediaQuery.of(context).padding.bottom,
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _onTabTapped(0),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/icons/navigation/home.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onTabTapped(1),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/icons/navigation/equipo.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onTabTapped(2),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/icons/navigation/sobres.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _onTabTapped(3),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/icons/navigation/mercado.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
