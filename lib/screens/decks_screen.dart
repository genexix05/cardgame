import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../models/card.dart' as card_model;
import '../services/firestore_service.dart';
import 'deck_builder_screen.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Deck> _decks = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, List<card_model.Card>> _deckCards = {};

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final decks = await _firestoreService.getUserDecks(user.uid);

      // Cargar las cartas para cada mazo
      for (final deck in decks) {
        final cards = await Future.wait(
            deck.cardIds.map((id) => _firestoreService.getCardById(id)));
        _deckCards[deck.id] = cards.whereType<card_model.Card>().toList();
      }

      setState(() {
        _decks = decks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar mazos: $e');
      setState(() {
        _error = 'Error al cargar los mazos. Por favor, intenta de nuevo.';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDeck(Deck deck) async {
    try {
      final success = await _firestoreService.deleteDeck(deck.id);
      if (success) {
        setState(() {
          _decks.removeWhere((d) => d.id == deck.id);
          _deckCards.remove(deck.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mazo eliminado correctamente'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el mazo: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _createNewDeck() async {
    final result = await Navigator.push<Deck>(
      context,
      MaterialPageRoute(
        builder: (context) => const DeckBuilderScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _decks.insert(0, result);
        _loadDecks(); // Recargar para obtener las cartas del nuevo mazo
      });
    }
  }

  Widget _buildCardImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Es una imagen en base64
      try {
        final String base64String = imageUrl.split(',')[1];
        final Uint8List bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 70,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 70,
              height: 100,
              color: Colors.grey[300],
              child: const Icon(Icons.error_outline),
            );
          },
        );
      } catch (e) {
        return Container(
          width: 70,
          height: 100,
          color: Colors.grey[300],
          child: const Icon(Icons.error_outline),
        );
      }
    } else {
      // Es una URL normal
      return Image.network(
        imageUrl,
        width: 70,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 70,
            height: 100,
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 70,
            height: 100,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    }
  }

  Widget _buildDeckCard(Deck deck) {
    final cards = _deckCards[deck.id] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          ListTile(
            title: Text(deck.name),
            subtitle: Text(
              'Creado: ${_formatDate(deck.createdAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // TODO: Implementar edición de mazo
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteConfirmation(deck),
                ),
              ],
            ),
          ),
          if (cards.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: _buildCardImage(card.imageUrl),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Deck deck) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mazo'),
        content: Text(
            '¿Estás seguro de que quieres eliminar el mazo "${deck.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDeck(deck);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Mazos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewDeck,
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
                        onPressed: _loadDecks,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : _decks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'No tienes mazos creados',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _createNewDeck,
                            child: const Text('Crear mi primer mazo'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: _decks.length,
                      itemBuilder: (context, index) {
                        final deck = _decks[index];
                        return _buildDeckCard(deck);
                      },
                    ),
    );
  }
}
