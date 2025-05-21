import 'card.dart';

class BattleCard {
  final Card baseCard;
  int currentHealth;
  int currentAttack;
  int currentDefense;

  BattleCard({
    required this.baseCard,
  })  : currentHealth = baseCard.maxHealth ?? 0,
        currentAttack = baseCard.attack ?? 0,
        currentDefense = baseCard.defense ?? 0;

  factory BattleCard.fromCard(Card card) {
    return BattleCard(baseCard: card);
  }

  Map<String, dynamic> toMap() {
    return {
      'baseCard': baseCard.toMap(),
      'currentHealth': currentHealth,
      'currentAttack': currentAttack,
      'currentDefense': currentDefense,
    };
  }

  factory BattleCard.fromMap(Map<String, dynamic> map) {
    return BattleCard(
      baseCard: Card.fromMap(map['baseCard']),
    )
      ..currentHealth = map['currentHealth'] ?? 0
      ..currentAttack = map['currentAttack'] ?? 0
      ..currentDefense = map['currentDefense'] ?? 0;
  }
}
