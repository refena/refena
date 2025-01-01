import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';

void main() {
  testWidgets('Should watch state', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _SimpleWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.read(_counter), 0);
    expect(find.text('0'), findsOneWidget);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(ref.read(_counter), 1);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Should watch state with select', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _SelectWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.read(_counter), 0);
    expect(find.text('0'), findsOneWidget);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(ref.read(_counter), 1);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('Should run onFirstFrame once before build', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _OnFirstFrameWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.read(_counter), 0);
    expect(find.text('0 - 0'), findsOneWidget);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(ref.read(_counter), 1);
    expect(find.text('1 - 0'), findsOneWidget);
  });

  testWidgets('Should run onFirstLoadingFrame, then onFirstFrame once',
      (tester) async {
    final completer = Completer<void>();

    final ref = RefenaScope(
      child: MaterialApp(
        home: _OnFirstLoadingFrameWidget(completer.future),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.read(_counter), 0);
    expect(find.text('Loading: 0'), findsOneWidget);

    ref.notifier(_counter).setState((old) => old + 1);
    expect(ref.read(_counter), 1);
    await tester.pump();
    expect(find.text('Loading: 0'), findsOneWidget);

    completer.complete();
    await tester.pump();
    await tester.pump();
    expect(find.text('1 - 0 - 1'), findsOneWidget);

    ref.notifier(_counter).setState((old) => old + 1);
    expect(ref.read(_counter), 2);
    await tester.pump();
    expect(find.text('2 - 0 - 1'), findsOneWidget);
  });

  testWidgets('Should dispose watched provider', (tester) async {
    final observer = RefenaHistoryObserver.only(
      providerDispose: true,
    );
    bool disposeCalled = false;
    final ref = RefenaScope(
      observers: [observer],
      child: MaterialApp(
        home: _SwitchingWidget(() => disposeCalled = true),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('0'), findsOneWidget);
    expect(ref.read(_counter), 0);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(ref.read(_counter), 1);
    expect(disposeCalled, false);

    // dispose
    expect(ref.getActiveProviders(), [_switcher, _counter]);
    observer.start(clearHistory: true);
    ref.notifier(_switcher).setState((_) => false);
    await tester.pump();
    observer.stop();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(ref.getActiveProviders(), [_switcher]);
    expect(ref.read(_counter), 0);
    expect(observer.history.length, 1);
    expect((observer.history.first as ProviderDisposeEvent).provider, _counter);
    expect(disposeCalled, true);
  });

  testWidgets('Should dispose watched temporary provider', (tester) async {
    final observer = RefenaHistoryObserver.only(
      providerDispose: true,
    );
    bool disposeCalled = false;
    final ref = RefenaScope(
      observers: [observer],
      child: MaterialApp(
        home: _SwitchingTempProviderWidget(() => disposeCalled = true),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('0'), findsOneWidget);
    expect(ref.read(_counter), 0);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(ref.read(_counter), 1);
    expect(disposeCalled, false);

    // dispose
    expect(
      ref.getActiveProviders(),
      [_switcher, _counter, isA<ViewProvider>()],
    );
    observer.start(clearHistory: true);
    ref.notifier(_switcher).setState((_) => false);
    await tester.pump();
    observer.stop();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(ref.getActiveProviders(), [_switcher, _counter]);
    expect(observer.history.length, 1);
    expect(
      (observer.history.first as ProviderDisposeEvent).provider,
      isA<ViewProvider>(),
    );
    expect(disposeCalled, true);
  });

  testWidgets('Should call sync init', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _SyncInitNoPlaceholderWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('0'), findsOneWidget);

    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(ref.read(_counter), 1);
  });

  testWidgets('Should show placeholder on sync init', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _SyncInitWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('Loading...'), findsOneWidget);
    expect(find.text('0'), findsNothing);

    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(ref.read(_counter), 1);
  });

  testWidgets('Should call async init', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _AsyncInitNoPlaceholderWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('0'), findsOneWidget);
    expect(ref.read(_counter), 0);

    await tester.pump();

    expect(find.text('0'), findsOneWidget);
    expect(ref.read(_counter), 0);

    await tester.pump(Duration(milliseconds: 150));

    expect(find.text('1'), findsOneWidget);
    expect(ref.read(_counter), 1);
  });

  testWidgets('Should show placeholder on async init', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _AsyncInitWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('Loading...'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(ref.read(_counter), 0);

    await tester.pump();

    expect(find.text('Loading...'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(ref.read(_counter), 0);

    await tester.pump(Duration(milliseconds: 150));

    expect(find.text('1'), findsOneWidget);
    expect(ref.read(_counter), 1);
  });

  testWidgets('Should show error widget', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _AsyncErrorInitWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('Loading...'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(ref.read(_counter), 0);

    await tester.pump();

    expect(find.text('Loading...'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(ref.read(_counter), 0);

    await tester.pump(Duration(milliseconds: 150));

    expect(find.text('Error: My Error'), findsOneWidget);
    expect(ref.read(_counter), 0);
  });
}

final _switcher = StateProvider((ref) => true);
final _counter = StateProvider((ref) => 0);

class _SimpleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (context) => _counter,
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}

class _SelectWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (context) => _counter.select((state) => state * 2),
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}

class _OnFirstFrameWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    late int initCounter;
    return ViewModelBuilder(
      provider: (context) => _counter,
      onFirstFrame: (context, vm) => initCounter = context.read(_counter),
      builder: (context, vm) {
        return Text('$vm - $initCounter');
      },
    );
  }
}

