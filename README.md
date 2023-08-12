# Riverpie

[![pub package](https://img.shields.io/pub/v/riverpie.svg)](https://pub.dev/packages/riverpie)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A tiny state management library for Flutter. Inspired by [Riverpod](https://pub.dev/packages/riverpod).

## Preview

Define a provider:

```dart
final counterProvider = NotifierProvider<Counter, int>((ref) => Counter());

class Counter extends Notifier<int> {
  @override
  int init() => 10;

  void increment() => state++;
}
```

Add `with Riverpie` and access the provider:

```dart
class CounterPage extends StatefulWidget {
  @override
  State<CounterPage> createState() => _CounterState();
}

class _CounterState extends State<CounterPage> with Riverpie {
  @override
  Widget build(BuildContext context) {
    final myCounter = ref.watch(counterProvider);
    return Scaffold(
      body: Column(
        children: [
          Text('The counter is $myCounter'),
          ElevatedButton(
            onPressed: () {
              ref.notifier(counterProvider).increment();
              // in riverpod it would be:
              // ref.read(counterProvider.notifier).increment();
            },
            child: const Text('+ 1'),
          ),
        ],
      ),
    );
  }
}
```

## Riverpie vs Riverpod

Besides the syntactic sugar `with Riverpie`, Riverpie is aimed to be more lightweight and more opinionated than Riverpod.

### ➤ Key differences

Providers cannot `watch` other providers. Instead, you can access other providers with `ref.read` or `ref.notify`.

The only provider that can do this is the `ViewProvider` that is intended to be used as a "view model".

Don't worry that you unintentionally use `watch` inside providers because each `ref` is typed accordingly.

Notifiers are never disposed or rebuilt, don't worry that the `ref` becomes invalid.

### ➤ Similarities

The state is still bound to the `RiverpieScope` widget. This means that you can override every provider in your tests.

You still have type safety and can use `ref.watch` to rebuild your widget.

You don't need to register any provider. Just use access them.

## Getting started

**Step 1: Add dependency**

```yaml
# pubspec.yaml
dependencies:
  riverpie: <version>
```

**Step 2: Add RiverpieScope**

```dart
void main() {
  runApp(
    RiverpieScope(
      child: const MyApp(),
    ),
  );
}
```

**Step 3: Define a provider**

```dart
final myProvider = Provider((_) => 42);
```

**Step 4: Use the provider**

```dart
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _CounterState();
}

class _MyPageState extends State<MyPage> with Riverpie {
  @override
  Widget build(BuildContext context) {
    final myValue = ref.watch(myProvider);
    return Scaffold(
      body: Center(
        child: Text('The value is $myValue'),
      ),
    );
  }
}
```

## Stateful vs Stateless widgets

The easiest way to use Riverpie is to use a `StatefulWidget` and add `with Riverpie` to the `State` class.

A `StatelessWidget` alone cannot be used in combination with `Riverpie`.

However, you can use `Consumer` to access the state.

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref) {
        final myValue = ref.watch(myProvider);
        return Scaffold(
          body: Center(
            child: Text('The value is $myValue'),
          ),
        );
      },
    );
  }
}
```

## Providers

There are many types of providers. Each one has its own purpose.

The most important ones are `Provider` and `NotifierProvider` because they are the most flexible.

| Provider           | Usage                      | Notifier API       | Can `watch` |
|--------------------|----------------------------|--------------------|-------------|
| `Provider`         | For immutable values       | -                  | No          |
| `FutureProvider`   | For immutable async values | -                  | No          |
| `NotifierProvider` | For mutable values         | Define it yourself | No          |
| `StateProvider`    | For simple mutable values  | `setState`         | No          |
| `ViewProvider`     | For view models            | -                  | Yes         |

### ➤ Provider

Use this provider for immutable values.

```dart
final myProvider = Provider((ref) => 42);
```

You may initialize this during app start:

```dart
final myProvider = Provider<PersistenceService>((_) => throw 'Not initialized');

