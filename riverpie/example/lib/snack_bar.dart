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
      scaffoldMessengerKey: context.ref.watch(snackBarProvider).key,
      home: MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              context.ref.read(snackBarProvider).showMessage('Hello World');
            },
            child: Text('Show SnackBar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.ref.dispatch(
                ShowSnackBarAction(message: 'Hello World from Action!'),
              );
            },
            child: Text('Show SnackBar Action'),
          ),
          ElevatedButton(
            onPressed: () {
              context.ref.redux(myReduxProvider).dispatch(DispatchAddonWithinAction());
            },
            child: Text('Show SnackBar Action within Action'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) {
                return RiverpieTracingPage();
              }));
            },
            child: Text('Show Tracing'),
          ),
        ],
      ),
    );
  }
}

final myReduxProvider = ReduxProvider((_) => MyReduxService());

class MyReduxService extends ReduxNotifier<void> {
  @override
  int init() => 0;
}

class DispatchAddonWithinAction extends ReduxAction<MyReduxService, void> with AddonActions {
  @override
  int reduce() => 0;

  @override
  void after() {
    addon.dispatch(ShowSnackBarAction(message: 'Hello World from Mixin!'));
  }
}
