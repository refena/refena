# Riverpie

[![pub package](https://img.shields.io/pub/v/riverpie.svg)](https://pub.dev/packages/riverpie)
![ci](https://github.com/Tienisto/riverpie/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

/ˈrɪvər-paɪ/

A state management library for Dart and Flutter.
Inspired by [Riverpod](https://pub.dev/packages/riverpod) and [async_redux](https://pub.dev/packages/async_redux).

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

Use `context.ref` to access the provider:

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Ref ref = context.ref;
    int counterState = ref.watch(counterProvider);
    return Scaffold(
      body: Center(
        child: Text('Counter state: $counterState'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.notifier(counterProvider).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

## Table of Contents

- [Riverpie vs Riverpod](#riverpie-vs-riverpod)
    - [Key differences](#-key-differences)
    - [Similarities](#-similarities)
- [Getting Started](#getting-started)
- [Access the state](#access-the-state)
- [Providers](#providers)
    - [Provider](#-provider)
    - [FutureProvider](#-futureprovider)
    - [StateProvider](#-stateprovider)
    - [ChangeNotifierProvider](#-changenotifierprovider)
    - [NotifierProvider](#-notifierprovider)
    - [AsyncNotifierProvider](#-asyncnotifierprovider)
    - [ReduxProvider](#-reduxprovider)
    - [ViewProvider](#-viewprovider)
- [Notifiers](#notifiers)
- [Using ref](#using-ref)
    - [ref.read](#-refread)
    - [ref.watch](#-refwatch)
    - [ref.stream](#-refstream)
    - [ref.future](#-reffuture)
    - [ref.notifier](#-refnotifier)
    - [ref.redux](#-refredux)
    - [ref.dispose](#-refdispose)
    - [ref.message](#-refmessage)
- [What to choose?](#what-to-choose)
- [Performance Optimization](#performance-optimization)
- [ensureRef](#ensureref)
- [defaultRef](#defaultref)
- [Observer](#observer)
- [Tracing UI](#tracing-ui)
- [Testing](#testing)
    - [Override providers](#-override-providers)
    - [Testing without Flutter](#-testing-without-flutter)
    - [Testing ReduxProvider](#-testing-reduxprovider)
    - [Access the state within tests](#-access-the-state-within-tests)
    - [State events](#-state-events)
    - [Example test](#-example-test)
- [Add-ons](#add-ons)
    - [Snackbars](#-snackbars)
    - [Navigation](#-navigation)
    - [Actions](#-actions)
- [Dart only](#dart-only)

## Riverpie vs Riverpod

Riverpie is aimed to be more pragmatic and more notifier focused than Riverpod.

Riverpie also includes a comprehensive [Redux](https://github.com/Tienisto/riverpie/blob/main/documentation/redux.md) implementation
that can be used for crucial parts of your app.

### ➤ Key differences

**Flutter native**:\
No `ConsumerWidget` or `ConsumerStatefulWidget`. You still use `StatefulWidget` or `StatelessWidget` as usual.
To access `ref`, you can either add `with Riverpie` (only in `StatefulWidget`) or call `context.ref`.

**Common super class**:\
`WatchableRef extends Ref`.
You can use `Ref` as parameter to implement util functions that need access to `ref`.
These functions can be called by providers and widgets.

**ref.watch**:\
Only the `ViewProvider` can `watch` other providers.
Every other provider can only be accessed with `ref.read` or `ref.notifier` within a provider body.
This ensures that the notifier itself is not accidentally rebuilt.

**Use ref anywhere, anytime**:\
Don't worry that the `ref` within providers or notifiers becomes invalid.
They live as long as the `RiverpieScope`.
With `ensureRef`, you also can access the `ref` within `initState` or `dispose` of a `StatefulWidget`.

**No provider modifiers**:\
There is no `.family` or `.autodispose`. This makes the provider landscape simple and straightforward.

**Notifier first**:\
With `Notifier`, `AsyncNotifier`, `PureNotifier`, and `ReduxNotifier`,
you can choose the right notifier for your use case.

### ➤ Similarities

**Testable**:\
The state is still bound to the `RiverpieScope` widget. This means that you can override every provider in your tests.

**Type-safe**:\
Every provider is correctly typed. Enjoy type-safe auto completions when you read them.

**Auto register**:\
You don't need to register any provider. They will be initialized lazily when you access them.

## Getting started

**Step 1: Add dependency**

Add [riverpie_flutter](https://pub.dev/packages/riverpie_flutter) for Flutter projects, or [riverpie](https://pub.dev/packages/riverpie) for Dart projects.

```yaml
# pubspec.yaml
dependencies:
  riverpie_flutter: <version>
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
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final myValue = context.ref.watch(myProvider);
    return Scaffold(
      body: Center(
        child: Text('The value is $myValue'),
      ),
    );
  }
}
```

## Access the state

The state should be accessed via `ref`.

You can get the `ref` right from the `context`:

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final myValue = ref.watch(myProvider);
    final mySecondValue = ref.watch(mySecondProvider);
    return Scaffold(
      body: Column(
        children: [
          Text('The value is $myValue'),
          Text('The second value is $mySecondValue'),
        ],
      ),
    );
  }
}
```

In a `StatefulWidget`, you can use `with Riverpie` to access the `ref` directly.

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

You can also use `Consumer` to access the state. This is useful to rebuild only a part of the widget tree:

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

| Provider                 | Usage                                | Notifier API   | Can `watch` |
|--------------------------|--------------------------------------|----------------|-------------|
| `Provider`               | Constants or stateless services      | -              | No          |
| `FutureProvider`         | Immutable async values               | -              | No          |
| `FutureFamilyProvider`   | Immutable collection of async values | -              | No          |
| `StateProvider`          | Simple states                        | `setState`     | No          |
| `ChangeNotifierProvider` | Performance critical services        | Custom methods | No          |
| `NotifierProvider`       | Regular services                     | Custom methods | No          |
| `AsyncNotifierProvider`  | Services that need futures           | Custom methods | No          |
| `ReduxProvider`          | Action based services                | Action based   | No          |
| `ViewProvider`           | View models                          | -              | Yes         |

### ➤ Provider

Use this provider for immutable values (constants or stateless services).

```dart
final myProvider = Provider((ref) => 42);
```

You may initialize this during app start.\
The override order is important:
An exception will be thrown on app start if you reference a provider that is not yet initialized.\
If you have at least one future override, you should await the initialization with `ref.ensureOverrides()`.

```dart
final persistenceProvider = Provider<PersistenceService>((ref) => throw 'Not initialized');
final apiProvider = Provider<ApiService>((ref) => throw 'Not initialized');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final scope = RiverpieScope(
    overrides: [
      // order is important
      persistenceProvider.overrideWithFuture((ref) async {
        final prefs = await SharedPreferences.getInstance();
        return PersistenceService(prefs);
      }),
      apiProvider.overrideWithFuture((ref) async {
        final persistenceService = ref.read(persistenceProvider);
        final anotherService = await initAnotherService();
        return ApiService(persistenceService, anotherService);
      }),
    ],
    child: const MyApp(),
  );

  await scope.ensureOverrides();

  runApp(scope);
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
  AsyncValue<String> versionAsync = ref.watch(versionProvider);
  return versionAsync.when(
    data: (version) => Text('Version: $version'),
    loading: () => const CircularProgressIndicator(),
    error: (error, stackTrace) => Text('Error: $error'),
  );
}
```

### ➤ FutureFamilyProvider

Use this provider for multiple asynchronous values.

```dart
final userProvider = FutureFamilyProvider<User, String>((ref, id) async {
  final api = ref.read(apiProvider);
  return api.fetchUser(id);
});
```

Access:

```dart
build(BuildContext context) {
  AsyncValue<User> userAsync = ref.watch(userProvider('123'));
}
```

### ➤ StateProvider

The `StateProvider` is handy for simple use cases where you only need a `setState` method.

```dart
final myProvider = StateProvider((ref) => 10);
```

Update the state:

```dart
ref.notifier(myProvider).setState((old) => old + 1);
```

### ➤ ChangeNotifierProvider

Use this provider if you have many rebuilds and need to optimize performance (e.g., progress indicator).

```dart
final myProvider = ChangeNotifierProvider((ref) => MyNotifier());

class MyNotifier extends ChangeNotifier {
  int _counter = 0;
  int get counter => _counter;

  void increment() {
    _counter++;
    notifyListeners();
  }
}
```

Use `ref.watch` to listen and `ref.notifier` to call methods:

```dart
build(BuildContext context) {
  final counter = ref.watch(myProvider).counter;
  return Scaffold(
    body: Center(
      child: Column(
        children: [
          Text('The value is $counter'),
          ElevatedButton(
            onPressed: ref.notifier(myProvider).increment,
            child: const Text('Increment'),
          ),
        ],
      ),
    ),
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

### ➤ AsyncNotifierProvider

Use this provider for mutable async values.

```dart
final counterProvider = AsyncNotifierProvider<Counter, int>((ref) => Counter());

class Counter extends AsyncNotifier<int> {
  @override
  Future<int> init() async {
    await Future.delayed(const Duration(seconds: 1));
    return 0;
  }

  void increment() async {
    // Set `future` to update the state.
    future = ref.notifier(apiProvider).fetchAsyncNumber();
    
    // Use `setState` to also access the old value.
    setState((snapshot) async => (snapshot.curr ?? 0) + 1);

    // Set `state` directly if you want more control.
    state = AsyncSnapshot.waiting();
    await Future.delayed(const Duration(seconds: 1));
    state = AsyncSnapshot.withData(ConnectionState.done, old + 1);
  }
}
```

Often, you want to implement some kind of refresh logic that shows the previous value while loading.

There is `ref.watchWithPrev` for that.

```dart
final counterState = ref.watchWithPrev(counterProvider);
AsyncSnapshot<int>? prev = counterState.prev; // show the previous value while loading
AsyncSnapshot<int> curr = counterState.curr; // might be AsyncSnapshot.waiting()
```

### ➤ ReduxProvider

[Redux full documentation](https://github.com/Tienisto/riverpie/blob/main/documentation/redux.md).

The `ReduxProvider` is the strictest option. The `state` is solely altered by actions.

You need to provide other notifiers via constructor making the `ReduxNotifier` self-contained and testable.

This has two main benefits:

- **Logging:** With `RiverpieDebugObserver`, you can see every action in the console.
- **Testing:** You can easily test the state transitions.

```dart
final counterProvider = ReduxProvider<Counter, int>((ref) {
  return Counter(ref.notifier(providerA), ref.notifier(providerB));
});

class Counter extends ReduxNotifier<int> {
  final ServiceA serviceA;
  final ServiceB serviceB;
  
  Counter(this.serviceA, this.serviceB);
  
  @override
  int init() => 0;
}

class AddAction extends ReduxAction<Counter, int> {
  final int amount;
  AddAction(this.amount);
  
  @override
  int reduce() => state + amount;
}

class SubtractAction extends ReduxAction<Counter, int> {
  final int amount;
  SubtractAction(this.amount);
  
  @override
  int reduce() => state - amount;

  @override
  void after() {
    // dispatch actions of other notifiers
    external(notifier.serviceA).dispatch(SomeAction());

    // access the state of other notifiers
    if (notifier.serviceB.state == 3) {
      // ...
    }

    // dispatch actions in the same notifier
    dispatch(AddAction(amount - 1));
  }
}
```

The widget can trigger actions with `ref.redux(provider).dispatch(action)`:

```dart
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final state = ref.watch(counterProvider);
    return Scaffold(
      body: Column(
        children: [
          Text(state.toString()),
          ElevatedButton(
            onPressed: () => ref.redux(counterProvider).dispatch(AddAction(2)),
            child: const Text('Increment'),
          ),
          ElevatedButton(
            onPressed: () => ref.redux(counterProvider).dispatch(SubtractAction(3)),
            child: const Text('Decrement'),
          ),
        ],
      ),
    );
  }
}
```

Here is how the console output could look like with `RiverpieDebugObserver`:

```text
[Riverpie] Action dispatched: [ReduxCounter.SubtractAction] by [MyPage]
[Riverpie] Change by [ReduxCounter] triggered by [SubtractAction]
            - Prev: 8
            - Next: 5
            - Rebuild (1): [MyPage]
```

You can additionally override `before`, `after`, and `wrapReduce` in a `ReduxAction` to add custom logic.

The redux feature is quite complex.
You can read more about it [here](https://github.com/Tienisto/riverpie/blob/main/documentation/redux.md).

### ➤ ViewProvider

The `ViewProvider` is the only provider that can `watch` other providers.

This is useful for view models that depend on multiple providers.

This requires more code but makes your app more testable.

```dart
class SettingsVm {
  final String firstName;
  final String lastName;
  final ThemeMode themeMode;
  final void Function() logout;

  // insert constructor
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
    final vm = context.ref.watch(settingsVmProvider);
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
  }
}
```

## Notifiers

A notifier holds the actual state and triggers rebuilds on widgets listening to them.

| Provider         | Usage                             | Provider                 | Exposes `ref` |
|------------------|-----------------------------------|--------------------------|---------------|
| `Notifier`       | For any use case                  | `NotifierProvider`       | Yes           |
| `ChangeNotifier` | For performance critical services | `ChangeNotifierProvider` | Yes           |
| `AsyncNotifier`  | For async values                  | `AsyncNotifierProvider`  | Yes           |
| `PureNotifier`   | For clean architectures           | `NotifierProvider`       | No            |
| `ReduxNotifier`  | For very clean architectures      | `ReduxProvider`          | No            |

### ➤ Notifier vs PureNotifier

`Notifier` and `PureNotifier` are very similar.

The difference is that the `Notifier` has access to `ref` and the `PureNotifier` does not.

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

A `PureNotifier` has no access to `ref` making this notifier self-contained.

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

### ➤ ref.read

Read the value of a provider.

```dart
int a = ref.read(myProvider);
```

### ➤ ref.watch

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

### ➤ ref.stream

Similar to `ref.watch` with `listener`, but you need to manage the subscription manually.

The subscription will not be disposed automatically.

Use this outside of a `build` method.

```dart
final subscription = ref.stream(myProvider).listen((value) {
  print('The value changed from ${value.prev} to ${value.next}');
});
```

### ➤ ref.future

Get the `Future` of a `FutureProvider` or an `AsyncNotifierProvider`.

```dart
Future<String> version = ref.future(versionProvider);
```

### ➤ ref.notifier

Get the notifier of a provider.

```dart
Counter counter = ref.notifier(counterProvider);

// or

ref.notifier(counterProvider).increment();
```

### ➤ ref.redux

Dispatches an action to a `ReduxProvider`.

```dart
ref.redux(myReduxProvider).dispatch(MyAction());

await ref.redux(myReduxProvider).dispatch(MyAction());
```

### ➤ ref.dispose

Providers are **never** disposed automatically.
Instead, you should create a custom "cleanup" logic.

To make your life easier, you can dispose a provider by calling this method:

```dart
ref.dispose(myProvider);
```

This can be called in a `StatefulWidget`'s `dispose` method and is safe to do so because `ref.dispose` does not trigger a rebuild.

```dart
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with Riverpie {
  @override
  void dispose() {
    ref.dispose(myProvider); // <-- dispose the provider
    super.dispose();
  }
}
```

In a notifier, you can hook into the disposing process by overriding `dispose`.

```dart
class MyNotifier extends Notifier<int> {
  @override
  int init() => 10;

  @override
  void dispose() {
    // custom cleanup logic
    // everything is still accessible until the end of this method
    super.dispose();
  }
}
```

### ➤ ref.message

Emits a message to the observer.

This might be handy if you have a `RiverpieTracingPage`.

```dart
ref.message('Hello World');
```

Inside a `ReduxAction`, this method is available as `emitMessage`.

## What to choose?

There are lots of providers and notifiers. Which one should you choose?

For most use cases, `Provider` and `Notifier` are more than enough.

If you work in an environment where clean architecture is important,
you may want to use `ReduxProvider` and `ViewProvider`.

Be aware that you will need to write more boilerplate code.

| Providers & Notifiers                          | Boilerplate                     | Testability |
|------------------------------------------------|---------------------------------|-------------|
| `Provider`, `StateProvider`                    |                                 | Low         |
| `Provider`, `NotifierProvider`                 | notifiers                       | Medium      |
| `Provider`, `ViewProvider`, `NotifierProvider` | notifiers, view models          | High        |
| `Provider`, `ViewProvider`, `ReduxProvider`    | notifiers, view models, actions | Very high   |

### ➤ Can I use different providers & notifiers together?

Yes. You can use any combination of providers and notifiers.

The cool thing about notifiers is that they are self-contained.

It is actually pragmatic to use `Notifier` and `ReduxNotifier` together, as each has its own strengths.

## Performance Optimization

### ➤ Selective watching

You may restrict the rebuilds to only a subset of the state with `provider.select`.

Here, the `==` operator is used to compare the previous and next value.

```dart
build(BuildContext context) {
  final themeMode = ref.watch(
    settingsProvider.select((settings) => settings.themeMode),
  );
  
  // ...
}
```

For more complex logic, you can use `rebuidWhen`.

```dart
build(BuildContext context) {
  final currentValue = ref.watch(
    myProvider,
    rebuildWhen: (prev, next) => prev.attribute != next.attribute,
  );
  
  // ...
}
```

You can use both `select` and `rebuildWhen` at the same time.
The `select` will be applied, when `rebuildWhen` returns `true`.

Do **not** execute `ref.watch` multiple times as only the last one will be used for the rebuild condition.
Instead, you should use *Records* to combine multiple values.

```dart
build(BuildContext context) {
  final (themeMode, locale) = ref.watch(settingsProvider.select((settings) {
    return (settings.theme, settings.locale);
  }));
}
```

### ➤ Notify Strategy

A more global approach than `select` is to set a `defaultNotifyStrategy`.

By default, `NotifyStrategy.identity` is used.
This means that the rebuild is triggered whenever a new instance is assigned.
This avoids comparing deeply nested objects.

If you think that your `==` overrides are fast enough, you can use `NotifyStrategy.equality` instead.

```dart
void main() {
  runApp(
    RiverpieScope(
      defaultNotifyStrategy: NotifyStrategy.equality,
      child: const MyApp(),
    ),
  );
}
```

You probably noticed the `default-` prefix.
Of course, you can override `updateShouldNotify` for each notifier individually.

```dart
class MyNotifier extends Notifier<int> {
  @override
  int init() => 10;
  
  @override
  bool updateShouldNotify(int old, int next) => old != next;
}
```

## ensureRef

In a `StatefulWidget`, you can use `ensureRef` to access the providers and notifiers within `initState`.

You may also use `ref` inside `dispose` because `ref` is guaranteed to be initialized.

Please note that you need `with Riverpie`.

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

Remember that this is only for edge cases, and you should always use the accessible `ref` if possible.

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
[Riverpie] Provider initialized: [Counter]
            - Reason: INITIAL ACCESS
            - Value: 10
[Riverpie] Listener added: [SecondPage] on [Counter]
[Riverpie] Change by [Counter]
            - Prev: 10
            - Next: 11
            - Rebuild (2): [HomePage], [SecondPage]
```

In case you want to use multiple observers at once, there is a `RiverpieMultiObserver` for that.

```dart
void main() {
  runApp(
    RiverpieScope(
      observer: RiverpieMultiObserver(
        observers: [
          RiverpieDebugObserver(),
          MyCustomObserver(),
        ],
      ),
      child: const MyApp(),
    ),
  );
}
```

Example implementation of a custom observer. Note that you also have access to `ref`.

```dart
class MyObserver extends RiverpieObserver {
  @override
  void init() {
    // optional initialization logic
    ref.read(crashReporterProvider).init();
  }

  @override
  void handleEvent(RiverpieEvent event) {
    if (event is ActionErrorEvent) {
      Object error = event.error;
      StackTrace stackTrace = event.stackTrace;

      ref.read(crashReporterProvider).report(error, stackTrace);
    }
  }
}
```

## Tracing UI

Riverpie includes a ready-to-use UI to trace the state changes.

First, you need to add the `RiverpieTracingObserver` to the `RiverpieScope`.

```dart
void main() {
  runApp(
    RiverpieScope(
      observer: RiverpieTracingObserver(),
      child: const MyApp(),
    ),
  );
}
```

Then, you can use the `RiverpieTracingPage` to show the state changes.

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RiverpieTracingPage(),
              ),
            );
          },
          child: const Text('Show tracing'),
        ),
      ),
    );
  }
}
```

Here is how it looks like:

![tracing-ui](https://raw.githubusercontent.com/Tienisto/riverpie/main/resources/tracing-ui.png)

Side note: The `RiverpieTracingObserver` itself is quite performant as events are added and removed with `O(1)` complexity.
To build the tree, it uses `O(n^2)` complexity, where `n` is the number of events. That's why you see a loading indicator when you open the tracing UI.

## Testing

### ➤ Override providers

You can override any provider in your tests.

```dart
void main() {
  testWidgets('My test', (tester) async {
    await tester.pumpWidget(
      RiverpieScope(
        overrides: [
          myProvider.overrideWithValue(42),
          myNotifierProvider.overrideWithNotifier((ref) => MyNotifier(42)),
        ],
        child: const MyApp(),
      ),
    );
  });
}
```

### ➤ Testing without Flutter

You can use `RiverpieContainer` to test your providers without Flutter.

```dart
void main() {
  test('My test', () {
    final ref = RiverpieContainer();

    expect(ref.read(myCounter), 0);
    ref.notifier(myCounter).increment();
    expect(ref.read(myCounter), 1);
  });
}
```

### ➤ Testing ReduxProvider

For simple tests, you can use `ReduxNotifier.test`. It provides a `state` getter, a `setState` method and optionally allows you to specify an initial state.

```dart
void main() {
  test('My test', () {
    final counter = ReduxNotifier.test(
      redux: Counter(),
      initialState: 11,
    );

    expect(counter.state, 11);

    counter.dispatch(IncrementAction());
    expect(counter.state, 12);

    counter.setState(42); // set state directly
    expect(counter.state, 42);
  });
}
```

To quickly override a `ReduxProvider`, you can use `overrideWithReducer`.

```dart
void main() {
  test('Override test', () {
    final ref = RiverpieContainer(
      overrides: [
        counterProvider.overrideWithReducer(
          overrides: {
            IncrementAction: (state) => state + 20,
            DecrementAction: null, // do nothing
          },
        ),
      ],
    );

    expect(ref.read(counterProvider), 0);

    // Should use the overridden reducer
    ref.redux(counterProvider).dispatch(IncrementAction());
    expect(ref.read(counterProvider), 20);

    // Should not change the state
    ref.redux(counterProvider).dispatch(DecrementAction());
    expect(ref.read(counterProvider), 20);
  });
}
```

### ➤ Access the state within tests

A `RiverpieScope` is a `Ref`, so you can access the state directly.

```dart
void main() {
  testWidgets('My test', (tester) async {
    final ref = RiverpieScope(
      child: const MyApp(),
    );
    await tester.pumpWidget(ref);

    // ...
    ref.notifier(myNotifier).increment();
    expect(ref.read(myNotifier), 2);
  });
}
```

### ➤ State events

Use `RiverpieHistoryObserver` to keep track of every state change.

```dart
void main() {
  testWidgets('My test', (tester) async {
    final observer = RiverpieHistoryObserver();
    await tester.pumpWidget(
      RiverpieScope(
        observer: observer,
        child: const MyApp(),
      ),
    );

    // ...
    expect(observer.history, [
      ProviderInitEvent(
        provider: myProvider,
        notifier: myNotifier,
        cause: ProviderInitCause.access,
        value: 1,
      ),
      ChangeEvent(
        notifier: myNotifier,
        action: null,
        prev: 1,
        next: 2,
        rebuild: [WidgetRebuildable<MyLoginPage>()],
      ),
    ]);
  });
}
```

### ➤ Example test

There is an example test that shows how to test a counter app.

[See the example test](https://github.com/Tienisto/riverpie/blob/main/documentation/testing.md).

## Add-ons

Add-ons are features implemented on top of Riverpie,
so you don't have to write the boilerplate code yourself.
The add-ons are entirely optional of course.

To get started, add the following import:

```dart
import 'package:riverpie_flutter/addons.dart';
```

The core library never imports the add-ons, so we don't need to publish an additional package
as the add-ons are tree-shaken away if you don't use them.

### ➤ Snackbars

Show snackbar messages.

First, set up the `snackBarProvider`:

```dart
MaterialApp(
  scaffoldMessengerKey: ref.watch(snackBarProvider).key,
  home: MyPage(),
)
```

Then show a message:

```dart
class MyNotifier extends Notifier<int> {
  @override
  int init() => 10;

  void increment() {
    state++;
    ref.read(snackbarProvider).showMessage('Incremented');
  }
}
```

Optionally, you can also dispatch a `ShowSnackBarAction`:

```dart
ref.dispatch(ShowSnackBarAction(message: 'Hello World from Action!'));
```

### ➤ Navigation

Manage your navigation stack.

First, set up the `navigationProvider`:

```dart
MaterialApp(
  navigatorKey: ref.watch(navigationProvider).key,
  home: MyPage(),
)
```

Then navigate:

```dart
class MyNotifier extends Notifier<int> {
  @override
  int init() => 10;

  void someMethod() async {
    state++;
    ref.read(navigationProvider).push(MyPage());

    // or wait for the result
    final result = await ref.read(navigationProvider).push<DateTime>(DatePickerPage());
  }
}
```

Optionally, you can also dispatch a `NavigateAction`:

```dart
ref.dispatch(NavigateAction.push(SecondPage()));

// or wait for the result
final result = await ref.dispatchAsync<DateTime>(
  NavigateAction.push(DatePickerPage()),
);
```

### ➤ Actions

Inside a `ReduxAction`, you can access all add-ons by adding `with AddonActions`.

This mixin adds an `addon` getter to the action.

```dart
class MyAction extends ReduxAction<Counter, int> with AddonActions {
  @override
  int reduce() => state + 1;

  @override
  void after() {
    addon.dispatch(ShowSnackBarAction(message: 'Hello World from Action!'));
    addon.dispatch(NavigateAction.push(SecondPage()));
  }
}
```

You can easily customize the given add-ons by extending their respective "Base-" classes.

```dart
class CustomizedNavigationAction<T> extends BaseNavigationPushAction<T> {
  @override
  Future<T?> navigate() async {
    // get the key
    GlobalKey<NavigatorState> key = notifier.service.key;
    
    // navigate
    T? result = await key.currentState!.push<T>(
      MaterialPageRoute(
        builder: (_) => _SecondPage(),
      ),
    );

    return result;
  }
}
```

Then, you can use your customized action:

```dart
class MyAction extends ReduxAction<Counter, int> with AddonActions {
  @override
  int reduce() => state + 1;

  @override
  void after() {
    addon.dispatch(CustomizedNavigationAction());
  }
}
```

## Dart only

You can use Riverpie without Flutter.

```yaml
# pubspec.yaml
dependencies:
  riverpie: <version>
```

```dart
void main() {
  final ref = RiverpieContainer();
  ref.read(myProvider);
  ref.notifier(myNotifier).doSomething();
  ref.stream(myProvider).listen((value) {
    print('The value changed from ${value.prev} to ${value.next}');
  });
}
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
