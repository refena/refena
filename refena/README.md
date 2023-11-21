![logo](https://raw.githubusercontent.com/refena/refena/main/resources/main-logo-512.webp)

[![pub package](https://img.shields.io/pub/v/refena.svg)](https://pub.dev/packages/refena)
![ci](https://github.com/refena/refena/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

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

Use `context.watch` to access the provider:

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int counterState = context.watch(counterProvider);
    return Scaffold(
      body: Center(
        child: Text('Counter state: $counterState'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.notifier(counterProvider).increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Or in Redux style:

```dart
final counterProvider = ReduxProvider<Counter, int>((ref) => Counter());

class Counter extends ReduxNotifier<int> {
  @override
  int init() => 10;
}

class AddAction extends ReduxAction<Counter, int> {
  final int amount;
  AddAction(this.amount);
  
  @override
  int reduce() => state + amount;
}

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int counterState = context.watch(counterProvider);
    return Scaffold(
      body: Center(
        child: Text('Counter state: $counterState'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.redux(counterProvider).dispatch(AddAction(2)),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Offering high traceability with [RefenaDebugObserver](#observer) and [RefenaTracingObserver](#-event-tracing):

```text
[Refena] Action dispatched: [ReduxCounter.SubtractAction] by [MyPage]
[Refena] Change by [ReduxCounter] triggered by [SubtractAction]
           - Prev: 8
           - Next: 5
           - Rebuild (1): [MyPage]
```

With a feature-rich [Refena Inspector](https://pub.dev/packages/refena_inspector):

![inspector](https://raw.githubusercontent.com/refena/refena/main/resources/inspector-screenshot.webp)

## Table of Contents

- [Refena vs Riverpod](#refena-vs-riverpod)
  - [Key differences](#-key-differences)
  - [Similarities](#-similarities)
  - [Downsides](#-downsides)
  - [Migration](#-migration)
- [Refena vs async_redux](#refena-vs-asyncredux)
- [Getting Started](#getting-started)
- [Access the state](#access-the-state)
- [Container and Scope](#container-and-scope)
- [Providers](#providers)
  - [Provider](#-provider)
  - [FutureProvider](#-futureprovider)
  - [FutureFamilyProvider](#-futurefamilyprovider)
  - [StateProvider](#-stateprovider)
  - [StreamProvider](#-streamprovider)
  - [ChangeNotifierProvider](#-changenotifierprovider)
  - [NotifierProvider](#-notifierprovider)
  - [AsyncNotifierProvider](#-asyncnotifierprovider)
  - [ReduxProvider](#-reduxprovider)
  - [ViewProvider](#-viewprovider)
  - [ViewFamilyProvider](#-viewfamilyprovider)
- [Notifiers](#notifiers)
- [Using ref](#using-ref)
  - [ref.read](#-refread)
  - [ref.watch](#-refwatch)
  - [ref.accessor](#-refaccessor)
  - [ref.stream](#-refstream)
  - [ref.future](#-reffuture)
  - [ref.rebuild](#-refrebuild)
  - [ref.notifier](#-refnotifier)
  - [ref.redux](#-refredux)
  - [ref.dispose](#-refdispose)
  - [ref.message](#-refmessage)
  - [ref.container](#-refcontainer)
  - [BuildContext Extensions](#-buildcontext-extensions)
- [What to choose?](#what-to-choose)
- [Performance Optimization](#performance-optimization)
- [ensureRef](#ensureref)
- [defaultRef](#defaultref)
- [Observer](#observer)
- [Tools](#tools)
  - [Event Tracing](#-event-tracing)
  - [Dependency Graph](#-dependency-graph)
  - [Inspector](#-inspector)
  - [Sentry](#-sentry)
- [Testing](#testing)
  - [Override providers](#-override-providers)
  - [Testing without Flutter](#-testing-without-flutter)
  - [Testing ReduxProvider](#-testing-reduxprovider)
  - [Testing Notifiers](#-testing-notifiers)
  - [Access the state within tests](#-access-the-state-within-tests)
  - [State events](#-state-events)
  - [Example test](#-example-test)
- [Add-ons](#add-ons)
  - [Snackbars](#-snackbars)
  - [Navigation](#-navigation)
  - [Actions](#-actions)
- [Dart only](#dart-only)
- [Deep Dives](#deep-dives)

## Refena vs Riverpod

Refena is aimed to be more notifier focused than Riverpod.

Refena also includes a comprehensive [Redux](https://pub.dev/documentation/refena/latest/topics/Redux-topic.html) implementation
that can be used for crucial parts of your app.

### ➤ Key differences

**Flutter native**:\
No `ConsumerWidget` or `ConsumerStatefulWidget`. You still use `StatefulWidget` or `StatelessWidget` as usual.
To access `ref`, you can either add `with Refena` (only in `StatefulWidget`) or call `context.ref`.

**Common super class**:\
`WatchableRef extends Ref`.
You can use `Ref` as a parameter type to implement util functions that need access to `ref`.
These functions can be called by providers and also by widgets.

**ref.watch**:\
Only the `ViewProvider` can `watch` other providers.
Every other provider only have `ref.read` or `ref.notifier` to access other providers.
This ensures that the notifier itself is not accidentally rebuilt.

**Use ref anywhere, anytime**:\
Don't worry that the `ref` within providers or notifiers becomes invalid.
They live as long as the `RefenaScope`.

**Notifier first**:\
With `Notifier`, `AsyncNotifier`, `PureNotifier`, and `ReduxNotifier`,
you can choose the right notifier for your use case.

### ➤ Similarities

**Testable**:\
Providers are stateless.
The state is stored in the `RefenaContainer`.
This makes providers testable.

**Type-safe**:\
Working with providers and notifiers are type-safe and null-safe.

**Auto register**:\
Don't worry that you forget to register a provider.
They are automatically registered when you use them.

### ➤ Downsides

**No `autodispose`**:\
Since there is no `ConsumerWidget`, providers are **never** disposed automatically.
Refena encourages you to use [ref.dispose](#-refdispose) to dispose providers explicitly.
For view models, you can use `ViewModelBuilder` which disposes the provider automatically.

### ➤ Migration

Use [refena_riverpod_extension](https://pub.dev/packages/refena_riverpod_extension)
to use Riverpod and Refena at the same time.

```dart
// Riverpod -> Refena
ref.refena.read(myRefenaProvider);

// Refena -> Riverpod
ref.riverpod.read(myRiverpodProvider);
```

Checkout [Refena for Riverpod developers](https://pub.dev/documentation/refena/latest/topics/Riverpod-topic.html) for more information.

## Refena vs async_redux

Compared to [async_redux](https://pub.dev/packages/async_redux),
Refena encourages you to split the state into multiple providers.

This makes it easier to implement isolated features,
so not only you have separation of concerns between UI and business logic,
but also between different features: You can only dispatch actions of the same provider.

Refena also favors dependency injection, so you can test each provider in isolation.

Another benefit is
that you can view the [dependency graph](#-dependency-graph) without any additional logic in your providers.

## Getting started

**Step 1: Add dependency**

Add [refena_flutter](https://pub.dev/packages/refena_flutter) for Flutter projects,
or [refena](https://pub.dev/packages/refena) for Dart projects.

```yaml
# pubspec.yaml
dependencies:
  refena_flutter: <version>
```

**Step 2: Add RefenaScope**

```dart
void main() {
  runApp(
    RefenaScope(
      child: const MyApp(),
    ),
  );
}
```

**Step 3: Define a provider**

```dart
final myProvider = Provider((ref) => 42);
```

**Step 4: Use the provider**

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final myValue = context.watch(myProvider);
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

To make your life easier, you can also skip the `ref` part: Just call `context.watch`.

In a `StatefulWidget`, you can use `with Refena` to access the `ref` directly.

```dart
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _CounterState();
}

class _MyPageState extends State<MyPage> with Refena {
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
    return Scaffold(
      body: Center(
        child: Consumer(
          builder: (context, ref) {
            final myValue = ref.watch(myProvider);
            return Text('The value is $myValue');
          }
        ),
      ),
    );
  }
}
```

## Container and Scope

The `RefenaContainer` is the root of your app. It holds the state of all providers.

In Flutter, you should use `RefenaScope` instead which provides easy access to the state from a `BuildContext`.

A `RefenaScope` is just a wrapper around a `RefenaContainer`.
If no container is provided, a new one is implicitly created.

```dart
void main() {
  runApp(
    RefenaScope( // <-- creates an implicit container
      child: const MyApp(),
    ),
  );
}
```

You can also create a container explicitly. Use `RefenaScope.withContainer` to provide the container:

```dart
void main() {
  final container = RefenaContainer();
  
  // pre init procedure
  container.set(databaseProvider.overrideWithValue(DatabaseService()));
  container.read(analyticsService).appStarted();

  runApp(
    RefenaScope.withContainer(
      container: container, // <-- explicit container
      child: const MyApp(),
    ),
  );
}
```

More about initialization [here](https://pub.dev/documentation/refena/latest/topics/Initialization-topic.html).

## Providers

There are many types of providers. Each one has its own purpose.

The most important ones are `Provider`, `NotifierProvider`, and `ReduxProvider` because they are the most flexible.

| Provider                 | Usage                 | Notifier API   | Can `watch`\* | Has `family`\* |
|--------------------------|-----------------------|----------------|---------------|----------------|
| `Provider`               | Constants or services | -              | No            | No             |
| `ViewProvider`           | View models           | -              | Yes           | Yes            |
| `FutureProvider`         | Async values          | -              | Yes           | Yes            |
| `StreamProvider`         | Streams               | -              | Yes           | Yes            |
| `StateProvider`          | Simple states         | `setState`     | No            | No             |
| `ChangeNotifierProvider` | More rebuild control  | Custom methods | No            | No             |
| `NotifierProvider`       | Regular services      | Custom methods | No            | No             |
| `AsyncNotifierProvider`  | Services with futures | Custom methods | No            | No             |
| `ReduxProvider`          | Action based services | Custom actions | No            | No             |

\* `watch` means that you can use `ref.watch` inside the provider build lambda.

\* `family` means that you can use `<Provider>.family` to create a parameterized collection of a provider.

### ➤ Provider

The `Provider` is the most basic provider. It is simple but very powerful.

Use this provider for immutable values (constants or stateless services).

```dart
final databaseProvider = Provider((ref) => DatabaseService());
```

To access the value:

```dart
// Everywhere
DatabaseService a = ref.read(databaseProvider);

// Inside a build method
DatabaseService a = ref.watch(databaseProvider);
```

This type of provider can replace your entire dependency injection solution.

### ➤ FutureProvider

Use this provider for asynchronous values.

The value is cached and only fetched once.

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

More about `AsyncValue` [here](https://pub.dev/documentation/refena/latest/topics/Async%20Value-topic.html).

### ➤ FutureFamilyProvider

Use this provider for multiple asynchronous values. Use `FutureProvider.family` for better readability.

```dart
final userProvider = FutureProvider.family<User, String>((ref, id) async {
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

### ➤ StreamProvider

Use this provider to listen to a stream.

```dart
final myProvider = StreamProvider<int>((ref) async* {
  yield 1;
  await Future.delayed(const Duration(seconds: 1));
  yield 2;
  await Future.delayed(const Duration(seconds: 1));
  yield 3;
});
```

Access:

```dart
build(BuildContext context) {
  AsyncValue<int> streamAsync = ref.watch(myProvider);
  return streamAsync.when(
    data: (value) => Text('The value is $value'),
    loading: () => const CircularProgressIndicator(),
    error: (error, stackTrace) => Text('Error: $error'),
  );
}
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
    final old = state.data ?? 0;
    state = AsyncValue.loading(old);
    await Future.delayed(const Duration(seconds: 1));
    state = AsyncValue.data(old + 1);
  }
}
```

Notice that `AsyncValue.loading()` can take an optional previous value.
This is handy if you want to show the previous value while loading.
When using `when`, it will automatically use the previous value by default.

```dart
build(BuildContext context) {
  final (counter, loading) = ref.watch(counterProvider.select((s) => (s, s.isLoading)));
  return counter.when(
    // also shows previous value even when it's loading
    data: (value) => Text('The value is $value (loading: $loading)'),
    
    // only shown initially when there is no previous value
    loading: () => Text('Loading...'),
    
    // always shows the error if the future fails (configurable)
    error: (error, stackTrace) => Text('Error: $error'),
  );
}
```

### ➤ ReduxProvider

[Redux full documentation](https://pub.dev/documentation/refena/latest/topics/Redux-topic.html).

The `ReduxProvider` is the strictest option. The `state` is solely altered by actions.

You need to provide other notifiers via constructor making the `ReduxNotifier` self-contained and testable.

This has two main benefits:

- **Logging:** With `RefenaDebugObserver`, you can see every action in the console.
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

  // This is called after the state transition
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
    final state = context.watch(counterProvider);
    return Scaffold(
      body: Column(
        children: [
          Text(state.toString()),
          ElevatedButton(
            onPressed: () => context.redux(counterProvider).dispatch(AddAction(2)),
            child: const Text('Increment'),
          ),
          ElevatedButton(
            onPressed: () => context.redux(counterProvider).dispatch(SubtractAction(3)),
            child: const Text('Decrement'),
          ),
        ],
      ),
    );
  }
}
```

Here is how the console output could look like with `RefenaDebugObserver`:

```text
[Refena] Action dispatched: [ReduxCounter.SubtractAction] by [MyPage]
[Refena] Change by [ReduxCounter] triggered by [SubtractAction]
           - Prev: 8
           - Next: 5
           - Rebuild (1): [MyPage]
```

You can additionally override `before`, `after`, and `wrapReduce` in a `ReduxAction` to add custom logic.

The redux feature is quite complex.
You can read more about it [here](https://pub.dev/documentation/refena/latest/topics/Redux-topic.html).

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
    final vm = context.watch(settingsVmProvider);
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

To automatically dispose the view model, you can use the `ViewModelBuilder` widget.

Nice to know: The `ViewModelBuilder` not only works with `ViewProvider` but with any provider.

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: settingsVmProvider,
      builder: (context, vm) {
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

You can also add lifecycle hooks to the view model:

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: settingsVmProvider,
      init: (context, ref) => ref.notifier(authProvider).init(),
      dispose: (context, ref) => ref.notifier(authProvider).dispose(),
      placeholder: (context) => Text('Loading...'), // while init is running
      error: (context, error, stackTrace) => Text('Error: $error'), // when init fails
      builder: (context, vm) {
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

### ➤ ViewFamilyProvider

Similar to `ViewProvider` but with a parameter. Use `ViewProvider.family` for better readability.

```dart
final settingsVmProvider = ViewProvider.family<SettingsVm, String>((ref, userId) {
  final auth = ref.watch(authProvider(userId));
  final themeMode = ref.watch(themeModeProvider);
  return SettingsVm(
    firstName: auth.firstName,
    lastName: auth.lastName,
    themeMode: themeMode,
    logout: () => ref.notifier(authProvider).logout(),
  );
});
```

A `ViewModelBuilder` would dispose the whole family provider.
You should use `FamilyViewModelBuilder` (or `ViewModelBuilder.family`) instead.
This will only dispose a member of the family on widget disposal.

```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int userId = 123;
    return ViewModelBuilder.family(
      provider: settingsVmProvider(userId),
      builder: (context, vm) {
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

A notifier holds the actual state and triggers rebuilds on widgets listening to them.

| Provider         | Usage                             | Provider                 | Exposes `ref` |
|------------------|-----------------------------------|--------------------------|---------------|
| `Notifier`       | For any use case                  | `NotifierProvider`       | Yes           |
| `ChangeNotifier` | For performance critical services | `ChangeNotifierProvider` | Yes           |
| `AsyncNotifier`  | For async values                  | `AsyncNotifierProvider`  | Yes           |
| `PureNotifier`   | For clean architectures           | `NotifierProvider`       | No            |
| `ReduxNotifier`  | For very clean architectures      | `ReduxProvider`          | No            |

### ➤ Lifecycle

Inside the `init` method, you can access the `ref` to read other providers.

The main goal is to return the initial state. Avoid any additional logic here.

```dart
class MyNotifier extends Notifier<int> {
  @override
  int init() {
    final persistenceService = ref.read(persistenceProvider);
    return persistenceService.getNumber();
  }
}
```

To do initial work, you can override `postInit`:

```dart
class MyNotifier extends Notifier<int> {
  @override
  int init() => 10;

  @override
  void postInit() {
    // do some work
  }
}
```

When `ref.dispose(provider)` is called, you can hook into the disposing process by overriding `dispose`.

```dart
class MyNotifier extends Notifier<int> {
  @override
  int init() => 10;

  @override
  void dispose() {
    // custom cleanup logic
    // everything is still accessible until the end of this method
  }
}
```

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

Read the value of a provider and rebuild the widget / provider when the value changes.

This should be used within a `build` method of a widget or inside a body of a `ViewProvider`.

**Warning:** Watching outside the `build` method can lead to inconsistent rebuilds.

```dart
Widget build(BuildContext context) {
  final ref = context.ref;
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

### ➤ ref.accessor

Similar to `Ref.read`, but instead of returning the state right away,
it returns a `StateAccessor` to get the state later.

This is useful if you need to read the latest state of a provider (`ViewProvider` in particular),
but you can't use `Ref.watch` when building a notifier.

More about [dependency injection](https://pub.dev/documentation/refena/latest/topics/Dependency%20Injection-topic.html).

```dart
final myViewProvider = ViewProvider((ref) {
  final counter = ref.watch(counterProvider);
  return MyView(counter);
});

final myProvider = NotifierProvider<MyNotifier, int>((ref) {
  // If we just use ref.read, then we don't have the latest state
  // of the myViewProvider.
  final view = ref.accessor(myViewProvider);
  return MyNotifier(view);
});

class MyNotifier extends Notifier<int> {
  final StateAccessor<MyView> _view;

  MyNotifier(this._view);

  @override
  int init() => 0;

  void add() {
    state += _view.state.counter;
  }
}
```

### ➤ ref.stream

Similar to `ref.watch` with `listener`, but you need to manage the subscription manually.

The subscription will not be disposed automatically.

Use this outside a `build` method.

```dart
final subscription = ref.stream(myProvider).listen((value) {
  print('The value changed from ${value.prev} to ${value.next}');
});
```

### ➤ ref.future

Get the `Future` of a `FutureProvider`, a `StreamProvider`, or an `AsyncNotifierProvider`.

```dart
Future<String> version = ref.future(versionProvider);
```

### ➤ ref.rebuild

Reruns the build method of a provider and triggers a rebuild on all listeners.

This is useful if you want to manually rebuild a provider.

Only available for rebuildable providers: `ViewProvider`, `FutureProvider`, `StreamProvider`.

Returns the result of the build method: `T`, `Future<T>`, `Stream<T>`.

```dart
Future<T> result = ref.rebuild(myFutureProvider);
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

await ref.redux(myReduxProvider).dispatchAsync(MyAsyncAction());
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

class _MyPageState extends State<MyPage> with Refena {
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
  }
}
```

### ➤ ref.message

Emits a message to the observer.

This might be handy if you use one of the built-in observers like `RefenaDebugObserver`.

The messages are also shown in the [inspector](#-inspector).

```dart
ref.message('Hello World');
```

Inside a `ReduxAction`, this method is available as `emitMessage`.

### ➤ ref.container

Returns the backing container.
The container exposes more advanced methods for edge cases like post-init overrides.

```dart
RefenaContainer container = ref.container;
```

### ➤ BuildContext Extensions

Some frequently used methods are available as extensions on `BuildContext`.

```dart
context.watch(myProvider);
context.read(myProvider);
context.notifier(myProvider).increment();
context.redux(myReduxProvider).dispatch(MyAction());
```

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
| `Provider`, `ReduxProvider`                    | notifiers, actions              | High        |
| `Provider`, `ViewProvider`, `NotifierProvider` | notifiers, view models          | Very high   |
| `Provider`, `ViewProvider`, `ReduxProvider`    | notifiers, view models, actions | Maximum     |

### ➤ Can I use different providers & notifiers together?

Yes. You can use any combination of providers and notifiers.

The cool thing about notifiers is that they are self-contained.

Usually, you don't need to create a view model for each page.
This refactoring can be done later when your page gets too complex.

### ➤ What layers should an app have?

Let's start from the UI (Widgets):

- **Widgets:** The UI layer. This is where you build your UI. It should not contain any business logic.
- **View Models:** This layer provides the data for the UI. It should not contain any business logic. Use `ViewProvider` for this layer.
- **Controllers:** This layer contains the business logic for one specific view (page). It should not contain any business logic shared between multiple views. Possible providers: `NotifierProvider`, `ReduxProvider`.
- **Services:** This layer contains the business logic that is shared between multiple views. A "service" is essentially a "feature" of your app. Possible providers: `NotifierProvider`, `ReduxProvider`.

As always, you don't need to use all layers. It depends on the complexity of your app.

- Create widgets and services first.
- If you notice that your widgets get too complex, you can add controllers or view models to avoid `StatefulWidget`s.

Simple `StatefulWidget`s are fine because they are still self-contained.
The problem starts when you want to test them.
View models makes it easier to test the UI.

This is a very pragmatic approach. You can also write the full architecture from the beginning.

Additional types like "repositories" can be added if you need them.
Usually, they can be treated as services (but more specialized) in this model.

You can open the [dependency graph](#-dependency-graph) to see how the layers are connected.

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

Do **not** execute `ref.watch` of the same provider multiple times
as only the last one will be used for the rebuild condition.
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

By default, `NotifyStrategy.equality` is used to reduce rebuilds.

You can change it to `NotifyStrategy.identity` to use `identical` instead of `==`.
This avoids comparing deeply nested objects.

```dart
void main() {
  runApp(
    RefenaScope(
      defaultNotifyStrategy: NotifyStrategy.identity,
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

Please note that you need `with Refena`.

```dart
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with Refena {
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
}
```

## defaultRef

If you are unable to access `ref`, there is a pragmatic solution for that.

You can use `RefenaScope.defaultRef` to access the providers and notifiers.

Remember that this is only for edge cases, and you should always use the accessible `ref` if possible.

```dart
void someFunction() {
  Ref ref = RefenaScope.defaultRef;
  ref.read(myProvider);
  ref.notifier(myNotifierProvider).doSomething();
}
```

## Observer

The `RefenaScope` accepts `observers`.

You can implement one yourself or just use the included `RefenaDebugObserver`.

```dart
void main() {
  runApp(
    RefenaScope(
      observers: [
        if (kDebugMode) ...[
          RefenaDebugObserver(),
        ],
      ],
      child: const MyApp(),
    ),
  );
}
```

Now you will see useful information printed into the console:

```text
[Refena] Provider initialized: [Counter]
          - Reason: INITIAL ACCESS
          - Value: 10
[Refena] Listener added: [SecondPage] on [Counter]
[Refena] Change by [Counter]
          - Prev: 10
          - Next: 11
          - Rebuild (2): [HomePage], [SecondPage]
```

Example implementation of a custom observer. Note that you also have access to `ref`.

```dart
class MyObserver extends RefenaObserver {
  @override
  void init() {
    // optional initialization logic
    ref.read(crashReporterProvider).init();
  }

  @override
  void handleEvent(RefenaEvent event) {
    if (event is ActionErrorEvent) {
      Object error = event.error;
      StackTrace stackTrace = event.stackTrace;

      ref.read(crashReporterProvider).report(error, stackTrace);

      if (error is ConnectionException) {
        // show snackbar
        ref.dispatch(ShowSnackBarAction(message: 'No internet connection'));
      }
    }
  }
}
```

## Tools

### ➤ Event Tracing

Refena includes a ready-to-use UI to trace the state changes.

First, you need to add the `RefenaTracingObserver` to the `RefenaScope`.

```dart
void main() {
  runApp(
    RefenaScope(
      observers: [RefenaTracingObserver()],
      child: const MyApp(),
    ),
  );
}
```

Then, you can use the `RefenaTracingPage` to show the state changes.

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
                builder: (_) => const RefenaTracingPage(),
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

![tracing-ui](https://raw.githubusercontent.com/refena/refena/main/resources/tracing-ui.png)

Side note:
The `RefenaTracingObserver` itself is quite performant as events are added and removed with `O(1)` complexity.
To build the tree, it uses `O(n^2)` complexity, where `n` is the number of events.
That's why you see a loading indicator when you open the tracing UI.

### ➤ Dependency Graph

You can open the `RefenaGraphPage` to see the dependency graph. It requires no setup.

Be aware that Refena only tracks dependencies during the build phase of a notifier,
hence, always prefer dependency injection!

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
                builder: (_) => const RefenaGraphPage(),
              ),
            );
          },
          child: const Text('Show graph'),
        ),
      ),
    );
  }
}
```

Here is how it looks like:

![graph-ui](https://raw.githubusercontent.com/refena/refena/main/resources/graph-ui.webp)

### ➤ Inspector

Both the `RefenaTracingPage` and the `RefenaGraphPage` are included in the [Refena Inspector](https://pub.dev/packages/refena_inspector).

![inspector](https://raw.githubusercontent.com/refena/refena/main/resources/inspector-screenshot.webp)

### ➤ Sentry

Use [refena_sentry](https://pub.dev/packages/refena_sentry) to add breadcrumbs to Sentry.

This is especially useful if you use Redux since you can see every action in Sentry.

![sentry](https://raw.githubusercontent.com/refena/refena/main/resources/sentry.webp)

## Testing

### ➤ Override providers

You can override any provider in your tests.

```dart
void main() {
  testWidgets('My test', (tester) async {
    await tester.pumpWidget(
      RefenaScope(
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

You can use `RefenaContainer` to test your providers without Flutter.

```dart
void main() {
  test('My test', () {
    final ref = RefenaContainer();

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
    final ref = RefenaContainer(
      overrides: [
        counterProvider.overrideWithReducer(
          reducer: {
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

### ➤ Testing Notifiers

You can use `Notifier.test` (or `AsyncNotifier.test`) to test your notifiers in isolation.

This is only useful if your notifier is not dependent on other providers,
or if you have specified all dependencies via constructor (dependency injection).

```dart
void main() {
  test('My test', () {
    final counter = Notifier.test(
      notifier: Counter(),
      initialState: 11,
    );

    expect(counter.state, 11);

    counter.notifier.increment();
    expect(counter.state, 12);
  });
}
```

### ➤ Access the state within tests

A `RefenaScope` is a `Ref`, so you can access the state directly.

```dart
void main() {
  testWidgets('My test', (tester) async {
    final ref = RefenaScope(
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

Use `RefenaHistoryObserver` to keep track of every state change.

```dart
void main() {
  testWidgets('My test', (tester) async {
    final observer = RefenaHistoryObserver();
    await tester.pumpWidget(
      RefenaScope(
        observers: [observer],
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

To test Redux, you can access `RefenaHistoryObserver.dispatchedActions`:

```dart
final observer = RefenaHistoryObserver.only(
  actionDispatched: true,
);

// ...

expect(observer.dispatchedActions.length, 2);
expect(observer.dispatchedActions, [
  isA<IncrementAction>(),
  isA<DecrementAction>(),
]);
```

### ➤ Example test

There is an example test that shows how to test a counter app.

[See the example test](https://pub.dev/documentation/refena/latest/topics/Testing-topic.html).

## Add-ons

Add-ons are features implemented on top of Refena,
so you don't have to write the boilerplate code yourself.
The add-ons are entirely optional, of course.

To get started, add the following import:

```dart
import 'package:refena_flutter/addons.dart';
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
ref.dispatchAsync(NavigateAction.push(SecondPage()));

// or wait for the result
final result = await ref.dispatchAsync<DateTime?>(
  NavigateAction.push(DatePickerPage()),
);
```

### ➤ Actions

The add-on actions are all implemented as `GlobalAction`.

So you can dispatch them from anywhere.

```dart
ref.dispatch(ShowSnackBarAction(message: 'Hello World from Action!'));
```

Please read the full documentation about global actions [here](https://pub.dev/documentation/refena/latest/topics/Redux-topic.html#global-actions).

You can easily customize the given add-ons by extending their respective "Base-" classes.

```dart
class CustomizedNavigationAction<T> extends BaseNavigationPushAction<T> {
  @override
  Future<T?> navigate() async {
    // get the key
    GlobalKey<NavigatorState> key = ref.read(navigationProvider).key;

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
class MyAction extends ReduxAction<Counter, int> with GlobalActions {
  @override
  int reduce() => state + 1;

  @override
  void after() {
    global.dispatchAsync(CustomizedNavigationAction());
  }
}
```

## Dart only

You can use Refena without Flutter.

```yaml
# pubspec.yaml
dependencies:
  refena: <version>
```

```dart
void main() {
  final ref = RefenaContainer();
  ref.read(myProvider);
  ref.notifier(myNotifier).doSomething();
  ref.stream(myProvider).listen((value) {
    print('The value changed from ${value.prev} to ${value.next}');
  });
}
```

## Deep dives

This README is a high-level overview of Refena.

To learn more about each topic, checkout the [topics](https://pub.dev/documentation/refena/latest/topics/Introduction-topic.html).

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
