# Riverpie

A tiny state management library for Flutter. Inspired by [Riverpod](https://pub.dev/packages/riverpod).

## Motivation

After developing several production-grade apps with Riverpod, I found that it's a bit "too much" for my taste.

The code should be Flutter-like as possible, `ConsumerWidget` and `ConsumerStatefulWidget` disrupts the developer experience (e.g. refactoring doesn't work).

I want to have a simple state management library that:

- still uses `StatelessWidget` and `StatefulWidget` as the main building blocks
- still has type safety as in Riverpod
- has no hierarchy of providers (just access another provider with `ref.read`)
- exposes a simple API: `ref.watch(provider)` to read, and `ref.notify(provider)` to write

## Features

Define a provider:

```dart
final counterProvider = NotifierProvider<Counter, int>(() => Counter());

class Counter extends Notifier<int> {
  @override
  int init() => 10;

  void increment() => state++;
}
```

Use the provider:

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
              ref.notify(counterProvider).increment();
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
final myProvider = Provider(() => 42);
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

The easiest way to use Riverpie is to use `StatefulWidget` and add `with Riverpie` to the state class.

However, you can also use `StatelessWidget` and `Consumer` to access the state.

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
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

### Provider

Use this provider for immutable values.

```dart
final myProvider = Provider(() => 42);
```

You may initialize this during app start:

```dart
final myProvider = Provider<PersistenceService>(() => throw 'Not initialized');

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

### NotifierProvider

Use this provider for mutable values.

This provider can be used in an MVC-like pattern.

The notifiers are **never** disposed. You may have custom logic to delete values within a state.

```dart
final counterProvider = NotifierProvider<Counter, int>(() => Counter());

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
Counter counter = ref.notify(counterProvider);
```

Or within a click handler:

```dart
ElevatedButton(
  onPressed: () {
    ref.notify(counterProvider).increment();
  },
  child: const Text('+ 1'),
)
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
