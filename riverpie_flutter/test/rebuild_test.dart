import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';

final _stateAProvider = StateProvider((ref) => 111);
final _stateBProvider = StateProvider((ref) => 999);

class _Vm {
  final String value;
  final void Function(int a) setA;
  final void Function(int b) setB;

  _Vm({
    required this.value,
    required this.setA,
    required this.setB,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Vm && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

final _viewProvider = ViewProvider((ref) {
  final a = ref.watch(_stateAProvider);
  final b = ref.watch(_stateBProvider);
  return _Vm(
    value: '$a - $b',
    setA: (a) => ref.notifier(_stateAProvider).setState((_) => a),
    setB: (b) => ref.notifier(_stateBProvider).setState((_) => b),
  );
});

void main() {
  testWidgets('Should rebuild widget with context.ref', (tester) async {
    final widget = _ContextRefWidget();
    final scope = RiverpieScope(
      child: MaterialApp(
        home: widget,
      ),
    );

    await tester.pumpWidget(scope);

    expect(find.text('111'), findsOneWidget);
    expect(widget._rebuildCount, 1);

    // update the state
    scope.notifier(_stateAProvider).setState((_) => 222);
    await tester.pump();

    expect(find.text('222'), findsOneWidget);
    expect(widget._rebuildCount, 2);
  });

  testWidgets('Should rebuild widget with "with Riverpie"', (tester) async {
    final key = GlobalKey<_WithRefWidgetState>();
    final scope = RiverpieScope(
      child: MaterialApp(
        home: _WithRefWidget(key: key),
      ),
    );

    await tester.pumpWidget(scope);

    expect(find.text('111'), findsOneWidget);
    expect(key.currentState!._rebuildCount, 1);

    // update the state
    scope.notifier(_stateAProvider).setState((_) => 222);
    await tester.pump();

    expect(find.text('222'), findsOneWidget);
    expect(key.currentState!._rebuildCount, 2);
  });

  testWidgets('Should rebuild partly with Consumer', (tester) async {
    final widget = _ConsumerWidget();
    final scope = RiverpieScope(
      child: MaterialApp(
        home: widget,
      ),
    );

    await tester.pumpWidget(scope);

    expect(find.text('111'), findsOneWidget);
    expect(find.text('999'), findsOneWidget);
    expect(widget._rebuildGlobalCount, 1);
    expect(widget._rebuildACount, 1);
    expect(widget._rebuildBCount, 1);

    // update the state
    scope.notifier(_stateAProvider).setState((_) => 222);
    await tester.pump();

    expect(find.text('222'), findsOneWidget);
    expect(find.text('999'), findsOneWidget);
    expect(widget._rebuildGlobalCount, 1);
    expect(widget._rebuildACount, 2);
    expect(widget._rebuildBCount, 1);

    // update the state
    scope.notifier(_stateBProvider).setState((_) => 888);
    await tester.pump();

    expect(find.text('222'), findsOneWidget);
    expect(find.text('888'), findsOneWidget);
    expect(widget._rebuildGlobalCount, 1);
    expect(widget._rebuildACount, 2);
    expect(widget._rebuildBCount, 2);
  });

  testWidgets('Should rebuild with ViewProvider', (tester) async {
    final widget = _ViewModelWidget();
    final observer = RiverpieHistoryObserver();
    final scope = RiverpieScope(
      observer: observer,
      child: MaterialApp(
        home: widget,
      ),
    );
    await tester.pumpWidget(scope);

    expect(find.text('111 - 999'), findsOneWidget);
    expect(widget._rebuildCount, 1);

    // update the state
    await tester.tap(find.byKey(ValueKey('setA')));
    await tester.pump();

    expect(find.text('222 - 999'), findsOneWidget);
    expect(widget._rebuildCount, 2);

    // update the state
    await tester.tap(find.byKey(ValueKey('setB')));
    await tester.pump();

    expect(find.text('222 - 888'), findsOneWidget);
    expect(widget._rebuildCount, 3);

    // check events
    final notifier = scope.anyNotifier(_viewProvider);
    final notifierA = scope.notifier(_stateAProvider);
    final notifierB = scope.notifier(_stateBProvider);
    expect(observer.history, [
      ProviderInitEvent(
        provider: _stateAProvider,
        notifier: notifierA,
        cause: ProviderInitCause.access,
        value: 111,
      ),
      ListenerAddedEvent(
        notifier: notifierA,
        rebuildable: notifier,
      ),
      ProviderInitEvent(
        provider: _stateBProvider,
        notifier: notifierB,
        cause: ProviderInitCause.access,
        value: 999,
      ),
      ListenerAddedEvent(
        notifier: notifierB,
        rebuildable: notifier,
      ),
      ProviderInitEvent(
        provider: _viewProvider,
        notifier: notifier,
        cause: ProviderInitCause.access,
        value: _Vm(
          value: '111 - 999',
          setA: (_) {},
          setB: (_) {},
        ),
      ),
      ListenerAddedEvent(
        notifier: notifier,
        rebuildable: WidgetRebuildable<_ViewModelWidget>(),
      ),
      ChangeEvent(
        notifier: notifierA,
        prev: 111,
        next: 222,
        flagRebuild: [notifier],
      ),
      ChangeEvent(
        notifier: notifier,
        prev: _Vm(
          value: '111 - 999',
          setA: (_) {},
          setB: (_) {},
        ),
        next: _Vm(
          value: '222 - 999',
          setA: (_) {},
          setB: (_) {},
        ),
        flagRebuild: [WidgetRebuildable<_ViewModelWidget>()],
      ),
      ChangeEvent(
        notifier: notifierB,
        prev: 999,
        next: 888,
        flagRebuild: [notifier],
      ),
      ChangeEvent(
        notifier: notifier,
        prev: _Vm(
          value: '222 - 999',
          setA: (_) {},
          setB: (_) {},
        ),
        next: _Vm(
          value: '222 - 888',
          setA: (_) {},
          setB: (_) {},
        ),
        flagRebuild: [WidgetRebuildable<_ViewModelWidget>()],
      ),
    ]);
  });

  testWidgets('Should rebuild widget conditionally', (tester) async {
    final widget = _RebuildWhenWidget();
    final scope = RiverpieScope(
      child: MaterialApp(
        home: widget,
      ),
    );

    await tester.pumpWidget(scope);

    expect(find.text('111'), findsOneWidget);
    expect(widget._rebuildCount, 1);

    // update the state
    scope.notifier(_stateAProvider).setState((_) => 333);
    await tester.pump();

    expect(find.text('111'), findsOneWidget);
    expect(widget._rebuildCount, 1);

    // update the state
    scope.notifier(_stateAProvider).setState((_) => 222);
    await tester.pump();

    expect(find.text('222'), findsOneWidget);
    expect(widget._rebuildCount, 2);

    // update the state
    scope.notifier(_stateAProvider).setState((_) => 444);
    await tester.pump();

    expect(find.text('444'), findsOneWidget);
    expect(widget._rebuildCount, 3);

    // update the state
    scope.notifier(_stateAProvider).setState((_) => 555);
    await tester.pump();

    expect(find.text('444'), findsOneWidget);
    expect(widget._rebuildCount, 3);
  });
}

// ignore: must_be_immutable
class _ContextRefWidget extends StatelessWidget {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;

    final value = context.ref.watch(_stateAProvider);
    return Scaffold(
      body: Text(value.toString()),
    );
  }
}

class _WithRefWidget extends StatefulWidget {
  const _WithRefWidget({required super.key});

  @override
  State<_WithRefWidget> createState() => _WithRefWidgetState();
}

class _WithRefWidgetState extends State<_WithRefWidget> with Riverpie {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;

    final value = ref.watch(_stateAProvider);
    return Scaffold(
      body: Text(value.toString()),
    );
  }
}

// ignore: must_be_immutable
class _ConsumerWidget extends StatelessWidget {
  int _rebuildGlobalCount = 0;
  int _rebuildACount = 0;
  int _rebuildBCount = 0;

  @override
  Widget build(BuildContext context) {
    _rebuildGlobalCount++;

    return Scaffold(
      body: Column(
        children: [
          Consumer(
            builder: (context, ref) {
              _rebuildACount++;
              final value = ref.watch(_stateAProvider);
              return Text(value.toString());
            },
          ),
          Consumer(
            builder: (context, ref) {
              _rebuildBCount++;
              final value = ref.watch(_stateBProvider);
              return Text(value.toString());
            },
          ),
        ],
      ),
    );
  }
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
          Text(vm.value),
          ElevatedButton(
            key: ValueKey('setA'),
            onPressed: () => vm.setA(222),
            child: Text('Set A'),
          ),
          ElevatedButton(
            key: ValueKey('setB'),
            onPressed: () => vm.setB(888),
            child: Text('Set B'),
          ),
        ],
      ),
    );
  }
}

// ignore: must_be_immutable
class _RebuildWhenWidget extends StatelessWidget {
  int _rebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;

    final value = context.ref.watch(
      _stateAProvider,
      rebuildWhen: (a, b) => b % 2 == 0,
    );

    return Scaffold(
      body: Text(value.toString()),
    );
  }
}
