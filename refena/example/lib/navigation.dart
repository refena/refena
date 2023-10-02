import 'package:flutter/material.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';

void main() {
  runApp(
    RefenaScope(
      observer: RefenaMultiObserver(
        observers: [
          RefenaDebugObserver(),
          RefenaTracingObserver(),
        ],
      ),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: context.ref.watch(navigationProvider).key,
      home: MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    return Scaffold(
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: [
            ElevatedButton(
              onPressed: () async {
                final result = await ref
                    .read(navigationProvider)
                    .push<String>(SecondPage());

                print('RESULT: $result (${result.runtimeType})');
              },
              child: Text('Push'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.dispatchAsync(
                  NavigateAction.push(SecondPage()),
                );
              },
              child: Text('Push Action (sync)'),
            ),
            ElevatedButton(
              onPressed: () async {
                final result = await ref.dispatchAsync<String?>(
                  NavigateAction.push(SecondPage()),
                );

                print('RESULT: $result (${result.runtimeType})');
              },
              child: Text('Push Action'),
            ),
            ElevatedButton(
              onPressed: () {
                ref
                    .redux(myReduxProvider)
                    .dispatchAsync(DispatchAddonWithinAction());
              },
              child: Text('Push Action within Action'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.dispatchAsync(NavigateAction.pushNamed('/second'));
              },
              child: Text('Push Named Action'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.dispatchAsync(
                  NavigateAction.push(RefenaTracingPage()),
                );
              },
              child: Text('Show Tracing'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Page'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              context.ref.dispatch(NavigateAction.pop());
            },
            child: Text('Pop'),
          ),
          ElevatedButton(
            onPressed: () {
              context.ref.dispatch(NavigateAction.pop('My Result'));
            },
            child: Text('Pop with result'),
          ),
        ],
      ),
    );
  }
}

final myReduxProvider = ReduxProvider((_) => MyReduxService());

class MyReduxService extends ReduxNotifier<void> {
  @override
  void init() {}
}

class DispatchAddonWithinAction extends AsyncReduxAction<MyReduxService, void>
    with GlobalActions {
  @override
  Future<void> reduce() async {
    await global.dispatchAsync(NavigateAction.push(SecondPage()));
  }
}
