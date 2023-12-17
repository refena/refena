import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';

void main() {
  testWidgets('BuildContext should be available during onTap', (tester) async {
    final scope = RefenaScope(
      child: MaterialApp(
        home: _MyPage(),
      ),
    );

    await tester.pumpWidget(scope);

    expect(find.text('Counter: 0'), findsOneWidget);

    await tester.tap(find.byKey(const Key('increment-button')));

    await tester.pumpAndSettle();

    expect(find.text('Counter: 1'), findsOneWidget);
    expect(find.text('SnackBar: 1'), findsOneWidget);
  });

  testWidgets('BuildContext should be available during init hooks',
      (tester) async {
    BuildContext? onInitContext;
    BuildContext? onInitBuildContext;
    final scope = RefenaScope(
      child: MaterialApp(
        home: _InitCallbackPage(
          onInit: (ref) {
            onInitContext = ref.notifier(_notifierProvider).getBuildContext();
          },
          onInitBuild: (ref) {
            onInitBuildContext =
                ref.notifier(_notifierProvider).getBuildContext();
          },
        ),
      ),
    );

    await tester.pumpWidget(scope);

    expect(find.text('Counter: 0'), findsOneWidget);
    expect(onInitContext, isNotNull);
    expect(onInitBuildContext, isNotNull);
    expect(onInitContext?.widget.runtimeType, ViewModelBuilder<int, int>);
    expect(onInitBuildContext?.widget.runtimeType, ViewModelBuilder<int, int>);
  });

  test('Should throw error if initialized outside of ViewModelBuilder', () {
    final ref = RefenaContainer();

    expect(
      () => ref.read(_notifierProvider),
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        '_Notifier requires a BuildContext. Use ViewModelBuilder to initialize this provider.',
      )),
    );

    expect(ref.getActiveProviders(), isEmpty);
  });

  testWidgets('Should dispose BuildContext on widget dispose', (tester) async {
    final scope = RefenaScope(
      child: MaterialApp(
        home: _HomePage(),
      ),
    );

    await tester.pumpWidget(scope);

    await tester.tap(find.byType(ElevatedButton));

    await tester.pumpAndSettle();

    expect(find.text('Counter: 0'), findsOneWidget);

    final notifier = scope.notifier(_notifierProvider);
    expect(scope.read(_notifierProvider), 0);
    expect(scope.notifier(_notifierProvider).getBuildContext(), isNotNull);

    // Pop the page
    await tester.tap(find.byKey(const Key('back-button')));

    await tester.pumpAndSettle();

    // The notifier should be disposed
    expect(scope.getActiveProviders(), isEmpty);

    // The BuildContext should be disposed as well
    expect(notifier.getBuildContext(), isNull);
    expect(
      () => notifier.context, // ignore: invalid_use_of_protected_member
      throwsA(isA<StateError>().having(
        (e) => e.message,
        'message',
        'BuildContext is already disposed.',
      )),
    );
  });
}

class _HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ElevatedButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => _MyPage(),
          ),
        ),
        child: const Text('Open'),
      ),
    );
  }
}

class _MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: _notifierProvider,
      builder: (context, vm) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Counter: $vm'),
                const SizedBox(height: 20),
                ElevatedButton(
                  key: const Key('increment-button'),
                  onPressed: () =>
                      context.notifier(_notifierProvider).increment(),
                  child: const Text('Increment'),
                ),
                ElevatedButton(
                  key: const Key('back-button'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Back'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InitCallbackPage extends StatelessWidget {
  final void Function(Ref) onInit;
  final void Function(Ref) onInitBuild;

  const _InitCallbackPage({
    required this.onInit,
    required this.onInitBuild,
  });

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: _notifierProvider,
      init: (context, ref) => onInit(ref),
      initBuild: (context, ref) => onInitBuild(ref),
      builder: (context, vm) {
        return Scaffold(
          body: Center(
            child: Text('Counter: $vm'),
          ),
        );
      },
    );
  }
}

final _notifierProvider = NotifierProvider<_Notifier, int>(
  (ref) => _Notifier(),
);

class _Notifier extends Notifier<int> with ViewBuildContext {
  @override
  int init() => 0;

  void increment() async {
    state++;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SnackBar: $state'),
      ),
    );
  }

  BuildContext? getBuildContext() {
    return contextOrNull;
  }
}
