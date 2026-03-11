import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/lesson_exercise.dart';

abstract class ExerciseGenerationCache {
  Future<LessonExercise?> get(String key);
  Future<void> put(String key, LessonExercise exercise);
}

class HiveExerciseGenerationCache implements ExerciseGenerationCache {
  static const String _boxName = 'exercise_generation_cache_v1';

  @override
  Future<LessonExercise?> get(String key) async {
    final box = await _openBox();
    final raw = box.get(key)?.toString();
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final exerciseJson = decoded['exercise'];
      if (exerciseJson is! Map<String, dynamic>) {
        return null;
      }

      return LessonExercise.fromJson(exerciseJson);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> put(String key, LessonExercise exercise) async {
    final box = await _openBox();
    final payload = <String, dynamic>{
      'generatedAt': DateTime.now().toIso8601String(),
      'exercise': exercise.toJson(),
    };
    await box.put(key, jsonEncode(payload));
  }

  Future<Box<dynamic>> _openBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }
}
