import 'package:flutter/material.dart';
import 'package:riverpie_flutter/addons.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';

void main() {
  runApp(
    RiverpieScope(
      observer: RiverpieTracingObserver(),
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
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final result = await ref.read(navigationProvider).push<String>(SecondPage());

              print('RESULT: $result (${result.runtimeType})');
            },
            child: Text('Push'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await ref.dispatchAsync<String>(
                NavigateAction.push(SecondPage()),
              );

              print('RESULT: $result (${result.runtimeType})');
            },
            child: Text('Push Action'),
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
                NavigateAction.push(RiverpieTracingPage()),
              );
            },
            child: Text('Show Tracing'),
          ),
        ],
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
