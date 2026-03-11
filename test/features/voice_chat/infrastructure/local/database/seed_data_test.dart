import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import 'test_db_helper.dart';

void main() {
  test('seed inserts integrity baseline for units, lessons and exercises',
      () async {
    final db = await openInMemoryTestDatabase();

    Future<int> count(String table) async {
      return Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $table')) ??
          0;
    }

    expect(await count('learning_units'), 2);
    expect(await count('lessons'), 6);
    expect(await count('exercises'), 36);
    expect(await count('unit_progress'), 2);
    expect(await count('lesson_progress'), 6);

    await db.close();
  });
}
