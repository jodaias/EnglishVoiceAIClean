import 'package:english_voice_ai_clean/features/voice_chat/infrastructure/local/database/daos/learning_units_dao.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_db_helper.dart';

void main() {
  test('lists ordered units and loads lessons', () async {
    final db = await openInMemoryTestDatabase();
    final dao = LearningUnitsDao(db);

    final units = await dao.listUnitsOrdered();
    expect(units, hasLength(2));
    expect(units.first.orderIndex, 0);

    final withLessons = await dao.listUnitsWithLessons();
    expect(withLessons.first.lessons, hasLength(3));
    expect(withLessons.last.lessons, hasLength(3));

    await db.close();
  });
}
