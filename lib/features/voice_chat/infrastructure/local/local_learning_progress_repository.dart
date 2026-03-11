import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../application/learning_progress_repository.dart';
import '../../domain/entities/user_progress.dart';

class LocalLearningProgressRepository implements LearningProgressRepository {
  static const String _boxName = 'voice_chat_local_v1';
  static const String _progressKey = 'voice_chat_learning_progress_v1';

  @override
  Future<UserProgress> getUserProgress() async {
    final box = await _openBox();
    final raw = box.get(_progressKey)?.toString();

    if (raw == null || raw.trim().isEmpty) {
      return const UserProgress.initial();
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProgress.fromJson(map);
    } catch (_) {
      return const UserProgress.initial();
    }
  }

  @override
  Future<void> saveUserProgress(UserProgress progress) async {
    final box = await _openBox();
    await box.put(_progressKey, jsonEncode(progress.toJson()));
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }
}
