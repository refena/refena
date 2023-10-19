![logo](https://raw.githubusercontent.com/refena/refena/main/resources/main-logo-512.webp)

[![pub package](https://img.shields.io/pub/v/refena_riverpod_extension.svg)](https://pub.dev/packages/refena_riverpod_extension)
![ci](https://github.com/refena/refena/actions/workflows/ci.yml/badge.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Provides extension getters to use [Riverpod](https://pub.dev/packages/riverpod) and [Refena](https://pub.dev/packages/refena) together.

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: <version>
  refena_flutter: <version>
  refena_riverpod_extension: <version>
```

## Usage

### ➤ Setup

Wrap your app with `RefenaRiverpodExtensionScope` below `RefenaScope` and `ProviderScope`:

```dart
void main() {
  runApp(
    ProviderScope(
      child: RefenaScope(
        child: RefenaRiverpodExtensionScope(
          child: MyApp(),
        ),
      ),
    ),
  );
}
```

### ➤ Access Riverpod from Refena

Let's say you have a `StateProvider` written in Riverpod:

```dart
final riverpodCounterProvider = StateProvider((ref) => 0);
```

Then you can access it from Refena by using the `Ref.riverpod` getter:

```dart
final refenaProvider = ViewProvider((ref) {
  // This is reactive!
  // The refenaProvider will be rebuilt when the riverpodCounterProvider changes.
  final counter = ref.riverpod.watch(riverpodCounterProvider);
  return counter.state;
});
```

### ➤ Access Refena from Riverpod

Let's say you have a `ReduxProvider` written in Refena:

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
```

Then you can access it by using the `Ref.refena` getter:

```dart
final riverpodProvider = Provider((ref) {
  // There is no reactive way to access Refena from Riverpod.
  return ref.refena.read(counterProvider);
});

final riverpodProvider2 = NotifierProvider<RiverpodCounter, int>(() {
  return RiverpodCounter();
});

class RiverpodCounter extends Notifier<int> {
  @override
  int build() => 0;
  
  void dispatch(int amount) {
    // We can dispatch actions to Refena from Riverpod.
    ref.refena.redux(counterProvider).dispatch(AddAction(amount));
  }
}
```
