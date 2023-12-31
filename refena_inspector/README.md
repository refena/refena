<img src="https://raw.githubusercontent.com/refena/refena/main/resources/inspector-logo-2048.webp" height="100" alt="Logo" />

[![pub package](https://img.shields.io/pub/v/refena_inspector.svg)](https://pub.dev/packages/refena_inspector)
![ci](https://github.com/refena/refena/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

The inspector for [Refena](https://pub.dev/packages/refena).

![inspector](https://raw.githubusercontent.com/refena/refena/main/resources/inspector-screenshot.webp)

## Usage

Add the [refena_inspector_client](https://pub.dev/packages/refena_inspector_client) and [refena_inspector](https://pub.dev/packages/refena_inspector) packages to your project.

```yaml
# pubspec.yaml
dependencies:
  refena_inspector_client: <version>

dev_dependencies:
  refena_inspector: <version>
```

Also add `.refena_inspector` to your `.gitignore` file.

```gitignore
# .gitignore
.refena_inspector/
```

Add the `RefenaInspectorObserver` to your `RefenaContainer` or `RefenaScope`.

This observer will handle the communication between your app and the inspector.

```dart
void main() {
  // or "RefenaScope" for Flutter projects
  RefenaContainer(
    observers: [
      RefenaInspectorObserver(), // <-- Add this observer
      RefenaTracingObserver(),
      RefenaDebugObserver(),
    ],
  );
}
```

Then start the inspector **before** your app is running:

```bash
dart run refena_inspector
```

Running the inspector afterwards also works, but it takes longer to connect.

You can configure the observer with custom actions:

```dart
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
);
```

As you can see, you can use nested maps to create a tree of actions.

One action can be either a `void Function(Ref)` or an `InspectorAction`.

You should use `InspectorAction` when you need to define parameters for the action.
