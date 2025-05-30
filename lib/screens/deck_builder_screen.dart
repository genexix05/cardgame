import 'package:flutter/material.dart';
import '../models/card.dart' as card_model;
import '../services/deck_service.dart';
import '../services/firestore_service.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';

class DeckBuilderScreen extends StatefulWidget {
  static const String routeName = '/deck-builder';

  const DeckBuilderScreen({super.key});

  @override
  State<DeckBuilderScreen> createState() => _DeckBuilderScreenState();
}

class _DeckBuilderScreenState extends State<DeckBuilderScreen> {
  final DeckService _deckService = DeckService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _deckNameController = TextEditingController();

  List<card_model.Card> _allCards = [];
  final List<card_model.Card> _selectedCards = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      print('\nCargando colección del usuario...');
      final userCollection =
          await _firestoreService.getUserCollection(user.uid);
      if (userCollection == null) {
        throw Exception('No se pudo obtener la colección del usuario');
      }

      print(
          'Cartas en la colección del usuario: ${userCollection.cards.length}');

      // Obtener todas las cartas disponibles
      final allCards = await _firestoreService.getAllCards();
      print('Total de cartas disponibles: ${allCards.length}');

      // Filtrar solo las cartas que el usuario tiene
      final userCards = allCards.where((card) {
        final userCard = userCollection.cards[card.id];
        return userCard != null && userCard.quantity > 0;
      }).toList();

      print('Cartas del usuario filtradas: ${userCards.length}');

      // Validar que todas las cartas tienen ID
      final validCards = userCards.where((card) {
        if (card.id.isEmpty) {
          print('⚠️ Carta sin ID válido: ${card.name}');
          return false;
        }
        return true;
      }).toList();

      print('Cartas válidas del usuario: ${validCards.length}');

      setState(() {
        _allCards = validCards;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar las cartas: $e');
      setState(() {
        _error = 'Error al cargar las cartas. Por favor, intenta de nuevo.';
        _isLoading = false;
      });
    }
  }

  bool _canAddCard(card_model.Card card) {
    // Si ya está seleccionada, no se puede añadir
    if (_selectedCards.contains(card)) return false;

    // Si ya hay 3 cartas, no se puede añadir
    if (_selectedCards.length >= 3) return false;

    // Contar cartas por tipo
    Map<card_model.CardType, int> typeCount = {};
    for (var selectedCard in _selectedCards) {
      typeCount[selectedCard.type] = (typeCount[selectedCard.type] ?? 0) + 1;
    }
    typeCount[card.type] = (typeCount[card.type] ?? 0) + 1;

    // Verificar restricciones
    bool hasCharacter = typeCount[card_model.CardType.character] != null;
    bool tooManyCharacters =
        (typeCount[card_model.CardType.character] ?? 0) > 2;
    bool tooManySupports = (typeCount[card_model.CardType.support] ?? 0) > 2;
    bool tooManyEquipment = (typeCount[card_model.CardType.equipment] ?? 0) > 2;

    // Si es la primera carta, debe ser un personaje
    if (_selectedCards.isEmpty && card.type != card_model.CardType.character) {
      return false;
    }

    // Si no hay personajes y esta no es un personaje, no se puede añadir
    if (!hasCharacter && card.type != card_model.CardType.character) {
      return false;
    }

    // Verificar límites por tipo
    if (tooManyCharacters || tooManySupports || tooManyEquipment) {
      return false;
    }

    return true;
  }

