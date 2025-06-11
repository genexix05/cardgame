import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/deck_provider.dart'; // Para pasar datos a BattlesScreen
import '../providers/collection_provider.dart'; // Para obtener datos del usuario
import '../utils/audio_service.dart';
import '../utils/transitions.dart'; // Para CustomPageRoute
import 'battles_screen.dart'; // Pantalla de Batallas

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

    // Cargar los datos del usuario cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    if (authProvider.isAuthenticated && authProvider.user != null) {
      // Cargar la colección del usuario si no está ya cargada
      if (collectionProvider.userCollection == null) {
        await collectionProvider.loadUserCollection(authProvider.user!.uid);
      }
    }
  }

  void _navigateToBattles(BuildContext context) async {
    await _audioService.playButtonClickSound();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final deckProvider = Provider.of<DeckProvider>(context, listen: false);

    // Mostrar indicador de carga mientras se preparan los datos
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Preparando batallas'),
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando tus mazos...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Asegurarse de que los datos necesarios para BattlesScreen estén cargados
      if (authProvider.isAuthenticated && authProvider.user != null) {
        // Cargar explícitamente los mazos del usuario si están vacíos
        if (deckProvider.userDecks.isEmpty) {
          print('Cargando mazos del usuario para batallas...');
          await deckProvider.loadUserDecks(authProvider.user!.uid);
        }
      }

      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.pop(context);
      }

      // Verificar nuevamente si hay mazos disponibles
      if (deckProvider.userDecks.isEmpty) {
        // No hay mazos disponibles, mostrar mensaje y no navegar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes mazos para combatir. Por favor, crea un mazo primero.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Navegar a la pantalla de batallas con los mazos cargados
      if (mounted) {
        Navigator.of(context).push(CustomPageRoute(
          child: BattlesScreen(
            currentPlayerId: authProvider.user?.uid ?? '',
            playerDecks: deckProvider.userDecks,
            deckCards: deckProvider.deckCards,
          ),
          settings: const RouteSettings(name: '/battles'),
        ));
      }
    } catch (e) {
      print('Error al preparar la pantalla de batallas: $e');
      // Cerrar diálogo de carga en caso de error
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tus mazos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final collectionProvider = Provider.of<CollectionProvider>(context);

    String userName = authProvider.user?.displayName ?? 'Jugador';

    // Obtener los datos reales desde Firebase
    String zeniAmount = '---';
    String dragonStonesAmount = '---';

    if (collectionProvider.userCollection != null) {
      zeniAmount = '${collectionProvider.userCollection!.coins} Z';
      dragonStonesAmount = '${collectionProvider.userCollection!.gems} DS';
    }

    return Scaffold(
      // AppBar simulando el HUD superior de la imagen
      appBar: AppBar(
        automaticallyImplyLeading: false, // No mostrar botón de retroceso
        backgroundColor:
            Theme.of(context).colorScheme.primary, // Color naranjo del tema
        elevation: 4, // Añadir un poco de sombra
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Nombre de Usuario y quizás un ícono de perfil pequeño
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(userName,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'CCSoothsayer')), // Fuente CCSoothsayer
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)), // Texto blanco
                const SizedBox(width: 12),
                // Icono de Dragon Stones (ejemplo)
                const Icon(Icons.diamond, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(dragonStonesAmount,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)), // Texto blanco
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
          // Mostrar indicador de carga si los datos se están cargando
          if (collectionProvider.isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          // Contenido principal centrado
          if (!collectionProvider.isLoading)
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
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            width: 3), // Borde
                      ),
                      elevation: 8,
                      shadowColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
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