void main() async {
  final persistenceService = PersistenceService(await SharedPreferences.getInstance());
  runApp(
    RiverpieScope(
      overrides: [
        myProvider.overrideWithValue(persistenceService),
      ],
      child: const MyApp(),
    ),
  );
}
```

To access the value:

```dart
// Everywhere
int a = ref.read(myProvider);

// Inside a build method
int a = ref.watch(myProvider);
```

### ➤ FutureProvider

Use this provider for asynchronous values that never change.

Example use cases:
- fetch static data from an API (that does not change)
- fetch device information (that does not change)

The advantage over `FutureBuilder` is that the value is cached and the future is only called once.

```dart
import 'package:package_info_plus/package_info_plus.dart';

final versionProvider = FutureProvider((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});
```

Access:

```dart
build(BuildContext context) {
  AsyncSnapshot<String> versionAsync = ref.watch(versionProvider);
  return versionAsync.when(
    data: (version) => Text('Version: $version'),
    loading: () => const CircularProgressIndicator(),
    error: (error, stackTrace) => Text('Error: $error'),
  );
}
```

### ➤ NotifierProvider

Use this provider for mutable values.

This provider can be used in an MVC-like pattern.

The notifiers are **never** disposed. You may have custom logic to delete values within a state.

```dart
final counterProvider = NotifierProvider<Counter, int>((ref) => Counter());

class Counter extends Notifier<int> {
  @override
  int init() => 10;

  void increment() => state++;
}
```

To access the value:

```dart
// Everywhere
int a = ref.read(counterProvider);

// Inside a build method
int a = ref.watch(counterProvider);
```

To access the notifier:

```dart
Counter counter = ref.notifier(counterProvider);
```

Or within a click handler:

```dart
ElevatedButton(
  onPressed: () {
    ref.notifier(counterProvider).increment();
  },
  child: const Text('+ 1'),
)
```

### ➤ StateProvider

The `StateProvider` is handy for simple use cases where you only need a `setState` method.

```dart
final myProvider = StateProvider((ref) => 10);
```

Update the state:

```dart
ref.notifier(myProvider).setState(11);
```

### ➤ ViewProvider

The `ViewProvider` is the only provider that can `watch` other providers.

It is useful for view models that uses multiple providers.

```dart
class SettingsVm {
  final String firstName;
  final String lastName;
  final ThemeMode themeMode;
  final void Function() logout;  
}

final settingsVmProvider = ViewProvider((ref) {
  final auth = ref.watch(authProvider);
  final themeMode = ref.watch(themeModeProvider);
  return SettingsVm(
    firstName: auth.firstName,
    lastName: auth.lastName,
    themeMode: themeMode,
    logout: () => ref.notifier(authProvider).logout(),
  );
});
```

The widget:

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref) {
        final vm = ref.watch(settingsVmProvider);
        return Scaffold(
          body: Center(
            child: Column(
              children: [
                Text('First name: ${vm.firstName}'),
                Text('Last name: ${vm.lastName}'),
                Text('Theme mode: ${vm.themeMode}'),
                ElevatedButton(
                  onPressed: vm.logout,
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

## Notifiers

Every provider exposes some kind of notifier (except `Provider`).

A notifier holds the actual state and triggers rebuilds on widgets listening to them.

There are multiple kinds of notifiers. Use notifiers in combination with `NotifierProvider`.

| Provider           | Usage                      | Exposes `ref` |
|--------------------|----------------------------|---------------|
| `Notifier`         | For any use case           | Yes           |
| `PureNotifier`     | For clean architectures    | No            |

### ➤ Notifier

The `Notifier` is the fastest and easiest way to implement a notifier.

It has access to `ref`, so you can use any provider at any time.

```dart
// You need to specify the generics (<..>) to have the correct type inference
// Waiting for https://github.com/dart-lang/language/issues/524
final counterProvider = NotifierProvider<Counter, int>((ref) => Counter());