class _OnFirstLoadingFrameWidget extends StatelessWidget {
  final Future<void> future;

  const _OnFirstLoadingFrameWidget(this.future);

  @override
  Widget build(BuildContext context) {
    late int loadingCounter;
    late int initCounter;
    return ViewModelBuilder(
      provider: (context) => _counter,
      init: (context) => future,
      onFirstLoadingFrame: (context) => loadingCounter = context.read(_counter),
      onFirstFrame: (context, vm) => initCounter = context.read(_counter),
      loadingBuilder: (context) => Text('Loading: $loadingCounter'),
      builder: (context, vm) {
        return Text('$vm - $loadingCounter - $initCounter');
      },
    );
  }
}

class _SwitchingWidget extends StatelessWidget {
  final void Function() onDispose;

  _SwitchingWidget(this.onDispose);

  @override
  Widget build(BuildContext context) {
    final b = context.watch(_switcher);
    if (b) {
      return ViewModelBuilder(
        provider: (context) => _counter,
        dispose: (ref) => onDispose(),
        builder: (context, vm) {
          return Text('$vm');
        },
      );
    } else {
      return Container();
    }
  }
}

/// Similar to [_SwitchingWidget], but creates a temporary provider
class _SwitchingTempProviderWidget extends StatelessWidget {
  final void Function() onDispose;

  _SwitchingTempProviderWidget(this.onDispose);

  @override
  Widget build(BuildContext context) {
    final b = context.watch(_switcher);
    if (b) {
      return ViewModelBuilder(
        provider: (context) => ViewProvider((ref) {
          return ref.watch(_counter);
        }),
        dispose: (ref) => onDispose(),
        builder: (context, vm) {
          return Text('$vm');
        },
      );
    } else {
      return Container();
    }
  }
}

class _SyncInitNoPlaceholderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (context) => _counter,
      init: (context) => context.notifier(_counter).setState((old) => old + 1),
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}

class _SyncInitWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (context) => _counter,
      init: (context) => context.notifier(_counter).setState((old) => old + 1),
      loadingBuilder: (context) => Text('Loading...'),
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}

class _AsyncInitNoPlaceholderWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (context) => _counter,
      init: (context) async {
        await Future.delayed(Duration(milliseconds: 100));
        context.notifier(_counter).setState((old) => old + 1);
      },
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}

class _AsyncInitWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (context) => _counter,
      init: (context) async {
        await Future.delayed(Duration(milliseconds: 100));
        context.notifier(_counter).setState((old) => old + 1);
      },
      loadingBuilder: (context) => Text('Loading...'),
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}

class _AsyncErrorInitWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: (context) => _counter,
      init: (context) async {
        await Future.delayed(Duration(milliseconds: 100));
        throw 'My Error';
      },
      loadingBuilder: (context) => Text('Loading...'),
      errorBuilder: (context, error, stackTrace) => Text('Error: $error'),
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}
