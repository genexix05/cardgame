import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/deck.dart';
import '../models/card.dart';
import 'firestore_service.dart';

class DeckService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Colección de mazos
  CollectionReference get _decksCollection => _firestore.collection('decks');

  // Obtener todos los mazos de un usuario
  Future<List<Deck>> getUserDecks(String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('El ID del usuario no puede estar vacío');
      }

      // Consulta temporal sin ordenamiento mientras se crea el índice
      final QuerySnapshot snapshot =
          await _decksCollection.where('userId', isEqualTo: userId).get();

      final decks = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Deck.fromMap({...data, 'id': doc.id});
      }).toList();

      // Ordenar manualmente por lastModified
      decks.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      return decks;
    } catch (e) {
      print('Error al obtener mazos del usuario: $e');
      if (e is FirebaseException) {
        if (e.code == 'failed-precondition') {
          print('Se requiere crear un índice compuesto en Firestore');
          print(
              'Por favor, crea el índice con los campos: userId (Ascending) y lastModified (Descending)');
        }
      }
      rethrow;
    }
  }

  // Crear un nuevo mazo
  Future<Deck?> createDeck(
      String userId, String name, List<String> cardIds) async {
    try {
      if (userId.isEmpty) {
        throw Exception('El ID del usuario no puede estar vacío');
      }
      if (name.isEmpty) {
        throw Exception('El nombre del mazo no puede estar vacío');
      }
      if (cardIds.isEmpty) {
        throw Exception('El mazo debe contener al menos una carta');
      }

      print('Creando mazo:');
      print('- Nombre: $name');
      print('- Cartas: ${cardIds.join(", ")}');

      // Obtener las cartas para validar el mazo
      final List<Card> cards = await _firestoreService.getAllCards();
      print('Cartas obtenidas: ${cards.length}');

      final deck = Deck(
        id: '',
        name: name,
        userId: userId,
        cardIds: cardIds,
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      );

      if (!deck.isValid(cards)) {
        throw Exception('El mazo no cumple con las restricciones');
      }

      print('Mazo válido, guardando en Firestore...');
      final docRef = await _decksCollection.add(deck.toMap());
      print('Mazo guardado con ID: ${docRef.id}');

      return deck.copyWith(id: docRef.id);
    } catch (e) {
      print('Error al crear mazo: $e');
      rethrow;
    }
  }

  // Actualizar un mazo existente
  Future<bool> updateDeck(Deck deck) async {
    try {
      if (deck.id.isEmpty) {
        throw Exception('El ID del mazo no puede estar vacío');
      }

      final List<Card> cards = await _firestoreService.getAllCards();
      if (!deck.isValid(cards)) {
        throw Exception('El mazo no cumple con las restricciones');
      }

      await _decksCollection.doc(deck.id).update(deck.toMap());
      return true;
    } catch (e) {
      print('Error al actualizar mazo: $e');
      rethrow;
    }
  }

  // Eliminar un mazo
  Future<bool> deleteDeck(String deckId) async {
    try {
      if (deckId.isEmpty) {
        throw Exception('El ID del mazo no puede estar vacío');
      }

      await _decksCollection.doc(deckId).delete();
      return true;
    } catch (e) {
      print('Error al eliminar mazo: $e');
      rethrow;
    }
  }

  // Obtener un mazo por ID
  Future<Deck?> getDeckById(String deckId) async {
    try {
      if (deckId.isEmpty) {
        throw Exception('El ID del mazo no puede estar vacío');
      }

      final DocumentSnapshot doc = await _decksCollection.doc(deckId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Deck.fromMap({...data, 'id': doc.id});
      }
      return null;
    } catch (e) {
      print('Error al obtener mazo: $e');
      rethrow;
    }
  }
}
