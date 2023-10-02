import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';

void main() {
  testWidgets('Should show snack bar with ref.read', (tester) async {
    final ref = RefenaScope(
      child: _App(_RefReadPage()),
    );

    await tester.pumpWidget(ref);

    // Verify that the snackbar is not visible.
    const expectedMessage = 'Hello from Provider!';
    expect(find.text(expectedMessage), findsNothing);

    await tester.tap(find.text('Show Snackbar'));
    await tester.pump();

    expect(find.text(expectedMessage), findsOneWidget);
  });

  testWidgets('Should show snack bar with ReduxAction', (tester) async {
    final ref = RefenaScope(
      child: _App(_ReduxPage()),
    );

    await tester.pumpWidget(ref);

    // Verify that the snackbar is not visible.
    const expectedMessage = 'Hello Redux!';
    expect(find.text(expectedMessage), findsNothing);

    await tester.tap(find.text('Show Snackbar'));
    await tester.pump();

    expect(find.text(expectedMessage), findsOneWidget);
  });

  testWidgets('Should show snack bar with custom ReduxAction', (tester) async {
    final ref = RefenaScope(
      child: _App(_CustomReduxPage()),
    );

    await tester.pumpWidget(ref);

    // Verify that the snackbar is not visible.
    const expectedMessage = 'Hello within action!';
    expect(find.text(expectedMessage), findsNothing);

    await tester.tap(find.text('Show Snackbar'));
    await tester.pump();

    expect(find.text(expectedMessage), findsOneWidget);
  });

  testWidgets('Should show snack bar with extended Action', (tester) async {
    final ref = RefenaScope(
      child: _App(_ExtendedActionPage()),
    );

    await tester.pumpWidget(ref);

    // Verify that the snackbar is not visible.
    const expectedMessage = 'Hello from extended action!';
    expect(find.text(expectedMessage), findsNothing);

    await tester.tap(find.text('Show Snackbar'));
    await tester.pump();

    expect(find.text(expectedMessage), findsOneWidget);
  });
}

class _App extends StatelessWidget {
  final Widget home;

  _App(this.home);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: context.ref.watch(snackBarProvider).key,
      home: home,
    );
  }
}

class _RefReadPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Snackbar'),
          onPressed: () {
            context.ref
                .read(snackBarProvider)
                .showMessage('Hello from Provider!');
          },
        ),
      ),
    );
  }
}

class _ReduxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Snackbar'),
          onPressed: () {
            context.ref.dispatch(ShowSnackBarAction(message: 'Hello Redux!'));
          },
        ),
      ),
    );
  }
}

class _CustomReduxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Snackbar'),
          onPressed: () {
            context.ref.redux(_myReduxProvider).dispatch(_MyReduxAction());
          },
        ),
      ),
    );
  }
}

class _ExtendedActionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text('Show Snackbar'),
          onPressed: () {
            context.ref.dispatch(_ExtendedSnackbarAction());
          },
        ),
      ),
    );
  }
}

final _myReduxProvider = ReduxProvider((ref) => _MyReduxService());

class _MyReduxService extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class _MyReduxAction extends ReduxAction<_MyReduxService, int>
    with GlobalActions {
  @override
  int reduce() {
    global.dispatch(ShowSnackBarAction(message: 'Hello within action!'));
    return state;
  }
}

class _ExtendedSnackbarAction extends BaseShowSnackBarAction {
  @override
  void reduce() {
    ref.read(snackBarProvider).key.currentState?.showSnackBar(
          SnackBar(content: Text('Hello from extended action!')),
        );
  }
}
