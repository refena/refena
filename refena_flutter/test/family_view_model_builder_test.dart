import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';

void main() {
  testWidgets('Should compile with family shorthand', (tester) async {
    final widget = ViewModelBuilder.family(
      provider: _vm(10),
      builder: (context, vm) {
        return Text('$vm');
      },
    );

    expect(widget, isA<FamilyViewModelBuilder>());
  });

  testWidgets('Should watch state', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _SimpleWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.read(_counter), 1);
    expect(find.text('10'), findsOneWidget);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(ref.read(_counter), 2);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('Should watch state with select', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _SelectWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    expect(ref.read(_counter), 1);
    expect(find.text('5'), findsOneWidget);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(ref.read(_counter), 2);
    expect(find.text('15'), findsOneWidget);
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

    final familyNotifier = ref.anyNotifier(_vm);
    expect(ref.read(_counter), 1);
    expect(find.text('5'), findsOneWidget);
    expect(familyNotifier.getTempProviders().length, 1);

    ref.notifier(_counter).setState((old) => old + 1);
    await tester.pump();

    expect(ref.read(_counter), 2);
    expect(find.text('15'), findsOneWidget);
    expect(disposeCalled, false);
    expect(familyNotifier.getTempProviders().length, 1);
    final temporaryProvider = familyNotifier.getTempProviders().first;

    // dispose parameter
    observer.start(clearHistory: true);
    ref.notifier(_switcher).setState((_) => false);
    await tester.pump();
    observer.stop();

    expect(find.text('5'), findsNothing);
    expect(find.text('15'), findsNothing);
    expect(ref.read(_counter), 2);
    expect(observer.history.length, 1);
    expect(
      (observer.history.first as ProviderDisposeEvent).provider,
      temporaryProvider, // should only dispose temporary provider
    );
    expect(disposeCalled, true);
  });
}

final _switcher = StateProvider((ref) => true);
final _counter = StateProvider((ref) => 1);
final _vm = ViewFamilyProvider<int, int>((ref, param) {
  return param * ref.watch(_counter);
});

class _SimpleWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FamilyViewModelBuilder(
      provider: _vm(10),
      builder: (context, vm) {
        return Text('$vm');
      },
    );
  }
}

class _SelectWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FamilyViewModelBuilder(
      provider: _vm(10).select((state) => state - 5),
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
      return ViewModelBuilder.family(
        provider: _vm(10).select((state) => state - 5),
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
