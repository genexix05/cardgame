import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/collection_provider.dart';
import '../utils/audio_service.dart';
import '../widgets/sound_button.dart';
import 'tabs/collection_tab.dart';
import 'tabs/packs_tab.dart';
import 'tabs/market_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final AudioService _audioService = AudioService();

  // Lista de pestañas
  final List<Widget> _tabs = [
    const CollectionTab(),
    const PacksTab(),
    const MarketTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();

    // Utilizar addPostFrameCallback para asegurarnos de que el widget ya se ha construido
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadUserData();
      // Inicializar y reproducir música
      await _audioService.initialize();
      if (_audioService.isAudioEnabled) {
        await _audioService.playMenuMusic();
      }
    });
  }

  @override
  void dispose() {
    _audioService.stopMusic();
    super.dispose();
  }

  // Cargar datos del usuario
  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.user != null) {
      await collectionProvider.loadUserCollection(authProvider.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          setState(() {
            _currentIndex = index;
          });
          await _audioService.playButtonClickSound();
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.collections),
            label: 'Colección',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Sobres',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Mercado',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
