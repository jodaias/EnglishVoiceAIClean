import 'dart:io';

import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/lesson_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/unit_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/user_progress.dart';
import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/local_learning_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'learning_progress_hive_test_',
    );
    Hive.init(tempDir.path);
  });

  setUp(() async {
    if (Hive.isBoxOpen('voice_chat_local_v1')) {
      await Hive.box<dynamic>('voice_chat_local_v1').clear();
      await Hive.box<dynamic>('voice_chat_local_v1').close();
    }
    await Hive.deleteBoxFromDisk('voice_chat_local_v1');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns initial progress when repository is empty', () async {
    final repository = LocalLearningProgressRepository();

    final progress = await repository.getUserProgress();

    expect(progress.totalXp, 0);
    expect(progress.availableHearts, 5);
    expect(progress.units, isEmpty);
  });

  test('persists and restores user progress', () async {
    final repository = LocalLearningProgressRepository();

    final lesson = LessonProgress.empty('lesson_1').copyWith(
      isCompleted: true,
      bestScore: 100,
      xpEarned: 80,
      attempts: 1,
      completedAt: DateTime.utc(2026, 3, 11, 9, 30, 0),
    );
    final unit = UnitProgress.empty('unit_1', isUnlocked: true).copyWith(
      crowns: 1,
      lessons: <String, LessonProgress>{'lesson_1': lesson},
    );

    final toSave = UserProgress.initial().copyWith(
      units: <String, UnitProgress>{'unit_1': unit},
      totalXp: 250,
      availableHearts: 3,
      heartsRefillAt: DateTime.utc(2026, 3, 11, 10, 0, 0),
      streakDays: 7,
      lastCompletedDateKey: '2026-03-11',
    );

    await repository.saveUserProgress(toSave);

    final restored = await repository.getUserProgress();
    expect(restored.totalXp, 250);
    expect(restored.availableHearts, 3);
    expect(restored.streakDays, 7);
    expect(restored.units['unit_1']?.isUnlocked, isTrue);
    expect(restored.units['unit_1']?.lessons['lesson_1']?.isCompleted, isTrue);
    expect(restored.units['unit_1']?.lessons['lesson_1']?.bestScore, 100);
  });
}
