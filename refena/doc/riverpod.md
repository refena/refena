# Refena for Riverpod developers

## Introduction

You might have noticed that Refena is similar to Riverpod.

However, there are still some things that need your attention when you want to migrate from Riverpod to Refena.

## Providers

| Riverpod                 | Refena                                                              |
|--------------------------|---------------------------------------------------------------------|
| `Provider`               | `Provider` for immutable values, `ViewProvider` for reactive values |
| `StateProvider`          | `StateProvider` (no change)                                         |
| `FutureProvider`         | `FutureProvider` (no change)                                        |
| `StreamProvider`         | `StreamProvider` (no change)                                        |
| `ChangeNotifierProvider` | `ChangeNotifierProvider` (no change)                                |
| `StateNotifierProvider`  | `NotifierProvider` (drop the `State` part)                          |
| `NotifierProvider`       | `NotifierProvider` (no change)                                      |
| `AsyncNotifierProvider`  | `AsyncNotifierProvider` (no change)                                 |

Family providers:

| Riverpod                | Refena                                                  |
|-------------------------|---------------------------------------------------------|
| `Provider.family`       | `ViewProvider.family` (only reactive version available) |
| `FutureProvider.family` | `FutureProvider.family` (no change)                     |
| Other                   | Not supported                                           |

New providers:

| Refena          | Description                                                |
|-----------------|------------------------------------------------------------|
| `ViewProvider`  | The only provider that can watch other providers           |
| `ReduxProvider` | A provider where you dispatch actions to get the new state |

## No ConsumerWidget or ConsumerStatefulWidget

In Refena, there is no `ConsumerWidget` or `ConsumerStatefulWidget`.

You can access the providers directly in the `build` method:

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final counter = context.watch(counterProvider);
    return Text('$counter');
  }
}
```

## AutoDispose

In Refena, providers never dispose themselves automatically.

Instead, you need to call `ref.dispose(provider)` manually (usually in a `StatefulWidget`'s `dispose` method):

```dart
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  @override
  void dispose() {
    context.dispose(counterProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counter = context.watch(counterProvider);
    return Text('$counter');
  }
}
```

Use `ViewModelBuilder` or `FamilyViewModelBuilder` widgets to dispose providers automatically.

## Watching

Do **not** execute `ref.watch` of the same provider multiple times
as only the last one will be used for the rebuild condition.
Instead, you should use *Records* to combine multiple values.

```dart
Widget build(BuildContext context) {
  final (themeMode, locale) = context.watch(settingsProvider.select((settings) {
    return (settings.theme, settings.locale);
  }));
}
```

## Access notifiers

A slight difference between Riverpod and Refena is how you access the notifiers.

| Riverpod                      | Refena                   |
|-------------------------------|--------------------------|
| `ref.read(provider.notifier)` | `ref.notifier(provider)` |

## Listener

In Riverpod, you can listen to a provider by calling `ref.listen(provider, (prev, next) {})`.

In Refena, there are two ways to listen to a provider:

Outside the `build` method:

```dart
final subscription = ref.stream(provider).listen((prev, next) {
  // This callback is called whenever the provider changes
});

// Cancel the subscription when you don't need it anymore
subscription.cancel();
```

Inside the `build` method:

```dart
final state = ref.watch(provider, listener: (prev, next) {
  // This callback is called whenever the provider changes
});
```

## Lifespan of Ref

Compared to Riverpod,
the `ref` object in Refena is always available because it's just a wrapper around `RefenaContainer`.
You will never need to worry about the lifespan of `ref`.

## NotifierProvider

In Refena, the `NotifierProvider` looks like this:

```dart
final counterProvider = NotifierProvider<Counter, int>((ref) {
  return Counter();
});

class Counter extends Notifier<int> {
  @override
  int init() => 0;

  void increment() => state++;
}
```

Notice that there is a `ref` parameter in the `NotifierProvider`'s builder function.
All providers have this parameter to allow you to use the **Dependency Injection** pattern.

Also, the `Notifier` class has the `init` method that returns the initial state.
This is similar to the `build` method in Riverpod.

## StateProvider

To change the state of a `StateProvider`, there is a slight difference between Riverpod and Refena.

| Riverpod                              | Refena                                              |
|---------------------------------------|-----------------------------------------------------|
| `ref.read(provider.notifier).state++` | `ref.notifier(provider).setState((old) => old + 1)` |

You need to access the notifier first to keep the code consistent with other providers.

## Refactoring

### ➤ ConsumerWidget

Before:

```dart
class MyPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider);
    return Text('$counter');
  }
}
```

After:

```dart
class MyPage extends StatelessWidget { // change to native widget
  @override
  Widget build(BuildContext context) {
    final ref = context.ref; // get ref from context
    final counter = ref.watch(counterProvider);
    return Text('$counter');
  }
}
```

### ➤ ConsumerStatefulWidget

Before:

```dart
class MyPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  @override
  Widget build(BuildContext context) {
    final counter = ref.watch(counterProvider);
    return Text('$counter');
  }
}
```

After:

```dart
class MyPage extends StatefulWidget { // change to native widget
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with Refena { // add mixin
  @override
  Widget build(BuildContext context) {
    // ref is available from the mixin
    final counter = ref.watch(counterProvider);
    return Text('$counter');
  }
}
```
