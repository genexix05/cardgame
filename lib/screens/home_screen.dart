import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/deck_provider.dart'; // Para pasar datos a BattlesScreen
import '../utils/audio_service.dart';
import '../utils/transitions.dart'; // Para CustomPageRoute
import 'battles_screen.dart'; // Pantalla de Batallas
// Importaciones ya no necesarias para la versión simplificada de HomeScreen:
// import '../providers/collection_provider.dart';
// import 'tabs/collection_tab.dart';
// import 'tabs/packs_tab.dart';
// import 'tabs/market_tab.dart';
// import 'decks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    // La música del menú ahora podría ser manejada por MainNavigationScreen o SplashScreen
    // Si es necesario reproducir música específica aquí, se puede añadir.
    // Ejemplo: _audioService.playMenuMusic(); (asegurándose de que no entre en conflicto)
  }

  void _navigateToBattles(BuildContext context) async {
    await _audioService.playButtonClickSound();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);

    // Asegurarse de que los datos necesarios para BattlesScreen estén cargados
    // Esta lógica de carga podría moverse a un nivel superior si es accedida por múltiples pantallas
    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Es posible que deckProvider.userDecks y deckProvider.deckCards ya estén cargados
      // por MainNavigationScreen o SplashScreen si se centraliza la carga de datos.
      // Si no, se deberían cargar aquí o asegurarse de que estén disponibles.
    }

    Navigator.of(context).push(CustomPageRoute(
      child: BattlesScreen(
        currentPlayerId: authProvider.user?.uid ?? '',
        playerDecks: deckProvider.userDecks,
        deckCards: deckProvider.deckCards,
      ),
      settings: const RouteSettings(name: '/battles'), // Añadir RouteSettings
    ));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    // final userProfileProvider = Provider.of<UserProfileProvider>(context); // Ejemplo si tuvieras uno

    String userName = authProvider.user?.displayName ?? 'Jugador';
    // String zeniAmount = userProfileProvider.zeni?.toString() ?? '---'; // Ejemplo
    // String dragonStonesAmount = userProfileProvider.dragonStones?.toString() ?? '---'; // Ejemplo
    String zeniAmount = '10000 Z'; // Placeholder
    String dragonStonesAmount = '50 DS'; // Placeholder

    return Scaffold(
      // AppBar simulando el HUD superior de la imagen
      appBar: AppBar(
        automaticallyImplyLeading: false, // No mostrar botón de retroceso
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nombre de Usuario y quizás un ícono de perfil pequeño
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                // Aquí podrías añadir RANGO y EXP si decides incluirlos más tarde
                // Text('Rango: 1', style: TextStyle(fontSize: 12)),
              ],
            ),
            // Iconos de Monedas
            Row(
              children: [
                // Icono de Zeni (ejemplo)
                const Icon(Icons.monetization_on,
                    color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(zeniAmount,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                // Icono de Dragon Stones (ejemplo)
                const Icon(Icons.diamond, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(dragonStonesAmount,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        // Aquí podrías añadir más elementos al AppBar si es necesario,
        // como la barra de STA que estaba en la imagen original.
      ),
      body: Stack(
        children: [
          // Fondo (opcional, puedes usar el mismo que en SplashScreen o uno nuevo)
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_background.png', // Cambia esto a tu imagen de fondo deseada
              fit: BoxFit.cover,
              // Placeholder en caso de que la imagen no cargue
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF60BBD8),
                        Color(0xFF2A76A1)
                      ], // Un degradado azulado
                    ),
                  ),
                );
              },
            ),
          ),
          // Contenido principal centrado
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(
                    flex: 2), // Empujar el contenido un poco hacia abajo
                // Aquí podrías añadir el logo del juego o algún gráfico
                // Ejemplo: Image.asset('assets/images/game_logo_small.png', height: 100),
                // const SizedBox(height: 30),

                // Botón grande de Luchar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: Colors.orange, // Color del botón
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80, vertical: 25),
                    textStyle: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Saiyan'), // Estilo de la fuente
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(30), // Bordes redondeados
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          width: 3), // Borde
                    ),
                    elevation: 8,
                    shadowColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  onPressed: () => _navigateToBattles(context),
                  child: const Text('LUCHAR'),
                ),
                const Spacer(flex: 3), // Más espacio debajo del botón
              ],
            ),
          ),
          // Puedes añadir otros elementos aquí, como banners de eventos en la parte inferior
          // como en la imagen de referencia (Fantastically Spooky)
        ],
      ),
    );
  }
}
