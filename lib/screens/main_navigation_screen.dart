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
  }

  void _onTabTapped(int index) async {
    if (_currentIndex == index)
      return; // No hacer nada si se pulsa la pestaña actual
    setState(() {
      _currentIndex = index;
    });
    // playButtonClickSound internamente se asegura de que AudioService esté inicializado.
    await _audioService.playButtonClickSound();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // Usar IndexedStack para mantener el estado de las pestañas
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType
            .fixed, // Para que todos los items sean visibles
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600], // Un gris un poco más oscuro
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people), // Icono para "Equipo"
            label: 'Equipo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard), // Mismo que en la imagen original
            label: 'Sobres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront), // Mismo que en la imagen original
            label: 'Mercado',
          ),
        ],
      ),
    );
  }
}

// Provisional: Crear el archivo team_tabs_screen.dart si no existe
// para evitar errores de importación hasta que lo implementemos.
// Este archivo se implementará correctamente en el siguiente paso.
// --- lib/screens/team_tabs_screen.dart ---
// import 'package:flutter/material.dart';
//
// class TeamTabsScreen extends StatelessWidget {
//   const TeamTabsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const Center(child: Text('Pantalla de Equipo (Pestañas)'));
//   }
// }
// -----------------------------------------
