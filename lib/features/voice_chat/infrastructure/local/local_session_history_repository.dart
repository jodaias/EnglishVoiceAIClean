import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../application/session_history_repository.dart';
import '../../domain/entities/daily_challenge.dart';
import '../../domain/entities/daily_challenge_history.dart';
import '../../domain/entities/practice_session_record.dart';

class LocalSessionHistoryRepository implements SessionHistoryRepository {
  static const String _boxName = 'voice_chat_local_v1';
  static const String _sessionsKey = 'voice_chat_sessions_v1';
  static const String _dailyChallengeKey = 'voice_chat_daily_challenge_v1';
  static const String _dailyChallengeHistoryKey =
      'voice_chat_daily_challenge_history_v1';
  static const int _maxSessions = 120;

  @override
  Future<void> saveSession(PracticeSessionRecord session) async {
    final box = await _openBox();
    final sessions = await getSessions();
    final updated = <PracticeSessionRecord>[session, ...sessions];
    final trimmed = updated.take(_maxSessions).toList(growable: false);
    final raw = trimmed
        .map((entry) => jsonEncode(entry.toJson()))
        .toList(growable: false);
    await box.put(_sessionsKey, raw);
  }

  @override
  Future<List<PracticeSessionRecord>> getSessions() async {
    final box = await _openBox();
    final rawValue = box.get(_sessionsKey);
    final raw = _readStringList(rawValue);

    final parsed = <PracticeSessionRecord>[];
    for (final item in raw) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        parsed.add(PracticeSessionRecord.fromJson(map));
      } catch (_) {
        // Ignore malformed entries from older app versions.
      }
    }

    parsed.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return parsed;
  }

  @override
  Future<DailyChallenge> getDailyChallenge() async {
    final box = await _openBox();
    final now = DateTime.now();
    final dateKey = _dateKey(now);

    final raw = box.get(_dailyChallengeKey)?.toString();
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final challenge = DailyChallenge.fromJson(map);
        if (challenge.dateKey == dateKey) {
          return challenge;
        }
      } catch (_) {
        // Ignore malformed stored challenge and generate a fresh one.
      }
    }

    final generated = DailyChallenge(
      dateKey: dateKey,
      topic: _topicForDate(now),
      targetMinutes: 5 + (now.day % 4),
      isCompleted: false,
    );

    await box.put(_dailyChallengeKey, jsonEncode(generated.toJson()));
    return generated;
  }

  @override
  Future<void> markDailyChallengeCompleted({required String dateKey}) async {
    final box = await _openBox();
    final challenge = await getDailyChallenge();
    if (challenge.dateKey != dateKey) {
      return;
    }

    final updated = challenge.copyWith(isCompleted: true);
    await box.put(_dailyChallengeKey, jsonEncode(updated.toJson()));

    final history = await getDailyChallengeHistory();
    final updatedHistory = history.addDateKey(dateKey);
    await box.put(
        _dailyChallengeHistoryKey, jsonEncode(updatedHistory.toJson()));
  }

  @override
  Future<DailyChallengeHistory> getDailyChallengeHistory() async {
    final box = await _openBox();
    final raw = box.get(_dailyChallengeHistoryKey)?.toString();

    if (raw == null || raw.trim().isEmpty) {
      return const DailyChallengeHistory(completedDateKeys: <String>[]);
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return DailyChallengeHistory.fromJson(map);
    } catch (_) {
      return const DailyChallengeHistory(completedDateKeys: <String>[]);
    }
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  List<String> _readStringList(dynamic rawValue) {
    if (rawValue is List) {
      return rawValue.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _topicForDate(DateTime value) {
    const topics = <String>[
      'Daily routine',
      'Travel planning',
      'Restaurant order',
      'Job interview intro',
      'Small talk with neighbors',
      'Shopping conversation',
      'Phone call practice',
    ];

    return topics[value.weekday % topics.length];
  }
}
