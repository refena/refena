import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart' as refena;
import 'package:refena_riverpod_extension/refena_riverpod_extension.dart';

final _refenaConstantProvider = refena.Provider((ref) => 100);
final _refenaProvider = refena.StateProvider((ref) => 111);
final _riverpodProvider = riverpod.StateProvider<int>((ref) {
  return 222 + ref.refena.read(_refenaConstantProvider);
});

class _Vm {
  final int refenaValue;
  final int riverpodValue;
  final void Function() incRefena;
  final void Function() incRiverpod;

  _Vm({
    required this.refenaValue,
    required this.riverpodValue,
    required this.incRefena,
    required this.incRiverpod,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Vm &&
          runtimeType == other.runtimeType &&
          refenaValue == other.refenaValue &&
          riverpodValue == other.riverpodValue;

  @override
  int get hashCode => refenaValue.hashCode ^ riverpodValue.hashCode;
}

final _viewProvider = refena.ViewProvider((ref) {
  return _Vm(
    refenaValue: ref.watch(_refenaProvider),
    riverpodValue: ref.riverpod.watch(_riverpodProvider),
    incRefena: () => ref.notifier(_refenaProvider).setState((s) => s + 1),
    incRiverpod: () => ref.riverpod.read(_riverpodProvider.notifier).state++,
  );
});

void main() {
  testWidgets('Should rebuild', (tester) async {
    final widget = _ViewModelWidget();
    final scope = riverpod.ProviderScope(
      child: refena.RefenaScope(
        child: RefenaRiverpodExtensionScope(
          child: MaterialApp(
            home: widget,
          ),
        ),
      ),
    );

    await tester.pumpWidget(scope);

    expect(find.text('111 - 322'), findsOneWidget);
    expect(widget._rebuildCount, 1);

    // update the state
    await tester.tap(find.byKey(ValueKey('incRefena')));
    await tester.pump();

    expect(find.text('112 - 322'), findsOneWidget);
    expect(widget._rebuildCount, 2);

    // update the state
    await tester.tap(find.byKey(ValueKey('incRiverpod')));
    await tester.pump();

    expect(find.text('112 - 323'), findsOneWidget);
    expect(widget._rebuildCount, 3);
  });

  testWidgets('Disposing rebuildable should dispose riverpod listener',
      (tester) async {
    final widget = _ViewModelWidget();
    final scope = refena.RefenaScope(
      child: riverpod.ProviderScope(
        child: RefenaRiverpodExtensionScope(
          child: MaterialApp(
            home: widget,
          ),
        ),
      ),
    );

    await tester.pumpWidget(scope);

    expect(find.text('111 - 322'), findsOneWidget);
    expect(widget._rebuildCount, 1);

    // update the state
    await tester.tap(find.byKey(ValueKey('incRiverpod')));
    await tester.pump();

    expect(find.text('111 - 323'), findsOneWidget);
    expect(widget._rebuildCount, 2);

    // dispose
    scope.dispose(_viewProvider);

    // update the state
    await tester.tap(find.byKey(ValueKey('incRiverpod')));
    await tester.pump();

    // should not rebuild because the rebuildable is disposed
    expect(find.text('111 - 323'), findsOneWidget);
    expect(widget._rebuildCount, 2);
  });
}

// ignore: must_be_immutable
class _ViewModelWidget extends StatelessWidget {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;

    final vm = context.ref.watch(_viewProvider);
    return Scaffold(
      body: Column(
        children: [
          Text('${vm.refenaValue} - ${vm.riverpodValue}'),
          ElevatedButton(
            key: const ValueKey('incRefena'),
            onPressed: vm.incRefena,
            child: const Text('incRefena'),
          ),
          ElevatedButton(
            key: const ValueKey('incRiverpod'),
            onPressed: vm.incRiverpod,
            child: const Text('incRiverpod'),
          ),
        ],
      ),
    );
  }
}
