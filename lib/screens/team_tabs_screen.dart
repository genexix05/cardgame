import 'package:flutter/material.dart';

// Pantallas existentes a integrar
import 'tabs/collection_tab.dart'; // Para "Mis Cartas"
import 'decks_screen.dart'; // Para "Mazos"
import 'card_catalog_screen.dart'; // Para el catálogo

import '../utils/audio_service.dart'; // Para sonidos de click

class TeamTabsScreen extends StatefulWidget {
  const TeamTabsScreen({super.key});

  @override
  State<TeamTabsScreen> createState() => _TeamTabsScreenState();
}

class _TeamTabsScreenState extends State<TeamTabsScreen> {
  final AudioService _audioService = AudioService();

  void _navigateToScreen(Widget screen, String title) async {
    await _audioService.playButtonClickSound();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Cartas',
          style: TextStyle(
            fontFamily: 'CCSoothsayer',
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/home_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                SizedBox(
                  height: 600, // Altura fija para los botones
                  child: Row(
                    children: [
                      // Botón grande a la izquierda
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: _buildLargeCardButton(
                            title: 'Mi Colección',
                            subtitle: 'Ver todas mis cartas obtenidas',
                            icon: Icons.collections_bookmark,
                            color: Colors.blue,
                            onTap: () => _navigateToScreen(
                              const CollectionTab(),
                              'Mi Colección',
                            ),
                          ),
                        ),
                      ),
                      // Dos botones pequeños apilados a la derecha
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.only(left: 10),
                          child: Column(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: _buildSmallCardButton(
                                    title: 'Mis Mazos',
                                    subtitle: 'Crear y gestionar mazos',
                                    icon: Icons.style,
                                    color: Colors.green,
                                    onTap: () => _navigateToScreen(
                                      const DecksScreen(),
                                      'Mis Mazos',
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  child: _buildSmallCardButton(
                                    title: 'Catálogo',
                                    subtitle: 'Explorar todas las cartas',
                                    icon: Icons.library_books,
                                    color: Colors.purple,
                                    onTap: () => _navigateToScreen(
                                      const CardCatalogScreen(),
                                      'Catálogo de Cartas',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(), // Esto empuja los botones hacia arriba
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeCardButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCardButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.8), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
