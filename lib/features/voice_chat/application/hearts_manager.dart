class HeartsState {
  final int currentHearts;
  final DateTime? refillAt;

  const HeartsState({
    required this.currentHearts,
    required this.refillAt,
  });
}

class HeartsManager {
  final int maxHearts;
  final Duration refillCooldown;
  final bool relaxedMode;

  int _currentHearts;
  DateTime? _refillAt;

  HeartsManager({
    this.maxHearts = 5,
    this.refillCooldown = const Duration(minutes: 30),
    this.relaxedMode = false,
    int? initialHearts,
    DateTime? initialRefillAt,
  })  : _currentHearts = (initialHearts ?? maxHearts).clamp(0, maxHearts),
        _refillAt = initialRefillAt;

  HeartsState get state => HeartsState(
        currentHearts: relaxedMode ? maxHearts : _currentHearts,
        refillAt: _refillAt,
      );

  bool get canContinue => relaxedMode || _currentHearts > 0;

  bool consumeHeart(DateTime now) {
    if (relaxedMode) {
      return true;
    }

    _applyRefillIfNeeded(now);

    if (_currentHearts <= 0) {
      return false;
    }

    _currentHearts -= 1;
    if (_currentHearts == 0) {
      _refillAt = now.add(refillCooldown);
    }
    return true;
  }

  void restoreAll() {
    _currentHearts = maxHearts;
    _refillAt = null;
  }

  void tick(DateTime now) {
    if (relaxedMode) {
      return;
    }
    _applyRefillIfNeeded(now);
  }

  void _applyRefillIfNeeded(DateTime now) {
    final refillAt = _refillAt;
    if (refillAt == null) {
      return;
    }
    if (!now.isBefore(refillAt)) {
      _currentHearts = maxHearts;
      _refillAt = null;
    }
  }
}
