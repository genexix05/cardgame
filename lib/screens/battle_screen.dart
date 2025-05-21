import 'package:flutter/material.dart';
import '../models/battle.dart';
import '../models/battle_card.dart';
import '../models/card.dart' as models;
import '../services/battle_service.dart';
import '../theme/index.dart'; // Importamos todos los temas
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

class BattleScreen extends StatefulWidget {
  final String battleId;
  final String currentPlayerId;

  const BattleScreen({
    super.key,
    required this.battleId,
    required this.currentPlayerId,
  });

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen>
    with SingleTickerProviderStateMixin {
  final BattleService _battleService = BattleService();
  BattleCard? _selectedCard;

  // Controlador para animaciones
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: GameEffects.medium,
      vsync: this,
    );

    // Iniciar animación
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Método seguro para mostrar imágenes (maneja URL y base64)
  Widget _buildSafeImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Es una imagen en formato base64
      try {
        final parts = imageUrl.split(',');
        if (parts.length <= 1) {
          // Base64 malformado, mostrar imagen por defecto
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 40),
          );
        }

        Uint8List? bytes;
        try {
          bytes = base64Decode(parts[1]);
        } catch (e) {
          print('Error decodificando base64: $e');
          // Decodificación fallida, mostrar imagen por defecto
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 40),
          );
        }

        // Si la decodificación fue exitosa, mostrar la imagen
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported, size: 40),
            );
          },
        );
      } catch (e) {
        print('Error general con imagen base64: $e');
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, size: 40),
        );
      }
    } else {
      // Es una URL normal
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 40),
          );
        },
      );
    }
  }

  // Construir barra de vida
  Widget _buildHealthBar(int currentHealth, int maxHealth) {
    final percentage = maxHealth > 0 ? currentHealth / maxHealth : 0.0;

    return Container(
      height: 12,
      width: double.infinity,
      decoration: BattleStyles.healthBarDecoration(percentage: percentage),
      child: Row(
        children: [
          AnimatedContainer(
            duration: GameEffects.medium,
            width: 80 * percentage,
            decoration:
                BattleStyles.healthFillDecoration(percentage: percentage),
          ),
        ],
      ),
    );
  }

  // Construir área de batalla
  Widget _buildBattleArea(
      List<BattleCard> cards, bool isPlayer, bool isPlayerTurn) {
    return AnimatedContainer(
      duration: GameEffects.medium,
      decoration: isPlayer
          ? BattleStyles.playerAreaDecoration
          : BattleStyles.opponentAreaDecoration,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del área
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isPlayer ? 'TU EQUIPO' : 'OPONENTE',
              style: GameStyles.gameSubtitle.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          // Cartas
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final isCharacter =
                    card.baseCard.type == models.CardType.character;
                final isSelected =
                    _selectedCard?.baseCard.id == card.baseCard.id;

                // Determinar rareza para aplicar estilo
                String rarity = 'common'; // Por defecto
                if (card.baseCard.rarity != null) {
                  // Convertir enum a string
                  switch (card.baseCard.rarity) {
                    case models.CardRarity.common:
                      rarity = 'common';
                      break;
                    case models.CardRarity.uncommon:
                      rarity = 'uncommon';
                      break;
                    case models.CardRarity.rare:
                      rarity = 'rare';
                      break;
                    case models.CardRarity.superRare:
                      rarity = 'super_rare';
                      break;
                    case models.CardRarity.legendary:
                      rarity = 'legendary';
                      break;
                    default:
                      rarity = 'common';
                  }
                }

                Widget cardWidget = CardStyles.card3D(
                  rarity: rarity,
                  child: Container(
                    decoration: CardStyles.cardDecoration(rarity: rarity),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildSafeImage(card.baseCard.imageUrl),
                        ),
                        // Tipo de carta
                        if (isCharacter)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.8),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Personaje',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Información de la carta en la parte inferior
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: CardStyles.glassInfoContainer,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  card.baseCard.name,
                                  style: CardStyles.cardName
                                      .copyWith(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                _buildHealthBar(
                                    card.currentHealth, card.currentHealth),
                                const SizedBox(height: 2),
                                Text(
                                  'ATK: ${card.currentAttack}',
                                  style: CardStyles.cardStats
                                      .copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                // Si está seleccionada, aplicar animación
                if (isSelected && isPlayer) {
                  cardWidget =
                      BattleStyles.selectedCardAnimation(child: cardWidget);
                }

                // Si es jugador y es su turno, permitir selección
                if (isPlayer && isPlayerTurn) {
                  return GestureDetector(
                    onTap: isCharacter
                        ? () {
                            setState(() {
                              _selectedCard = isSelected ? null : card;
                            });
                          }
                        : null,
                    child: cardWidget,
                  );
                } else {
                  return cardWidget;
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Método para realizar acciones
  void _performAction(Battle battle, BattleAction action) async {
    if (_selectedCard == null) return;

    try {
      await _battleService.performAction(
        battle.id,
        widget.currentPlayerId,
        action,
        cardId: _selectedCard!.baseCard.id, // cardId como parámetro nombrado
      );

      // Reiniciar selección después de la acción
      setState(() {
        _selectedCard = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Para efectos visuales
      appBar: AppBar(
        title: const Text('Batalla'),
        backgroundColor: Colors.black54,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/battle_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: StreamBuilder<Battle?>(
          stream: Stream.fromFuture(_battleService.getBattle(widget.battleId)),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Container(
                  decoration: GameStyles.glassPanel(baseColor: Colors.red),
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: GameStyles.gameSubtitle,
                  ),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(GameTheme.primaryColor),
                ),
              );
            }

            final battle = snapshot.data!;
            final isPlayer1 = widget.currentPlayerId == battle.player1Id;
            final playerCards =
                isPlayer1 ? battle.player1Cards : battle.player2Cards;
            final opponentCards =
                isPlayer1 ? battle.player2Cards : battle.player1Cards;
            final isPlayerTurn =
                battle.currentTurnPlayerId == widget.currentPlayerId;

            return FadeTransition(
              opacity: _animationController,
              child: SafeArea(
                child: Column(
                  children: [
                    // Área del oponente
                    Expanded(
                      child:
                          _buildBattleArea(opponentCards, false, isPlayerTurn),
                    ),

                    // Panel de información de batalla
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BattleStyles.battleInfoPanelDecoration,
                      child: Column(
                        children: [
                          // Estado de la batalla
                          Text(
                            battle.state == BattleState.inProgress
                                ? isPlayerTurn
                                    ? '¡TU TURNO!'
                                    : 'TURNO DEL OPONENTE'
                                : 'BATALLA FINALIZADA',
                            style: BattleStyles.turnText,
                          ),
                          const SizedBox(height: 8),
                          // Botones de acción
                          if (battle.state == BattleState.inProgress &&
                              isPlayerTurn)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Botón de ataque
                                GestureDetector(
                                  onTap: _selectedCard == null
                                      ? null
                                      : () => _performAction(
                                          battle, BattleAction.attack),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 10),
                                    decoration:
                                        BattleStyles.actionButtonDecoration(
                                      isActive: _selectedCard != null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.flash_on,
                                          color: Colors.white,
                                          size: 20,
                                          shadows: [
                                            Shadow(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              blurRadius: 3,
                                              offset: const Offset(1, 1),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ATACAR',
                                          style: BattleStyles.actionText,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Área del jugador
                    Expanded(
                      child: _buildBattleArea(playerCards, true, isPlayerTurn),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
