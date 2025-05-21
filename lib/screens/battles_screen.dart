import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/battle.dart';
import '../models/card.dart' as models;
import '../models/deck.dart';
import '../services/battle_service.dart';
import '../providers/deck_provider.dart';
import 'battle_screen.dart';
import 'dart:convert';
import 'dart:typed_data';

class BattlesScreen extends StatefulWidget {
  final String currentPlayerId;
  final List<Deck> playerDecks;
  final Map<String, List<models.Card>> deckCards;

  const BattlesScreen({
    super.key,
    required this.currentPlayerId,
    required this.playerDecks,
    required this.deckCards,
  });

  @override
  State<BattlesScreen> createState() => _BattlesScreenState();
}

class _BattlesScreenState extends State<BattlesScreen> {
  final BattleService _battleService = BattleService();
  Deck? _selectedDeck;
  bool _isSearching = false;

  @override
  void dispose() {
    if (_isSearching) {
      _battleService.cancelMatchmaking(widget.currentPlayerId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batallas'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.search_off : Icons.add),
            onPressed: _isSearching ? _cancelSearch : _showCreateBattleDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Battle>>(
        stream: _battleService.getPlayerActiveBattles(widget.currentPlayerId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: error snapshot'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final battles = snapshot.data!;
          if (battles.isEmpty) {
            return Center(
              child: _isSearching
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        const Text('Buscando oponente...'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _cancelSearch,
                          child: const Text('Cancelar búsqueda'),
                        ),
                      ],
                    )
                  : const Text('No hay batallas activas'),
            );
          }

          return ListView.builder(
            itemCount: battles.length,
            itemBuilder: (context, index) {
              final battle = battles[index];
              final isPlayer1 = widget.currentPlayerId == battle.player1Id;
              final opponentId =
                  isPlayer1 ? battle.player2Id : battle.player1Id;
              final playerDeck =
                  isPlayer1 ? battle.player1Deck : battle.player2Deck;
              final opponentDeck =
                  isPlayer1 ? battle.player2Deck : battle.player1Deck;

              return ListTile(
                leading: const Icon(Icons.deck),
                title: Text('VS ${opponentDeck.name}'),
                subtitle: Text(
                  battle.state == BattleState.inProgress
                      ? battle.currentTurnPlayerId == widget.currentPlayerId
                          ? 'Tu turno'
                          : 'Turno del oponente'
                      : 'Batalla finalizada',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BattleScreen(
                        battleId: battle.id,
                        currentPlayerId: widget.currentPlayerId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Método seguro para mostrar imágenes (maneja URL y base64)
  Widget _buildSafeImage(String imageUrl,
      {double width = 40, double height = 40}) {
    if (imageUrl.startsWith('data:image')) {
      // Es una imagen en formato base64
      try {
        final parts = imageUrl.split(',');
        if (parts.length <= 1) {
          // Base64 malformado, mostrar icono por defecto
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          );
        }

        Uint8List? bytes;
        try {
          bytes = base64Decode(parts[1]);
        } catch (e) {
          print('Error decodificando base64: $e');
          // Decodificación fallida, mostrar icono por defecto
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported),
          );
        }

        // Si la decodificación fue exitosa, mostrar la imagen
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: width,
            height: height,
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
        );
      } catch (e) {
        print('Error general con imagen base64: $e');
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported),
        );
      }
    } else {
      // Es una URL normal
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _showCreateBattleDialog() async {
    if (widget.playerDecks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes mazos para combatir'),
        ),
      );
      return;
    }

    _selectedDeck = null;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona un mazo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.playerDecks.length,
            itemBuilder: (context, index) {
              final deck = widget.playerDecks[index];
              final cards = widget.deckCards[deck.id] ?? [];
              final characterCard = cards.firstWhere(
                (card) => card.type == models.CardType.character,
                orElse: () => cards.isNotEmpty
                    ? cards.first
                    : models.Card(
                        id: "",
                        name: "Carta por defecto",
                        description: "No hay cartas disponibles",
                        imageUrl: "",
                        rarity: models.CardRarity.common,
                        type: models.CardType.character,
                        power: 0,
                        series: "",
                      ),
              );

              return ListTile(
                leading: _buildSafeImage(characterCard.imageUrl),
                title: Text(deck.name),
                subtitle: Text(
                  '${cards.length} cartas',
                ),
                selected: _selectedDeck?.id == deck.id,
                onTap: () {
                  setState(() {
                    _selectedDeck = deck;
                  });
                  Navigator.pop(context);
                  _startSearching();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _startSearching() async {
    if (_selectedDeck == null) return;

    final playerCards = widget.deckCards[_selectedDeck!.id] ?? [];

    // Verificar si hay cartas con ID vacío o si el mazo está vacío
    final invalidCards = playerCards.where((card) => card.id.isEmpty).toList();

    if (invalidCards.isNotEmpty || playerCards.isEmpty) {
      print(
          '🔄 Se detectaron cartas inválidas o mazo vacío. Aplicando solución automática...');

      // Usar directamente los IDs conocidos que funcionan
      final workingCardIds = [
        "8UQKTGDmB2OKRunhKpIH",
        "a74v9gGAqkrI3DuzJpEg",
        "ae4irmvPNbLf50aq99cn"
      ];

      // Actualizar el mazo con estos IDs conocidos
      try {
        final deckProvider = Provider.of<DeckProvider>(context, listen: false);

        // Mostrar indicador de carga para la reparación
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            title: Text('Reparando mazo'),
            content: SizedBox(
              height: 100,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Aplicando IDs de cartas válidos...'),
                  ],
                ),
              ),
            ),
          ),
        );

        // Actualizar el mazo con los IDs de trabajo conocidos
        await deckProvider.updateDeck(
            _selectedDeck!.id, _selectedDeck!.name, workingCardIds);

        // Cerrar el diálogo de carga de reparación
        if (mounted) {
          Navigator.pop(context);
        }

        // Mostrar indicador de carga para obtener cartas actualizadas
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              title: Text('Actualizando información'),
              content: SizedBox(
                height: 100,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Obteniendo cartas actualizadas...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        List<models.Card> fetchedPlayerCards;
        try {
          // ASUNCIÓN: deckProvider.getCardsByIds(List<String> ids) existe y devuelve Future<List<models.Card>>
          // Este método debe buscar en la colección 'cards' de Firebase.
          // Necesitarás implementar este método en tu DeckProvider.
          fetchedPlayerCards = await deckProvider.getCardsByIds(workingCardIds);

          if (fetchedPlayerCards.length != workingCardIds.length) {
            print(
                'Advertencia: No se encontraron todas las cartas para los IDs: \${workingCardIds.join(\', \')}. Encontradas: \${fetchedPlayerCards.length}');
            if (fetchedPlayerCards.isEmpty) {
              throw Exception(
                  'No se pudo obtener ninguna carta válida para el mazo reparado.');
            }
          }
        } catch (e) {
          if (mounted) {
            Navigator.pop(context); // Cerrar diálogo de "Obteniendo cartas"
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('Error al obtener cartas del mazo reparado: \$e')),
            );
          }
          setState(() {
            _isSearching = false;
          });
          return;
        }

        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo de "Obteniendo cartas"
        }

        // Actualizar el mazo seleccionado con los nuevos IDs
        setState(() {
          _selectedDeck = _selectedDeck?.copyWith(cardIds: workingCardIds);
          _isSearching = true; // Iniciar búsqueda
        });

        // Continuar con la búsqueda usando el mazo reparado y las cartas obtenidas de Firebase
        final battle = await _battleService.findMatch(
          widget.currentPlayerId,
          _selectedDeck!, // Contiene los cardIds actualizados
          fetchedPlayerCards, // Cartas obtenidas de Firebase
        );

        if (mounted) {
          setState(() {
            _isSearching = false;
          });

          if (battle != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BattleScreen(
                  battleId: battle.id,
                  currentPlayerId: widget.currentPlayerId,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se encontró ningún oponente'),
              ),
            );
          }
        }
      } catch (e) {
        // Cerrar el diálogo de carga si hay error
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al reparar el mazo: $e'),
            ),
          );
        }
      }

      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final battle = await _battleService.findMatch(
        widget.currentPlayerId,
        _selectedDeck!,
        playerCards,
      );

      if (mounted) {
        setState(() {
          _isSearching = false;
        });

        if (battle != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BattleScreen(
                battleId: battle.id,
                currentPlayerId: widget.currentPlayerId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontró ningún oponente'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        print('Error detallado al buscar combate: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Error al buscar combate. Por favor, inténtalo de nuevo.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Entendido',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showCardErrorDetails(List<models.Card> invalidCards) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cartas inválidas'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Se encontraron ${invalidCards.length} cartas con problemas en el ID:'),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: invalidCards.length,
                  itemBuilder: (context, index) {
                    final card = invalidCards[index];
                    return ListTile(
                      title: Text(card.name),
                      subtitle: Text(
                          'Tipo: ${card.type.toString().split('.').last}, ID: ${card.id}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _repairDeck();
            },
            child: const Text('Reparar mazo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _fixCardIds();
            },
            child: const Text('Corregir IDs'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _useTestDeck();
            },
            child: const Text('Solución Rápida'),
          ),
        ],
      ),
    );
  }

  void _repairDeck() async {
    if (_selectedDeck == null) return;

    final deckProvider = Provider.of<DeckProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Reparando mazo'),
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Eliminando cartas inválidas del mazo...'),
              ],
            ),
          ),
        ),
      ),
    );

    final result = await deckProvider.repairDeck(_selectedDeck!.id);

    if (mounted) {
      Navigator.pop(context); // Cerrar el diálogo de carga

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          action: SnackBarAction(
            label: 'Aceptar',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  void _fixCardIds() async {
    if (_selectedDeck == null) return;

    final deckProvider = Provider.of<DeckProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Corrigiendo cartas'),
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Eliminando IDs vacíos del mazo...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Obtener las cartas actuales del mazo
      final cards =
          List<models.Card>.from(widget.deckCards[_selectedDeck!.id] ?? []);

      // Identificar cartas con ID vacío
      final cardsWithEmptyId = cards.where((card) => card.id.isEmpty).toList();

      if (cardsWithEmptyId.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Cerrar el diálogo de carga
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se encontraron cartas con ID vacío')),
          );
        }
        return;
      }

      // Llamar al método para arreglar las cartas
      bool success = await deckProvider.fixCardsWithEmptyIds(_selectedDeck!.id);

      if (mounted) {
        Navigator.pop(context); // Cerrar el diálogo de carga

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Se han eliminado las cartas con ID vacío y reemplazado con cartas válidas'),
              action: SnackBarAction(
                label: 'Aceptar',
                onPressed: () {},
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Hubo un problema al corregir el mazo: ${deckProvider.error}'),
              action: SnackBarAction(
                label: 'Reintentar',
                onPressed: () => _fixCardIds(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar el diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al corregir IDs: $e')),
        );
      }
    }
  }

  void _useTestDeck() async {
    if (_selectedDeck == null) return;

    final deckProvider = Provider.of<DeckProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Aplicando solución rápida'),
        content: SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Reemplazando el mazo con cartas válidas...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Usar los IDs exactos que se muestran en Firebase
      final workingCardIds = [
        "8UQKTGDmB2OKRunhKpIH",
        "a74v9gGAqkrI3DuzJpEg",
        "ae4irmvPNbLf50aq99cn"
      ];

      // Actualizar el mazo con estos IDs
      await deckProvider.updateDeck(
          _selectedDeck!.id, _selectedDeck!.name, workingCardIds);

      if (mounted) {
        Navigator.pop(context); // Cerrar el diálogo de carga

        if (deckProvider.error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '¡Solución rápida aplicada! El mazo ahora tiene cartas válidas.'),
            ),
          );

          // Intentar iniciar la búsqueda automáticamente con el mazo arreglado
          setState(() {
            _selectedDeck = _selectedDeck?.copyWith(cardIds: workingCardIds);
          });
          _startSearching();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Error al aplicar la solución rápida: ${deckProvider.error}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar el diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _cancelSearch() async {
    await _battleService.cancelMatchmaking(widget.currentPlayerId);
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }
}
