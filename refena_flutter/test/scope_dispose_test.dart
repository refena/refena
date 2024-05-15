import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// These tests check if the [RefenaScope] disposes containing
/// [RefenaContainer] correctly.
void main() {
  testWidgets('Should dispose implicit container', (tester) async {
    late Ref implicitRef;
    final outerRef = RefenaScope(
      child: MaterialApp(
        home: _ImplicitContainerWidget((ref) => implicitRef = ref),
      ),
    );

    await tester.pumpWidget(outerRef);

    // sanity checks
    expect(implicitRef, isNotNull);
    expect(outerRef.read(_disposeProvider), false);

    // check preconditions
    final notifier = implicitRef.notifier(_disposableProvider);
    expect(outerRef.container.disposed, false);
    expect(implicitRef.container.disposed, false);
    expect(notifier._disposed, false);

    // dispose
    outerRef.notifier(_disposeProvider).setState((_) => true);
    await tester.pumpAndSettle();

    expect(outerRef.container.disposed, false);
    expect(implicitRef.container.disposed, true);
    expect(notifier._disposed, true);
  });

  testWidgets('Should not dispose implicit container on rebuild',
      (tester) async {
    late Ref implicitRef;
    final outerRef = RefenaScope(
      child: MaterialApp(
        home: _ImplicitContainerWidget((ref) => implicitRef = ref),
      ),
    );

    await tester.pumpWidget(outerRef);

    // sanity checks
    expect(implicitRef, isNotNull);
    expect(outerRef.read(_disposeProvider), false);

    // check preconditions
    final notifier = implicitRef.notifier(_disposableProvider);
    expect(outerRef.container.disposed, false);
    expect(implicitRef.container.disposed, false);
    expect(notifier._disposed, false);
    expect(tester.widget<Text>(find.byKey(ValueKey('dummy'))).data, '0');
    expect(tester.widget<Text>(find.byKey(ValueKey('text'))).data, '20');

    // update state
    notifier.doubleIt();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(ValueKey('dummy'))).data, '0');
    expect(tester.widget<Text>(find.byKey(ValueKey('text'))).data, '40');

    // trigger rebuild
    outerRef.notifier(_dummyProvider).setState((i) => i + 1);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(ValueKey('dummy'))).data, '1');
    expect(tester.widget<Text>(find.byKey(ValueKey('text'))).data, '40');

    // update state (it should use the same container)
    notifier.doubleIt();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(ValueKey('dummy'))).data, '1');
    expect(tester.widget<Text>(find.byKey(ValueKey('text'))).data, '80');

    expect(outerRef.container.disposed, false);
    expect(implicitRef.container.disposed, false);
    expect(notifier._disposed, false);
  });

  testWidgets('Should dispose explicit container', (tester) async {
    final internalRef = RefenaContainer();

    final outerRef = RefenaScope(
      child: MaterialApp(
        home: _ExplicitContainerWidget(
          container: internalRef,
          ownsContainer: true,
        ),
      ),
    );

    await tester.pumpWidget(outerRef);

    // sanity checks
    expect(outerRef.read(_disposeProvider), false);

    // check preconditions
    final notifier = internalRef.notifier(_disposableProvider);
    expect(outerRef.container.disposed, false);
    expect(internalRef.disposed, false);
    expect(notifier._disposed, false);

    // dispose
    outerRef.notifier(_disposeProvider).setState((_) => true);

    await tester.pumpAndSettle();

    expect(outerRef.container.disposed, false);
    expect(internalRef.disposed, true);
    expect(notifier._disposed, true);
  });

  testWidgets('Should not dispose when no ownership given', (tester) async {
    final internalRef = RefenaContainer();

    final outerRef = RefenaScope(
      child: MaterialApp(
        home: _ExplicitContainerWidget(
          container: internalRef,
          ownsContainer: false,
        ),
      ),
    );

    await tester.pumpWidget(outerRef);

    // sanity checks
    expect(outerRef.read(_disposeProvider), false);

    // check preconditions
    final notifier = internalRef.notifier(_disposableProvider);
    expect(outerRef.container.disposed, false);
    expect(internalRef.disposed, false);
    expect(notifier._disposed, false);

    // dispose
    outerRef.notifier(_disposeProvider).setState((_) => true);

    await tester.pumpAndSettle();

    expect(outerRef.container.disposed, false);
    expect(internalRef.disposed, false);
    expect(notifier._disposed, false);
  });
}

class _ImplicitContainerWidget extends StatelessWidget {
  final void Function(Ref) onImplicitRef;

  _ImplicitContainerWidget(this.onImplicitRef);

  @override
  Widget build(BuildContext context) {
    if (context.ref.watch(_disposeProvider)) {
      return Container();
    }
    return RefenaScope(
      child: Column(
        children: [
          Text(
            context.ref.watch(_dummyProvider).toString(),
            key: const ValueKey('dummy'),
          ),
          _NotifierWidgetAccessor((ref) => onImplicitRef(ref)),
        ],
      ),
    );
  }
}

class _ExplicitContainerWidget extends StatelessWidget {
  final RefenaContainer container;
  final bool ownsContainer;

  const _ExplicitContainerWidget({
    required this.container,
    required this.ownsContainer,
  });

  @override
  Widget build(BuildContext context) {
    if (context.ref.watch(_disposeProvider)) {
      return Container();
    }
    return RefenaScope.withContainer(
      container: container,
      ownsContainer: ownsContainer,
      child: _NotifierWidgetAccessor(),
    );
  }
}

final _disposeProvider = StateProvider((ref) => false, debugLabel: 'Disposer');

final _dummyProvider = StateProvider((ref) => 0, debugLabel: 'Dummy');

class _NotifierWidgetAccessor extends StatelessWidget {
  final void Function(Ref)? onRef;

  // Uses UniqueKey() to force rebuilds with a new BuildContext.
  // This avoids reusing the old ref.
  _NotifierWidgetAccessor([this.onRef]) : super(key: UniqueKey());

  @override
  Widget build(BuildContext context) {
    onRef?.call(context.ref);
    return Text(
      context.ref.watch(_disposableProvider).toString(),
      key: const ValueKey('text'),
    );
  }
}

final _disposableProvider = NotifierProvider<_DisposableNotifier, int>((ref) {
  return _DisposableNotifier();
});

class _DisposableNotifier extends Notifier<int> {
  bool _disposed = false;

  @override
  int init() => 20;

  void doubleIt() {
    state *= 2;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
