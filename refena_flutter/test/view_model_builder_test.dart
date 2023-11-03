import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/view_model_builder.dart';

void main() {
  testWidgets('Should watch state', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _SimpleWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('0'), findsOneWidget);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
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
    observer.start(clearHistory: true);
    ref.notifier(_switcher).setState((_) => false);
    await tester.pump();
    observer.stop();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(ref.read(_counter), 0);
    expect(observer.history.length, 1);
    expect((observer.history.first as ProviderDisposeEvent).provider, _counter);
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
      provider: _counter,
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}

class _SwitchingWidget extends StatelessWidget {
  final void Function() onDispose;

  _SwitchingWidget(this.onDispose);

  @override
  Widget build(BuildContext context) {
    final b = context.ref.watch(_switcher);
    if (b) {
      return ViewModelBuilder(
        provider: _counter,
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
      provider: _counter,
      init: (context, ref) {
        ref.notifier(_counter).setState((old) => old + 1);
      },
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
      provider: _counter,
      init: (context, ref) {
        ref.notifier(_counter).setState((old) => old + 1);
      },
      placeholder: (context) => Text('Loading...'),
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
      provider: _counter,
      init: (context, ref) async {
        await Future.delayed(Duration(milliseconds: 100));
        ref.notifier(_counter).setState((old) => old + 1);
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
      provider: _counter,
      init: (context, ref) async {
        await Future.delayed(Duration(milliseconds: 100));
        ref.notifier(_counter).setState((old) => old + 1);
      },
      placeholder: (context) => Text('Loading...'),
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
      provider: _counter,
      init: (context, ref) async {
        await Future.delayed(Duration(milliseconds: 100));
        throw 'My Error';
      },
      placeholder: (context) => Text('Loading...'),
      error: (context, error, stackTrace) => Text('Error: $error'),
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}