  void _toggleCardSelection(card_model.Card card) {
    print('\nIntentando seleccionar carta:');
    print('- Nombre: ${card.name}');
    print('- ID: ${card.id}');
    print('- Tipo: ${card.type}');

    if (card.id.isEmpty) {
      print('⚠️ Error: La carta no tiene ID válido');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: La carta no tiene ID válido'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      if (_selectedCards.contains(card)) {
        print('Deseleccionando carta: ${card.name}');
        _selectedCards.remove(card);
      } else if (_canAddCard(card)) {
        print('Seleccionando carta: ${card.name}');
        _selectedCards.add(card);
      } else {
        String errorMessage = 'No se puede añadir esta carta porque:';
        if (_selectedCards.length >= 3) {
          errorMessage += '\n- El mazo ya tiene 3 cartas';
        } else if (_selectedCards.isEmpty &&
            card.type != card_model.CardType.character) {
          errorMessage += '\n- El mazo debe comenzar con un personaje';
        } else {
          Map<card_model.CardType, int> typeCount = {};
          for (var selectedCard in _selectedCards) {
            typeCount[selectedCard.type] =
                (typeCount[selectedCard.type] ?? 0) + 1;
          }
          typeCount[card.type] = (typeCount[card.type] ?? 0) + 1;

          if ((typeCount[card_model.CardType.character] ?? 0) > 2) {
            errorMessage += '\n- Ya hay 2 personajes en el mazo';
          }
          if ((typeCount[card_model.CardType.support] ?? 0) > 2) {
            errorMessage += '\n- Ya hay 2 soportes en el mazo';
          }
          if ((typeCount[card_model.CardType.equipment] ?? 0) > 2) {
            errorMessage += '\n- Ya hay 2 equipamientos en el mazo';
          }
        }

        print('❌ No se puede añadir la carta: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _saveDeck() async {
    if (_selectedCards.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El mazo debe tener exactamente 3 cartas'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_deckNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un nombre para el mazo'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Verificar que todas las cartas tienen ID
      for (var card in _selectedCards) {
        if (card.id.isEmpty) {
          throw Exception('Error: Una o más cartas no tienen ID válido');
        }
      }

      print('Guardando mazo con las siguientes cartas:');
      for (var card in _selectedCards) {
        print('- ${card.name} (ID: ${card.id}, Tipo: ${card.type})');
      }

      final cardIds = _selectedCards.map((card) => card.id).toList();
      print('IDs de cartas a guardar: ${cardIds.join(", ")}');

      final deck = await _deckService.createDeck(
        user.uid,
        _deckNameController.text,
        cardIds,
      );

      if (deck != null) {
        if (mounted) {
          Navigator.pop(context, deck);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar el mazo'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error al guardar el mazo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el mazo: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Constructor de Mazos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveDeck,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCards,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Nombre del mazo
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _deckNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre del mazo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    // Mazo actual
                    Container(
                      height: 150,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ...List.generate(3, (index) {
                            if (index < _selectedCards.length) {
                              final card = _selectedCards[index];
                              return _buildDeckCard(card);
                            }
                            return _buildEmptyDeckSlot();
                          }),
                        ],
                      ),
                    ),

                    // Contador de cartas
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Cartas seleccionadas: ${_selectedCards.length}/3',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),

                    // Lista de cartas disponibles
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: _allCards.length,
                        itemBuilder: (context, index) {
                          final card = _allCards[index];
                          final isSelected = _selectedCards.contains(card);
                          return _buildCardItem(card, isSelected);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDeckCard(card_model.Card card) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(
          color: _getRarityColor(card.rarity),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          _buildCardImage(card.imageUrl),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                card.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDeckSlot() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.add, color: Colors.grey),
      ),
    );
  }

  Widget _buildCardItem(card_model.Card card, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleCardSelection(card),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : _getRarityColor(card.rarity),
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            _buildCardImage(card.imageUrl),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Text(
                      card.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _getCardTypeName(card.type),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Es una imagen en base64
      try {
        final String base64String = imageUrl.split(',')[1];
        final Uint8List bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.error_outline),
              ),
            );
          },
        );
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.error_outline),
          ),
        );
      }
    } else {
      // Es una URL normal
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.error_outline),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }
  }

  Color _getRarityColor(card_model.CardRarity rarity) {
    switch (rarity) {
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

  String _getCardTypeName(card_model.CardType type) {
    switch (type) {
      case card_model.CardType.character:
        return 'Personaje';
      case card_model.CardType.support:
        return 'Soporte';
      case card_model.CardType.equipment:
        return 'Equipamiento';
      case card_model.CardType.event:
        return 'Evento';
    }
  }

  @override
  void dispose() {
    _deckNameController.dispose();
    super.dispose();
  }
}
