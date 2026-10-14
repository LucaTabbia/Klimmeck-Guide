import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/screens/auth/app_lifecycle_bridge.dart';

void main() {
  late AppLifecycleEventBus bus;
  late int backgrounded;
  late int foregrounded;

  setUp(() {
    bus = AppLifecycleEventBus();
    backgrounded = 0;
    foregrounded = 0;
    bus.backgrounded.listen((_) => backgrounded++);
    bus.foregrounded.listen((_) => foregrounded++);
  });

  tearDown(() => bus.close());

  Future<void> mountBridge(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      AppLifecycleBridge(bus: bus, child: const SizedBox()),
    );
  }

  void drive(WidgetTester tester, List<AppLifecycleState> states) {
    for (final state in states) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
  }

  const toBackground = [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ];
  const toForeground = [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ];

  testWidgets('a real background round trip emits both events once', (
    tester,
  ) async {
    await mountBridge(tester);

    drive(tester, toBackground);
    await tester.pump();
    expect(backgrounded, 1);
    expect(foregrounded, 0);

    drive(tester, toForeground);
    await tester.pump();
    expect(backgrounded, 1);
    expect(foregrounded, 1);
  });

  testWidgets('an inactive to resumed blip emits nothing', (tester) async {
    await mountBridge(tester);

    drive(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
    await tester.pump();

    expect(backgrounded, 0);
    expect(foregrounded, 0);
  });

  testWidgets('unmounting stops the translation', (tester) async {
    await mountBridge(tester);
    await tester.pumpWidget(const SizedBox());

    drive(tester, toBackground);
    drive(tester, toForeground);
    await tester.pump();

    expect(backgrounded, 0);
    expect(foregrounded, 0);
  });
}