class Counter extends Notifier<int> {
  @override
  int init() => 10;

  void increment() {
    final anotherValue = ref.read(anotherProvider);
    state++;
  }
}
```

### ➤ PureNotifier

The `PureNotifier` is the stricter option.

It has no access to `ref` making this notifier self-contained.

This is often used in combination with dependency injection, where you provide the dependencies via constructor.

```dart
final counterProvider = NotifierProvider<PureCounter, int>((ref) {
  final persistenceService = ref.read(persistenceProvider);
  return PureCounter(persistenceService);
});

class PureCounter extends PureNotifier<int> {
  final PersistenceService _persistenceService;

  PureCounter(this._persistenceService);
  
  @override
  int init() => 10;

  void increment() {
    counter++;
    _persistenceService.persist();
  }
}
```

## Using ref

With `ref`, you can access the providers and notifiers.

**ref.read**

Read the value of a provider.

```dart
int a = ref.read(myProvider);
```

**ref.watch**

Read the value of a provider and rebuild the widget when the value changes.

This should be used within a `build` method.

```dart
build(BuildContext context) {
  final currentValue = ref.watch(myProvider);
  
  // ...
}
```

You may add an optional `listener` callback:

```dart
build(BuildContext context) {
  final currentValue = ref.watch(myProvider, listener: (prev, next) {
    print('The value changed from $prev to $next');
  });

  // ...
}
```

**ref.stream**

Similar to `ref.watch` with `listener`, but you need to manage the subscription manually.

The subscription will not be disposed automatically.

Use this outside of a `build` method.

```dart
final subscription = ref.stream(myProvider).listen((value) {
  print('The value changed from ${value.prev} to ${value.next}');
});
```

**ref.notifier**

Get the notifier of a provider.

```dart
Counter counter = ref.notifier(counterProvider);

// or

ref.notifier(counterProvider).increment();
```

## Performance Optimization

**ref.watch**

You may restrict the rebuilds to only a subset of the state.

```dart
build(BuildContext context) {
  final currentValue = ref.watch(
    myProvider,
    rebuildWhen: (prev, next) => prev.attribute != next.attribute,
  );
  
  // ...
}
```

## ensureRef

In a `StatefulWidget`, you can use `ensureRef` to access the providers and notifiers within `initState`.

You may also use `ref` inside `dispose` because `ref` is guaranteed to be initialized.

```dart
@override
void initState() {
  super.initState();
  ensureRef((ref) {
    ref.read(myProvider);
  });
  
  // or
  ensureRef();
}

@override
void dispose() {
  ensureRef((ref) {
    // This is safe now because we called `ensureRef` in `initState`
    ref.read(myProvider);
    ref.notifier(myNotifierProvider).doSomething();
  });
  super.dispose();
}
```

## defaultRef

If you are unable to access `ref`, there is a pragmatic solution for that.

You can use `RiverpieScope.defaultRef` to access the providers and notifiers.

Remember that this is only for edge cases and you should always use `ref` if possible.

```dart
void someFunction() {
  final ref = RiverpieScope.defaultRef;
  ref.read(myProvider);
  ref.notifier(myNotifierProvider).doSomething();
}
```

## Observer

The `RiverpieScope` accepts an optional `observer`.

You can implement one yourself or just use the included `RiverpieDebugObserver`.

```dart
void main() {
  runApp(
    RiverpieScope(
      observer: kDebugMode ? const RiverpieDebugObserver() : null,
      child: const MyApp(),
    ),
  );
}
```

Now you will see useful information printed into the console:

```text
[Riverpie] Provider initialized: <Counter>
            - Reason: INITIAL ACCESS
            - Value: 10
[Riverpie] Listener added: <SecondPage> on <Counter>
[Riverpie] Change by <Counter>
            - Prev: 10
            - Next: 11
            - Rebuild (2): <HomePage>, <SecondPage>
```

## License

MIT License

Copyright (c) 2023 Tien Do Nam

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
