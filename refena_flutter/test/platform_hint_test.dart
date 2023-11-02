import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/scope.dart';

void main() {
  setUp(() {
    PlatformHintProvider.instance = _MockPlatformHintProvider(PlatformHint.web);
  });

  testWidgets('Should set platform hint in implicit container', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: Container(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.platformHint, PlatformHint.web);
  });

  testWidgets('Should set platform hint from constructor', (tester) async {
    final ref = RefenaScope(
      platformHint: PlatformHint.windows,
      child: MaterialApp(
        home: Container(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.platformHint, PlatformHint.windows);
  });

  testWidgets('Should set platform hint in explicit container', (tester) async {
    final container = RefenaContainer();

    final ref = RefenaScope.withContainer(
      container: container,
      child: MaterialApp(
        home: Container(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.platformHint, PlatformHint.web);
  });

  testWidgets('Should set platform hint from constructor (ex)', (tester) async {
    final container = RefenaContainer();

    final ref = RefenaScope.withContainer(
      container: container,
      platformHint: PlatformHint.windows,
      child: MaterialApp(
        home: Container(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.platformHint, PlatformHint.windows);
  });

  testWidgets('Should not override platform when already set', (tester) async {
    final container = RefenaContainer(
      platformHint: PlatformHint.windows,
    );

    final ref = RefenaScope.withContainer(
      container: container,
      child: MaterialApp(
        home: Container(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.platformHint, PlatformHint.windows);
  });
}

class _MockPlatformHintProvider extends PlatformHintProvider {
  final PlatformHint platformHint;

  _MockPlatformHintProvider(this.platformHint);

  @override
  PlatformHint getPlatformHint() => platformHint;
}
