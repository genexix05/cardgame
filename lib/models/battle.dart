import 'card.dart';
import 'battle_card.dart';
import 'deck.dart';

enum BattleState { waiting, inProgress, finished }

enum BattleAction { attack, defend }

class Battle {
  final String id;
  final String player1Id;
  final String player2Id;
  final Deck player1Deck;
  final Deck player2Deck;
  final List<BattleCard> player1Cards;
  final List<BattleCard> player2Cards;
  BattleState state;
  String currentTurnPlayerId;
  final Map<String, BattleAction> lastActions;
  String? winnerId;

  Battle({
    required this.id,
    required this.player1Id,
    required this.player2Id,
    required this.player1Deck,
    required this.player2Deck,
    required this.player1Cards,
    required this.player2Cards,
    this.state = BattleState.waiting,
    required this.currentTurnPlayerId,
    Map<String, BattleAction>? lastActions,
    this.winnerId,
  }) : lastActions =
            Map<String, BattleAction>.from(lastActions ?? const {}) {
    // Asegurarse de que al crear una batalla, su estado cambie a inProgress
    if (state == BattleState.waiting) {
      state = BattleState.inProgress;
    }
  }

  factory Battle.fromMap(Map<String, dynamic> map) {
    return Battle(
      id: map['id'],
      player1Id: map['player1Id'],
      player2Id: map['player2Id'],
      player1Deck: Deck.fromMap(map['player1Deck']),
      player2Deck: Deck.fromMap(map['player2Deck']),
      player1Cards: (map['player1Cards'] as List<dynamic>)
          .map((card) => BattleCard.fromMap(card))
          .toList(),
      player2Cards: (map['player2Cards'] as List<dynamic>)
          .map((card) => BattleCard.fromMap(card))
          .toList(),
      state: BattleState.values.firstWhere(
        (e) => e.toString() == 'BattleState.${map['state']}',
        orElse: () => BattleState.waiting,
      ),
      currentTurnPlayerId: map['currentTurnPlayerId'],
      lastActions: map['lastActions'] != null
          ? Map<String, BattleAction>.from(
              (map['lastActions'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(
                  key,
                  BattleAction.values.firstWhere(
                    (e) => e.toString() == 'BattleAction.$value',
                    orElse: () => BattleAction.attack,
                  ),
                ),
              ),
            )
          : {},
      winnerId: map['winnerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'player1Deck': player1Deck.toMap(),
      'player2Deck': player2Deck.toMap(),
      'player1Cards': player1Cards.map((card) => card.toMap()).toList(),
      'player2Cards': player2Cards.map((card) => card.toMap()).toList(),
      'state': state.toString().split('.').last,
      'currentTurnPlayerId': currentTurnPlayerId,
      'lastActions': lastActions.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'winnerId': winnerId,
    };
  }

  // Método para procesar una acción de combate
  void processAction(String playerId, BattleAction action, {String? cardId}) {
    if (state != BattleState.inProgress) return;
    if (playerId != currentTurnPlayerId) return;

    lastActions[playerId] = action;

    // Si ambos jugadores han realizado su acción, procesar el turno
    if (lastActions.length == 2) {
      _processTurn();
    } else {
      // Cambiar al siguiente jugador
      currentTurnPlayerId =
          currentTurnPlayerId == player1Id ? player2Id : player1Id;
    }
  }

  void _processTurn() {
    final player1Action = lastActions[player1Id];
    final player2Action = lastActions[player2Id];

    // Procesar ataque de jugador 1
    if (player1Action == BattleAction.attack &&
        player2Action == BattleAction.attack) {
      _processAttack(player1Cards, player2Cards);
      _processAttack(player2Cards, player1Cards);
    } else if (player1Action == BattleAction.attack &&
        player2Action == BattleAction.defend) {
      _processAttack(player1Cards, player2Cards, isDefending: true);
    } else if (player1Action == BattleAction.defend &&
        player2Action == BattleAction.attack) {
      _processAttack(player2Cards, player1Cards, isDefending: true);
    }

    // Verificar si hay un ganador
    _checkWinner();

    // Limpiar acciones y cambiar turno
    lastActions.clear();
    currentTurnPlayerId = player1Id;
  }

  void _processAttack(List<BattleCard> attackers, List<BattleCard> defenders,
      {bool isDefending = false}) {
    // Encontrar la carta de personaje activa
    final attacker = attackers
        .firstWhere((card) => card.baseCard.type == CardType.character);
    final defender = defenders
        .firstWhere((card) => card.baseCard.type == CardType.character);

    int damage = attacker.currentAttack;
    if (isDefending) {
      damage = (damage - defender.currentDefense).clamp(0, damage);
    }

    // Actualizar la vida del defensor
    defender.currentHealth = (defender.currentHealth - damage)
        .clamp(0, defender.baseCard.maxHealth ?? 0);
  }

  void _checkWinner() {
    BattleCard getCharacterCard(
        List<BattleCard> cards, String playerIdForDebug) {
      try {
        // Ensure there's at least one card to avoid exception on empty list if guard is bypassed
        if (cards.isEmpty) {
          print(
              "⚠️ Error: Card list is empty for player $playerIdForDebug in _checkWinner. Battle ID: $id.");
          // Return a dummy defeated card
          return BattleCard(
              baseCard: Card(
                  id: 'error_empty_list_char',
                  name: 'EmptyListCharacter',
                  description: '',
                  imageUrl: '',
                  rarity: CardRarity.common,
                  type: CardType.character,
                  series: '',
                  attack: 0,
                  defense: 0,
                  maxHealth: 1,
                  power: 0))
            ..currentHealth = 0;
        }
        return cards
            .firstWhere((card) => card.baseCard.type == CardType.character);
      } catch (e) {
        print(
            "⚠️ Error: No character card found for player $playerIdForDebug in _checkWinner. Player cards count: ${cards.length}. Battle ID: $id. Error: $e");
        // Return a dummy defeated card to prevent crash and likely mark player as defeated
        return BattleCard(
            baseCard: Card(
                id: 'error_no_char_card',
                name: 'ErrorCharacter',
                description: '',
                imageUrl: '',
                rarity: CardRarity.common,
                type: CardType.character,
                series: '',
                attack: 0,
                defense: 0,
                maxHealth: 1,
                power: 0))
          ..currentHealth = 0;
      }
    }

    final player1Character = getCharacterCard(player1Cards, player1Id);
    final player2Character = getCharacterCard(player2Cards, player2Id);

    // Check for winner, explicitly handle if both players reach 0 health simultaneously (draw or specific rule)
    bool p1Defeated = player1Character.currentHealth <= 0;
    bool p2Defeated = player2Character.currentHealth <= 0;

    if (p1Defeated && p2Defeated) {
      state = BattleState.finished;
      print(
          "Battle $id: Both players defeated. P1 health: ${player1Character.currentHealth}, P2 health: ${player2Character.currentHealth}.");
      winnerId = null; // Explicitly a draw if both are 0
      return; // Important to return here to avoid subsequent winner assignment
    }

    // If not a draw, then check individual defeats
    if (p1Defeated) {
      winnerId = player2Id;
      state = BattleState.finished;
    } else if (p2Defeated) {
      winnerId = player1Id;
      state = BattleState.finished;
    }
  }
}
