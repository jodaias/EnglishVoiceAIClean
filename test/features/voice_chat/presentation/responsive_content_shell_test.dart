import 'package:english_voice_ai_clean/features/voice_chat/presentation/responsive_content_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const targetKey = Key('responsive-target');

  Future<void> pumpShell(
    WidgetTester tester,
    double width, {
    ResponsiveContentProfile profile = ResponsiveContentProfile.premium,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    late final Widget shell;
    switch (profile) {
      case ResponsiveContentProfile.compact:
        shell = const ResponsiveContentShell.compact(
          child: SizedBox(
            key: targetKey,
            height: 100,
            width: double.infinity,
          ),
        );
        break;
      case ResponsiveContentProfile.balanced:
        shell = const ResponsiveContentShell(
          child: SizedBox(
            key: targetKey,
            height: 100,
            width: double.infinity,
          ),
        );
        break;
      case ResponsiveContentProfile.premium:
        shell = ResponsiveContentShell.premium(
          child: const SizedBox(
            key: targetKey,
            height: 100,
            width: double.infinity,
          ),
        );
        break;
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: shell,
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('premium profile keeps 940 max width at 1024px', (tester) async {
    await pumpShell(tester, 1024);

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 940);
    expect(rect.left, closeTo((1024 - 940) / 2, 0.1));
  });

  testWidgets('premium profile keeps 1024 max width at 1280px', (tester) async {
    await pumpShell(tester, 1280);

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 1024);
    expect(rect.left, closeTo((1280 - 1024) / 2, 0.1));
  });

  testWidgets('premium profile keeps 1120 max width at 1600px', (tester) async {
    await pumpShell(tester, 1600);

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 1120);
    expect(rect.left, closeTo((1600 - 1120) / 2, 0.1));
  });

  testWidgets('balanced profile keeps 960 max width at 1024px', (tester) async {
    await pumpShell(
      tester,
      1024,
      profile: ResponsiveContentProfile.balanced,
    );

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 960);
    expect(rect.left, closeTo((1024 - 960) / 2, 0.1));
  });

  testWidgets('balanced profile keeps 960 max width at 1280px', (tester) async {
    await pumpShell(
      tester,
      1280,
      profile: ResponsiveContentProfile.balanced,
    );

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 960);
    expect(rect.left, closeTo((1280 - 960) / 2, 0.1));
  });

  testWidgets('balanced profile keeps 1100 max width at 1600px',
      (tester) async {
    await pumpShell(
      tester,
      1600,
      profile: ResponsiveContentProfile.balanced,
    );

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 1100);
    expect(rect.left, closeTo((1600 - 1100) / 2, 0.1));
  });

  testWidgets('compact profile keeps 1024 max width at 1024px', (tester) async {
    await pumpShell(
      tester,
      1024,
      profile: ResponsiveContentProfile.compact,
    );

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 976);
    expect(rect.left, closeTo(24, 0.1));
  });

  testWidgets('compact profile keeps 1024 max width at 1280px', (tester) async {
    await pumpShell(
      tester,
      1280,
      profile: ResponsiveContentProfile.compact,
    );

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 1024);
    expect(rect.left, closeTo((1280 - 1024) / 2, 0.1));
  });

  testWidgets('compact profile keeps 1200 max width at 1600px', (tester) async {
    await pumpShell(
      tester,
      1600,
      profile: ResponsiveContentProfile.compact,
    );

    final rect = tester.getRect(find.byKey(targetKey));
    expect(rect.width, 1200);
    expect(rect.left, closeTo((1600 - 1200) / 2, 0.1));
  });
}
