import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';

// Pantallas existentes a integrar
import 'tabs/collection_tab.dart'; // Para "Mis Cartas"
import 'decks_screen.dart'; // Para "Mazos"
import 'card_catalog_screen.dart'; // Para el catálogo

import '../utils/audio_service.dart'; // Para sonidos de click
import '../providers/collection_provider.dart';
import '../providers/auth_provider.dart';
import '../models/card.dart' as card_model;

class TeamTabsScreen extends StatefulWidget {
  const TeamTabsScreen({super.key});

  @override
  State<TeamTabsScreen> createState() => _TeamTabsScreenState();
}

class _TeamTabsScreenState extends State<TeamTabsScreen>
    with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  late AnimationController _floatingCardsController;
  final List<FloatingCard> _floatingCards = [];
  Timer? _cardSpawnTimer;
  final math.Random _random = math.Random();

  // Cartas para mostrar en los botones
  card_model.Card? _collectionCard;
  card_model.Card? _deckCard;
  card_model.Card? _catalogCard;

  @override
  void initState() {
    super.initState();

    _floatingCardsController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Cargar cartas para los botones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserCollectionCards();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Iniciar el sistema de cartas flotantes solo cuando el context esté disponible
    if (mounted && _cardSpawnTimer == null) {
      _startFloatingCardSystem();
    }

    // Escuchar cambios en la colección del usuario
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    // Si la colección se ha cargado y hay cartas, actualizar el sistema
    if (collectionProvider.userCardsWithDetails.isNotEmpty) {
      // Las cartas flotantes automáticamente usarán las cartas reales
      // ya que _getRandomCardData() ahora las obtiene de la colección
    }
  }

  Future<void> _loadUserCollectionCards() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);

    if (authProvider.user != null) {
      await collectionProvider.loadUserCollection(authProvider.user!.uid);

      if (collectionProvider.userCardsWithDetails.isNotEmpty) {
        final userCards = collectionProvider.userCardsWithDetails;

        // Filtrar cartas por tipo para cada botón
        final characterCards = userCards.where((item) {
          final cardDetail = item['cardDetail'] as card_model.Card;
          return cardDetail.type == card_model.CardType.character;
        }).toList();

        final supportCards = userCards.where((item) {
          final cardDetail = item['cardDetail'] as card_model.Card;
          return cardDetail.type == card_model.CardType.support;
        }).toList();

        final equipmentCards = userCards.where((item) {
          final cardDetail = item['cardDetail'] as card_model.Card;
          return cardDetail.type == card_model.CardType.equipment;
        }).toList();

        setState(() {
          // Asignar cartas aleatorias para cada botón
          if (characterCards.isNotEmpty) {
            _collectionCard =
                characterCards[_random.nextInt(characterCards.length)]
                    ['cardDetail'] as card_model.Card;
          }

          if (supportCards.isNotEmpty) {
            _deckCard = supportCards[_random.nextInt(supportCards.length)]
                ['cardDetail'] as card_model.Card;
          } else if (characterCards.isNotEmpty) {
            _deckCard = characterCards[_random.nextInt(characterCards.length)]
                ['cardDetail'] as card_model.Card;
          }

          if (equipmentCards.isNotEmpty) {
            _catalogCard =
                equipmentCards[_random.nextInt(equipmentCards.length)]
                    ['cardDetail'] as card_model.Card;
          } else if (userCards.isNotEmpty) {
            _catalogCard = userCards[_random.nextInt(userCards.length)]
                ['cardDetail'] as card_model.Card;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _floatingCardsController.dispose();
    _cardSpawnTimer?.cancel();
    super.dispose();
  }

  void _startFloatingCardSystem() {
    // Crear cartas flotantes cada 1-3 segundos (más frecuente)
    _cardSpawnTimer = Timer.periodic(
      Duration(seconds: 1 + _random.nextInt(3)),
      (timer) {
        if (_floatingCards.length < 12) {
          // Aumentado de 3 a 12 cartas simultáneas
          _spawnFloatingCard();
        }
      },
    );

    // Spawn inicial inmediato y luego más cartas
    _spawnFloatingCard();
    Timer(const Duration(milliseconds: 500), () {
      _spawnFloatingCard();
    });
    Timer(const Duration(seconds: 1), () {
      _spawnFloatingCard();
    });
    Timer(const Duration(milliseconds: 1500), () {
      _spawnFloatingCard();
    });
  }

  void _spawnFloatingCard() {
    if (!mounted) return;

    // Verificar si hay cartas válidas antes de crear cartas flotantes
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);
    final userCardsWithDetails = collectionProvider.userCardsWithDetails;

    if (userCardsWithDetails.isEmpty) {
      print('⚠️ No hay cartas en la colección, no se crearán cartas flotantes');
      return;
    }

    final cardData = _getRandomCardData();

    // No crear carta flotante si es la carta por defecto "Sin cartas"
    if (cardData.name == 'Sin cartas') {
      print('⚠️ No se creará carta flotante sin cartas válidas');
      return;
    }

    final startPosition = _getRandomStartPosition();
    final endPosition = _getRandomEndPosition();

    final floatingCard = FloatingCard(
      cardData: cardData,
      startPosition: startPosition,
      endPosition: endPosition,
      onAnimationComplete: () {
        setState(() {
          _floatingCards.removeWhere((card) => card.cardData.id == cardData.id);
        });
      },
    );

    setState(() {
      _floatingCards.add(floatingCard);
    });

    // Remover la carta después de tiempo variable (6-12 segundos)
    Timer(Duration(seconds: 6 + _random.nextInt(7)), () {
      setState(() {
        _floatingCards.removeWhere((card) => card.cardData.id == cardData.id);
      });
    });
  }

  CardData _getRandomCardData() {
    // Usar únicamente cartas de la colección del usuario
    final collectionProvider =
        Provider.of<CollectionProvider>(context, listen: false);
    final userCardsWithDetails = collectionProvider.userCardsWithDetails;

    print(
        '🎯 Generando datos de carta. Cartas disponibles: ${userCardsWithDetails.length}');

    // MEJORADO: filtrar cartas que realmente tengan una imagen válida y no vacía
    final cardsWithValidImages = userCardsWithDetails.where((item) {
      final card = item['cardDetail'] as card_model.Card;

      // Verificar que el imageUrl no esté vacío
      if (card.imageUrl.isEmpty) {
        return false;
      }

      // Verificar que si es base64, tenga formato válido
      if (card.imageUrl.startsWith('data:image')) {
        final parts = card.imageUrl.split(',');
        if (parts.length <= 1 || parts[1].isEmpty) {
          print('⚠️ Imagen base64 inválida para carta: ${card.name}');
          return false;
        }
        // Verificar que el base64 no sea demasiado corto (probablemente corrupto)
        if (parts[1].length < 100) {
          print('⚠️ Imagen base64 muy corta para carta: ${card.name}');
          return false;
        }
      }

      return true;
    }).toList();

    if (cardsWithValidImages.isNotEmpty) {
      // Usar cartas reales (con imagen válida) de la colección del usuario
      final randomCardData =
          cardsWithValidImages[_random.nextInt(cardsWithValidImages.length)];
      final card = randomCardData['cardDetail'] as card_model.Card;

      // Obtener color basado en la rareza de la carta
      Color cardColor = _getColorFromRarity(card.rarity);

      print('✨ Usando carta real: ${card.name}, Rareza: ${card.rarity}');
      print('🖼️ ImageUrl válida detectada, longitud: ${card.imageUrl.length}');

      return CardData(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            _random.nextInt(1000).toString(),
        name: card.name,
        imageUrl: card.imageUrl,
        color: cardColor,
      );
    }

    // Si no hay cartas con imagen válida, no mostrar cartas flotantes
    print(
        '⚠️ No hay cartas con imagen válida disponible en la colección del usuario');
    return CardData(
      id: DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      name: 'Sin cartas',
      imageUrl: '',
      color: Colors.grey,
    );
  }

  // Método para obtener color basado en la rareza de la carta
  Color _getColorFromRarity(card_model.CardRarity rarity) {
    switch (rarity) {
      case card_model.CardRarity.common:
        return const Color(0xFF9E9E9E); // Gris
      case card_model.CardRarity.uncommon:
        return const Color(0xFF4CAF50); // Verde
      case card_model.CardRarity.rare:
        return const Color(0xFF2196F3); // Azul
      case card_model.CardRarity.superRare:
        return const Color(0xFF9C27B0); // Púrpura
      case card_model.CardRarity.ultraRare:
        return const Color(0xFFFF9800); // Naranja
      case card_model.CardRarity.legendary:
        return const Color(0xFFF44336); // Rojo/Dorado
    }
  }

  Offset _getRandomStartPosition() {
    // Variedad de posiciones de inicio desde diferentes lados
    if (!mounted) {
      return const Offset(400, -100); // Valor por defecto si no hay context
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final startSide =
        _random.nextInt(4); // 0: derecha, 1: izquierda, 2: arriba, 3: abajo

    switch (startSide) {
      case 0: // Desde la derecha
        return Offset(
          screenWidth + 50,
          _random.nextDouble() * screenHeight,
        );
      case 1: // Desde la izquierda
        return Offset(
          -50,
          _random.nextDouble() * screenHeight,
        );
      case 2: // Desde arriba
        return Offset(
          _random.nextDouble() * screenWidth,
          -100,
        );
      case 3: // Desde abajo
        return Offset(
          _random.nextDouble() * screenWidth,
          screenHeight + 100,
        );
      default:
        return Offset(screenWidth + 50, -100 + _random.nextDouble() * 200);
    }
  }

  Offset _getRandomEndPosition() {
    // Variedad de posiciones finales hacia diferentes lados
    if (!mounted) {
      return const Offset(-100, 800); // Valor por defecto si no hay context
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final endSide =
        _random.nextInt(4); // 0: izquierda, 1: derecha, 2: abajo, 3: arriba

    switch (endSide) {
      case 0: // Hacia la izquierda
        return Offset(
          -100 - _random.nextDouble() * 100,
          _random.nextDouble() * screenHeight,
        );
      case 1: // Hacia la derecha
        return Offset(
          screenWidth + 100 + _random.nextDouble() * 100,
          _random.nextDouble() * screenHeight,
        );
      case 2: // Hacia abajo
        return Offset(
          _random.nextDouble() * screenWidth,
          screenHeight + 100,
        );
      case 3: // Hacia arriba
        return Offset(
          _random.nextDouble() * screenWidth,
          -100,
        );
      default:
        return Offset(-100 - _random.nextDouble() * 100, screenHeight + 100);
    }
  }

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
      body: Stack(
        children: [
          // Fondo base
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Cartas flotantes
          ..._floatingCards.map(
            (floatingCard) => AnimatedFloatingCardWidget(
              key: ValueKey(floatingCard.cardData.id),
              floatingCard: floatingCard,
            ),
          ),

          // Contenido principal
          SafeArea(
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
                            child: _buildLargeCardButtonWithCard(
                              title: 'Mi Colección',
                              subtitle: 'Ver todas mis cartas obtenidas',
                              icon: Icons.collections_bookmark,
                              color:
                                  const Color(0xFFFF6B35), // Naranja vibrante
                              card: _collectionCard,
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
                                    child: _buildSmallCardButtonWithCard(
                                      title: 'Mis Mazos',
                                      subtitle: 'Crear y gestionar mazos',
                                      icon: Icons.style,
                                      color: const Color(
                                          0xFF1A237E), // Azul navy profundo
                                      card: _deckCard,
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
                                    child: _buildSmallCardButtonWithCard(
                                      title: 'Catálogo',
                                      subtitle: 'Explorar todas las cartas',
                                      icon: Icons.library_books,
                                      color: const Color(
                                          0xFF00ACC1), // Teal que complementa la paleta
                                      card: _catalogCard,
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
        ],
      ),
    );
  }

  Widget _buildLargeCardButtonWithCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    card_model.Card? card,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            spreadRadius: 4,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: color.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.5,
                colors: [
                  color.withOpacity(0.7),
                  color,
                  color.withOpacity(0.9),
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Efecto de brillo superior
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Patrón de textura
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      backgroundBlendMode: BlendMode.overlay,
                      gradient: SweepGradient(
                        center: Alignment.center,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                          Colors.white.withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Carta en la esquina superior derecha
                if (card != null)
                  Positioned(
                    top: 15,
                    right: 15,
                    child: CollectionCardWidget(
                      card: card,
                      size: 50,
                    ),
                  ),

                // Contenido principal
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono con efecto resplandeciente
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.25),
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 60,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            offset: const Offset(3, 3),
                            blurRadius: 6,
                          ),
                          Shadow(
                            color: color.withOpacity(0.5),
                            offset: const Offset(-1, -1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Título con efectos múltiples
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'CCSoothsayer',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                          Shadow(
                            color: color.withOpacity(0.6),
                            offset: const Offset(-1, -1),
                            blurRadius: 2,
                          ),
                          Shadow(
                            color: Colors.white.withOpacity(0.3),
                            offset: const Offset(0, 0),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    // Subtítulo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Efectos de esquina con brillo
                Positioned(
                  bottom: 15,
                  left: 15,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallCardButtonWithCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    card_model.Card? card,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            spreadRadius: 3,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: color.withOpacity(0.25),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: Colors.white.withOpacity(0.3),
          highlightColor: Colors.white.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 2.2,
                colors: [
                  color.withOpacity(0.7),
                  color,
                  color.withOpacity(0.9),
                  Colors.black.withOpacity(0.3),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Efecto de brillo
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Textura sutil
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      backgroundBlendMode: BlendMode.overlay,
                      gradient: SweepGradient(
                        center: Alignment.center,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Carta en la esquina superior derecha
                if (card != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CollectionCardWidget(
                      card: card,
                      size: 30,
                    ),
                  ),

                // Contenido principal
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.08),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 34,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                          ),
                          Shadow(
                            color: color.withOpacity(0.4),
                            offset: const Offset(-1, -1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Título
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'CCSoothsayer',
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            offset: const Offset(1, 1),
                            blurRadius: 3,
                          ),
                          Shadow(
                            color: color.withOpacity(0.5),
                            offset: const Offset(-0.5, -0.5),
                            blurRadius: 1,
                          ),
                          Shadow(
                            color: Colors.white.withOpacity(0.2),
                            offset: const Offset(0, 0),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Subtítulo
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.6),
                              offset: const Offset(0.5, 0.5),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar cartas de la colección en los botones
class CollectionCardWidget extends StatelessWidget {
  final card_model.Card card;
  final double size;

  const CollectionCardWidget({
    super.key,
    required this.card,
    this.size = 40,
  });

  // Método para construir la imagen de la carta
  Widget _buildCardImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Es una imagen en formato base64
      try {
        final parts = imageUrl.split(',');
        if (parts.length <= 1) {
          return _buildDefaultCard();
        }

        Uint8List? bytes;
        try {
          bytes = base64Decode(parts[1]);
        } catch (e) {
          return _buildDefaultCard();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: size,
            height: size * 1.4,
            errorBuilder: (context, error, stackTrace) => _buildDefaultCard(),
          ),
        );
      } catch (e) {
        return _buildDefaultCard();
      }
    } else if (imageUrl.isNotEmpty) {
      // Es una URL normal
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: size,
          height: size * 1.4,
          errorBuilder: (context, error, stackTrace) => _buildDefaultCard(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildDefaultCard();
          },
        ),
      );
    } else {
      return _buildDefaultCard();
    }
  }

  Widget _buildDefaultCard() {
    return Container(
      width: size,
      height: size * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getRarityColor().withOpacity(0.7),
            _getRarityColor().withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: size * 0.4,
        ),
      ),
    );
  }

  Color _getRarityColor() {
    switch (card.rarity) {
      case card_model.CardRarity.common:
        return Colors.grey;
      case card_model.CardRarity.uncommon:
        return Colors.green;
      case card_model.CardRarity.rare:
        return Colors.blue;
      case card_model.CardRarity.superRare:
        return Colors.purple;
      case card_model.CardRarity.ultraRare:
        return Colors.orange;
      case card_model.CardRarity.legendary:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          // Sombra del color de rareza
          BoxShadow(
            color: _getRarityColor().withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 3),
          ),
          // Sombra negra para profundidad
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Carta principal
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getRarityColor(),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  // Imagen de la carta
                  _buildCardImage(card.imageUrl),

                  // Overlay con opacidad para el efecto
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                          _getRarityColor().withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),

                  // Nombre de la carta (solo en cartas más grandes)
                  if (size > 35)
                    Positioned(
                      bottom: 2,
                      left: 1,
                      right: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          card.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size * 0.12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Efecto de brillo en los bordes
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.transparent,
                    Colors.transparent,
                    _getRarityColor().withOpacity(0.2),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clases para el sistema de cartas flotantes
class CardData {
  final String id;
  final String name;
  final String imageUrl;
  final Color color;

  CardData({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.color,
  });
}

class FloatingCard {
  final CardData cardData;
  final Offset startPosition;
  final Offset endPosition;
  final VoidCallback onAnimationComplete;

  FloatingCard({
    required this.cardData,
    required this.startPosition,
    required this.endPosition,
    required this.onAnimationComplete,
  });
}

class AnimatedFloatingCardWidget extends StatefulWidget {
  final FloatingCard floatingCard;

  const AnimatedFloatingCardWidget({
    super.key,
    required this.floatingCard,
  });

  @override
  State<AnimatedFloatingCardWidget> createState() =>
      _AnimatedFloatingCardWidgetState();
}

class _AnimatedFloatingCardWidgetState extends State<AnimatedFloatingCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _positionAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  double _cardSize = 60.0; // Valor por defecto
  late Duration _animationDuration;

  @override
  void initState() {
    super.initState();

    // Tamaños variables para las cartas (entre 45 y 75)
    final math.Random random = math.Random();
    _cardSize = 45 + random.nextDouble() * 30;

    // Duraciones variables (entre 6 y 12 segundos)
    _animationDuration = Duration(seconds: 6 + random.nextInt(7));

    _animationController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    // Animación de posición con curvas más variadas
    final curves = [
      Curves.easeInOut,
      Curves.easeIn,
      Curves.easeOut,
      Curves.linear
    ];
    _positionAnimation = Tween<Offset>(
      begin: widget.floatingCard.startPosition,
      end: widget.floatingCard.endPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: curves[random.nextInt(curves.length)],
    ));

    // Animación de opacidad (aparece, se mantiene, desaparece)
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.8),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 0.8),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 0.0),
        weight: 20,
      ),
    ]).animate(_animationController);

    // Animación de escala (pequeña pulsación)
    _scaleAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    // Animación de rotación más variada
    _rotationAnimation = Tween<double>(
      begin: -0.2 + random.nextDouble() * 0.4,
      end: -0.3 + random.nextDouble() * 0.6,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animación
    _animationController.forward().then((_) {
      widget.floatingCard.onAnimationComplete();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          left: _positionAnimation.value.dx,
          top: _positionAnimation.value.dy,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: _cardSize,
                  height: _cardSize * 1.4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.floatingCard.cardData.color,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            widget.floatingCard.cardData.color.withOpacity(0.6),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Carta principal
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildCardImageExact(
                              widget.floatingCard.cardData.imageUrl),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Método que copia EXACTAMENTE la lógica de CollectionCardWidget pero mejorada
  Widget _buildCardImageExact(String imageUrl) {
    print(
        "🖼️ FloatingCard: Construyendo imagen con URL: ${imageUrl.isEmpty ? 'VACÍA' : 'longitud ${imageUrl.length}'}");

    if (imageUrl.isEmpty) {
      print(
          '⚠️ FloatingCard: URL de imagen vacía, mostrando imagen por defecto');
      return _buildDefaultCardExact();
    }

    if (!imageUrl.startsWith('data:image')) {
      print('⚠️ FloatingCard: URL no es base64, mostrando imagen por defecto');
      return _buildDefaultCardExact();
    }

    try {
      final parts = imageUrl.split(',');
      if (parts.length <= 1 || parts[1].isEmpty) {
        print('⚠️ FloatingCard: Formato base64 inválido');
        return _buildDefaultCardExact();
      }

      final String base64Data = parts[1];
      Uint8List bytes;

      try {
        bytes = base64Decode(base64Data);
        print(
            '✅ FloatingCard: Base64 decodificado exitosamente, ${bytes.length} bytes');
      } catch (e) {
        print('❌ FloatingCard: Error decodificando base64: $e');
        return _buildDefaultCardExact();
      }

      return Container(
        width: _cardSize,
        height: _cardSize * 1.4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Colors.black12, // Color de fondo mientras carga
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('❌ FloatingCard: Error mostrando imagen: $error');
                return _buildDefaultCardExact();
              },
              gaplessPlayback: true, // Evita parpadeos durante la carga
            ),
            // Overlay sutil para dar profundidad
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ FloatingCard: Error general: $e');
      return _buildDefaultCardExact();
    }
  }

  Widget _buildDefaultCardExact() {
    return Container(
      width: _cardSize,
      height: _cardSize * 1.4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.floatingCard.cardData.color.withOpacity(0.7),
            widget.floatingCard.cardData.color.withOpacity(0.9),
          ],
        ),
        // Agregar un borde para mejor visibilidad
        border: Border.all(
          color: widget.floatingCard.cardData.color.withOpacity(0.8),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Icono principal centrado
          Center(
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withOpacity(0.9),
              size: _cardSize * 0.4,
            ),
          ),
          // Patrón de fondo sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                    widget.floatingCard.cardData.color.withOpacity(0.1),
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
