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

  // Lista de iconos para la navegación
  final List<String> _iconPaths = [
    'assets/icons/navigation/home.png',
    'assets/icons/navigation/equipo.png',
    'assets/icons/navigation/sobres.png',
    'assets/icons/navigation/mercado.png',
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

  Widget _buildNavigationButton(int index) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          // Sombra naranja cuando está activo
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 0),
                  ),
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(0, 0),
                  ),
                ]
              : null,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            // Borde naranja sutil cuando está activo
            border: isActive
                ? Border.all(
                    color: Colors.orange.withOpacity(0.4),
                    width: 2,
                  )
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              // Fondo ligeramente naranja cuando está activo
              color: isActive
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.transparent,
              child: AnimatedScale(
                scale: isActive ? 1.05 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Image.asset(
                  _iconPaths[index],
                  width: 84,
                  height: 84,
                  fit: BoxFit.contain,
                  // Filtro de color para resaltar cuando está activo
                  color: isActive ? Colors.orange.withOpacity(0.2) : null,
                  colorBlendMode: isActive ? BlendMode.overlay : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
              decoration: BoxDecoration(
                // Fondo semi-transparente para mejorar la visibilidad
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                    (index) => _buildNavigationButton(index),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
