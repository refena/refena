import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena/src/ref.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';

void main() {
  testWidgets('Ref.watch should still return state after dispose',
      (tester) async {
    // ignore: invalid_use_of_internal_member
    WatchableRefImpl? watchableRef;
    final ref = RefenaScope(
      child: MaterialApp(
        home: _SwitchWidget(
          // ignore: invalid_use_of_internal_member
          onRef: (ref) => watchableRef = ref as WatchableRefImpl,
        ),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.read(_stateProvider), 10);
    expect(tester.widget<Text>(find.byType(Text)).data, 'Number 10');

    ref.notifier(_stateProvider).setState((value) => value + 1);
    expect(ref.read(_stateProvider), 11);

    await tester.pump();
    expect(tester.widget<Text>(find.byType(Text)).data, 'Number 11');

    ref.notifier(_switchProvider).setState((value) => false);

    await tester.pump();
    expect(find.byType(Text), findsNothing);

    expect(watchableRef!.rebuildable.disposed, true);

    // This should not throw an exception
    printWarning = false;
    // ignore: invalid_use_of_internal_member
    ref.notifier(_stateProvider).cleanupListeners();
    expect(watchableRef!.watch(_stateProvider), 11);

    // ignore: invalid_use_of_internal_member
    expect(ref.notifier(_stateProvider).getListeners(), isEmpty);
  });
}

final _stateProvider = StateProvider((ref) => 10);
final _switchProvider = StateProvider((ref) => true);

class _SwitchWidget extends StatelessWidget {
  final void Function(WatchableRef ref) onRef;

  const _SwitchWidget({
    required this.onRef,
  });

  @override
  Widget build(BuildContext context) {
    if (context.watch(_switchProvider)) {
      return _MyWidget(onRef: onRef);
    } else {
      return const SizedBox();
    }
  }
}

class _MyWidget extends StatelessWidget {
  final void Function(WatchableRef ref) onRef;

  const _MyWidget({
    required this.onRef,
  });

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    onRef(ref);
    return Scaffold(
      body: Center(
        child: Text('Number ${ref.watch(_stateProvider)}'),
      ),
    );
  }
}
