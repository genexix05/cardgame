import 'package:flutter_test/flutter_test.dart';
import 'package:cardgame/models/card.dart';
import 'package:cardgame/models/card_pack.dart';
import 'package:cardgame/models/user_collection.dart';

void main() {
  group('Modelos de datos', () {
    test('Card debe crearse correctamente', () {
      final card = Card(
        id: '1',
        name: 'Carta de prueba',
        description: 'Esta es una carta de prueba',
        imageUrl: 'https://example.com/image.jpg',
        rarity: CardRarity.rare,
        type: CardType.character,
        power: 100,
        series: 'Serie de prueba',
      );

      expect(card.id, '1');
      expect(card.name, 'Carta de prueba');
      expect(card.rarity, CardRarity.rare);
      expect(card.type, CardType.character);
    });

    test('UserCard debe crearse correctamente', () {
      final userCard = UserCard(
        cardId: '1',
        quantity: 3,
        isForSale: false,
        isFavorite: true,
      );

      expect(userCard.cardId, '1');
      expect(userCard.quantity, 3);
      expect(userCard.isForSale, false);
      expect(userCard.isFavorite, true);
    });

    test('UserCollection debe crearse correctamente', () {
      final userCards = {
        '1': UserCard(cardId: '1', quantity: 3),
        '2': UserCard(cardId: '2', quantity: 1),
      };

      final collection = UserCollection(
        userId: 'user1',
        cards: userCards,
        coins: 1000,
        gems: 50,
      );

      expect(collection.userId, 'user1');
      expect(collection.cards.length, 2);
      expect(collection.cards['1']?.quantity, 3);
      expect(collection.coins, 1000);
      expect(collection.gems, 50);
    });

    test('UserCollection.addCard debe funcionar correctamente', () {
      final collection = UserCollection(
        userId: 'user1',
        cards: {
          '1': UserCard(cardId: '1', quantity: 1),
        },
        coins: 1000,
        gems: 50,
      );

      // Añadir carta existente
      final updatedCollection1 = collection.addCard('1');
      expect(updatedCollection1.cards['1']?.quantity, 2);

      // Añadir carta nueva
      final updatedCollection2 = updatedCollection1.addCard('2');
      expect(updatedCollection2.cards['2']?.quantity, 1);
      expect(updatedCollection2.cards.length, 2);
    });

    test('CardPack debe crearse correctamente', () {
      final pack = CardPack(
        id: 'pack1',
        name: 'Sobre básico',
        imageUrl: 'https://example.com/pack.jpg',
        description: 'Un sobre básico',
        type: CardPackType.basic,
        cardCount: 5,
        price: 100,
        currency: CardPackCurrency.coins,
      );

      expect(pack.id, 'pack1');
      expect(pack.name, 'Sobre básico');
      expect(pack.type, CardPackType.basic);
      expect(pack.cardCount, 5);
      expect(pack.price, 100);
      expect(pack.currency, CardPackCurrency.coins);
    });
  });
}
