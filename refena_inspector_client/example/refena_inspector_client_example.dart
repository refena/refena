import 'package:refena/refena.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

/// Run this main function,
/// then run the inspector server with the following command:
/// `dart run refena_inspector`
void main() async {
  // or "RefenaScope" for Flutter projects
  final ref = RefenaContainer(
    observers: [
      RefenaInspectorObserver(
        host: 'localhost',
        actions: {
          'Test message': (Ref ref) => ref.message('test'),
          'Authentication': {
            'Login': InspectorAction(
              params: {
                'name': ParamSpec.string(),
                'password': ParamSpec.string(),
              },
              action: (ref, params) {
                ref.message(
                  'Login with ${params['name']} and ${params['password']}',
                );
              },
            ),
            'Register': InspectorAction(
              params: {
                'name': ParamSpec.string(required: true),
                'age': ParamSpec.int(defaultValue: 20),
                'height': ParamSpec.double(required: true),
                'premium': ParamSpec.bool(defaultValue: false),
              },
              action: (ref, params) {
                ref.message(
                  'Register with name: ${params['name']}, age: ${params['age']}, height: ${params['height']}, premium: ${params['premium']}',
                );
              },
            ),
            'Logout': (Ref ref) => throw 'Logout error',
            'Admin': {
              'Test': {
                'Hello': (Ref ref) => ref.message('Hello'),
                'World': (Ref ref) => ref.message('World'),
              }
            },
          },
        },
      ),
      RefenaTracingObserver(
        exclude: (e) {
          return e.debugLabel.endsWith('5');
        },
      ),
      RefenaDebugObserver(),
    ],
  );

  int i = 0;
  while (true) {
    await Future.delayed(Duration(seconds: 1));
    ref.message('Hello! $i');
    i++;
  }
}
