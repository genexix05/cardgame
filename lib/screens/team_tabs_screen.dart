import 'package:flutter/material.dart';

// Pestañas/Pantallas existentes a integrar
import 'tabs/collection_tab.dart'; // Para "Mis Cartas"
import 'decks_screen.dart'; // Para "Mazos"
import 'card_catalog_screen.dart'; // Importar la pantalla real del catálogo

import '../utils/audio_service.dart'; // Para sonidos de click en pestañas

class TeamTabsScreen extends StatefulWidget {
  const TeamTabsScreen({super.key});

  @override
  State<TeamTabsScreen> createState() => _TeamTabsScreenState();
}

class _TeamTabsScreenState extends State<TeamTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioService _audioService = AudioService();

  // Ya no es necesario el placeholder _buildCardCatalogScreen
  // Widget _buildCardCatalogScreen() {
  //   return const Center(child: Text('Próximamente: Catálogo de Todas las Cartas'));
  // }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _audioService.playButtonClickSound();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // La navegación principal maneja el stack
        title: const Text('Equipo'), // Título de la sección
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis Cartas'),
            Tab(text: 'Mazos'),
            Tab(text: 'Catálogo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CollectionTab(), // Pestaña "Mis Cartas"
          DecksScreen(), // Pestaña "Mazos"
          CardCatalogScreen(), // Usar la pantalla real del Catálogo de Cartas
        ],
      ),
    );
  }
}
