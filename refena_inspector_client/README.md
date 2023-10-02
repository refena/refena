![logo](https://raw.githubusercontent.com/refena/refena/main/resources/inspector-logo-512.webp)

[![pub package](https://img.shields.io/pub/v/refena_inspector_client.svg)](https://pub.dev/packages/refena_inspector_client)
![ci](https://github.com/refena/refena/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The inspector for [Refena](https://pub.dev/packages/refena).

```yaml
# pubspec.yaml
dependencies:
  refena_inspector_client: <version>

dev_dependencies:
  refena_inspector: <version>
```

## Usage

Add the `RefenaInspectorObserver` to your `RefenaContainer` or `RefenaScope`.

This observer will handle the communication between your app and the inspector.

```dart
void main() {
  // or "RefenaScope" for Flutter projects
  RefenaContainer(
    observer: RefenaMultiObserver(
      observers: [
        RefenaInspectorObserver(
          actions: {
            'Test message': (Ref ref) => ref.message('test'),
            'Authentication': {
              'Register': InspectorAction(
                params: {
                  'name': ParamSpec.string(required: true),
                  'age': ParamSpec.int(defaultValue: 20),
                },
                action: (ref, params) {
                  ref.message('Registering ${params['name']}');
                },
              ),
              'Logout': (Ref ref) => throw 'Logout error',
            },
          },
        ),
        RefenaTracingObserver(),
        RefenaDebugObserver(),
      ],
    ),
  );
}
```

Then start the inspector after your app is running:

```bash
dart run refena_inspector
```
