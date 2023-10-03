import 'package:flutter/material.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

void main() {
  runApp(
    RefenaScope(
      observers: [
        RefenaInspectorObserver(
          actions: {
            'Show Snackbar': InspectorAction(
                params: {
                  'message': ParamSpec.string(
                    defaultValue: 'Hello World',
                  ),
                },
                action: (ref, params) {
                  ref.dispatch(ShowSnackBarAction(message: params['message']));
                }
            ),
          },
        ),
        RefenaTracingObserver(),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspector Test',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: context.ref.read(snackBarProvider).key,
      home: MyPage(),
    );
  }
}

class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspector Test'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RefenaTracingPage()),
              );
            },
            child: Text('Show Tracing'),
          ),
        ],
      ),
    );
  }
}
