import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';

void main() {
  testWidgets('Should override synchronously', (tester) async {
    StateNotifier? firstFrameNotifier;
    final scope = RefenaScope(
      overrides: [
        _provider.overrideWithInitialState((ref) => 'overridden'),
      ],
      child: _MyApp(
        onNotifier: (n) => firstFrameNotifier = n,
      ),
    );

    await tester.pumpWidget(scope);

    await scope.ensureOverrides();

    // The override should be already applied to the first frame since
    // even if the override is not yet applied. The lazy initialization
    // also checks if there is an override first.
    expect(find.text('overridden'), findsOneWidget);
    expect(find.text('original'), findsNothing);

    // The notifier should be only initialized **ONCE**.
    // If the following expect fails, then the override is happening **AFTER**
    // the first frame which causes the first frame to create a new notifier
    // just to be replaced by the override procedure shortly after.
    expect(firstFrameNotifier?.hashCode, scope.notifier(_provider).hashCode);
  });
}

final _provider = StateProvider((ref) => 'original');

// ignore: must_be_immutable
class _MyApp extends StatelessWidget {
  final void Function(StateNotifier notifier) onNotifier;
  bool firstFrame = true;

  _MyApp({
    required this.onNotifier,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.watch(_provider);
    if (firstFrame) {
      firstFrame = false;
      final notifier = context.notifier(_provider);
      onNotifier(notifier);
    }
    return MaterialApp(
      home: Scaffold(
        body: Text(text),
      ),
    );
  }
}
