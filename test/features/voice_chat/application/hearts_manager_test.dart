import 'package:english_voice_ai_clean/features/voice_chat/application/hearts_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consumes hearts until empty and sets refill time', () {
    final now = DateTime.utc(2026, 3, 11, 10, 0, 0);
    final manager = HeartsManager(
      maxHearts: 3,
      refillCooldown: const Duration(minutes: 30),
    );

    expect(manager.consumeHeart(now), isTrue);
    expect(manager.state.currentHearts, 2);

    expect(manager.consumeHeart(now), isTrue);
    expect(manager.state.currentHearts, 1);

    expect(manager.consumeHeart(now), isTrue);
    expect(manager.state.currentHearts, 0);
    expect(manager.state.refillAt, now.add(const Duration(minutes: 30)));

    expect(manager.consumeHeart(now), isFalse);
  });

  test('refills hearts after cooldown passes', () {
    final now = DateTime.utc(2026, 3, 11, 10, 0, 0);
    final manager = HeartsManager(
      maxHearts: 2,
      refillCooldown: const Duration(minutes: 10),
    );

    manager.consumeHeart(now);
    manager.consumeHeart(now);
    expect(manager.state.currentHearts, 0);

    manager.tick(now.add(const Duration(minutes: 9)));
    expect(manager.state.currentHearts, 0);

    manager.tick(now.add(const Duration(minutes: 10)));
    expect(manager.state.currentHearts, 2);
    expect(manager.state.refillAt, isNull);
  });

  test('relaxed mode does not consume hearts', () {
    final now = DateTime.utc(2026, 3, 11, 10, 0, 0);
    final manager = HeartsManager(
      maxHearts: 5,
      relaxedMode: true,
    );

    expect(manager.consumeHeart(now), isTrue);
    expect(manager.state.currentHearts, 5);
    expect(manager.canContinue, isTrue);
  });
}
