// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';

/// These tests check if notifiers are correctly unwatched when
/// they are no longer watched in the build method but were watched
/// in the previous build method.
void main() {
  testWidgets('Should unwatch old provider', (tester) async {
    bool buildCalled = false;
    final ref = RefenaScope(
      child: MaterialApp(
        home: _Widget(() => buildCalled = true),
      ),
    );

    await tester.pumpWidget(ref);

    expect(find.text('10'), findsOneWidget);
    expect(
      ref.notifier(_switchProvider).getListeners(),
      [WidgetRebuildable<_Widget>()],
    );
    expect(
      ref.notifier(_providerA).getListeners(),
      [WidgetRebuildable<_Widget>()],
    );
    expect(
      ref.notifier(_providerB).getListeners(),
      isEmpty,
    );

    // Changing A should rebuild
    buildCalled = false;
    ref.notifier(_providerA).setState((_) => 11);
    await tester.pump();

    expect(find.text('11'), findsOneWidget);
    expect(buildCalled, true);

    // Changing B should not rebuild
    buildCalled = false;
    ref.notifier(_providerB).setState((_) => 21);
    await tester.pump();

    expect(find.text('11'), findsOneWidget);
    expect(buildCalled, false);

    // Switch to B
    ref.notifier(_switchProvider).setState((_) => false);
    await tester.pump();

    expect(find.text('21'), findsOneWidget);
    expect(
      ref.notifier(_switchProvider).getListeners(),
      [WidgetRebuildable<_Widget>()],
    );
    expect(
      ref.notifier(_providerA).getListeners(),
      isEmpty,
    );
    expect(
      ref.notifier(_providerB).getListeners(),
      [WidgetRebuildable<_Widget>()],
    );

    // Changing A should not rebuild
    buildCalled = false;
    ref.notifier(_providerA).setState((_) => 12);
    await tester.pump();

    expect(find.text('21'), findsOneWidget);
    expect(buildCalled, false);

    // Changing B should rebuild
    buildCalled = false;
    ref.notifier(_providerB).setState((_) => 22);
    await tester.pump();

    expect(find.text('22'), findsOneWidget);
    expect(buildCalled, true);
  });

  testWidgets('Should dispose rebuildable on provider dispose', (tester) async {
    final ref = RefenaScope(
      child: MaterialApp(
        home: _ViewModelParentWidget(),
      ),
    );

    await tester.pumpWidget(ref);

    final notifierA = ref.notifier(_providerA);
    final viewNotifier = ref.anyNotifier(_vmProvider);
    final rebuildable = viewNotifier.getListeners().first as ElementRebuildable;
    expect(find.text('10'), findsOneWidget);
    expect(notifierA.disposed, false);
    expect(viewNotifier.disposed, false);
    expect(rebuildable.unwatchManagerDisposed, false);

    // implicitly dispose [_ViewModelWidget]
    ref.notifier(_switchProvider).setState((_) => false);
    await tester.pump();

    expect(find.text('10'), findsNothing);
    expect(notifierA.disposed, false);
    expect(viewNotifier.disposed, true);

    // While the widget is disposed, we need to ensure that
    // the unwatch manager is also disposed.
    expect(rebuildable.unwatchManagerDisposed, true);
  });
}

final _switchProvider = StateProvider((ref) => true);
final _providerA = StateProvider((ref) => 10);
final _providerB = StateProvider((ref) => 20);

class _Widget extends StatelessWidget {
  final void Function() onBuild;

  _Widget(this.onBuild);

  @override
  Widget build(BuildContext context) {
    onBuild();
    final int number;
    if (context.watch(_switchProvider)) {
      number = context.watch(_providerA);
    } else {
      number = context.watch(_providerB);
    }
    return Text(number.toString());
  }
}

final _vmProvider = ViewProvider((ref) {
  return ref.watch(_providerA);
});

class _ViewModelParentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (context.watch(_switchProvider)) {
      return _ViewModelWidget();
    } else {
      return Container();
    }
  }
}

class _ViewModelWidget extends StatefulWidget {
  @override
  State<_ViewModelWidget> createState() => _ViewModelWidgetState();
}

class _ViewModelWidgetState extends State<_ViewModelWidget> {
  @override
  void dispose() {
    context.dispose(_vmProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(context.watch(_vmProvider).toString());
  }
}
