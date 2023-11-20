# Dependency injection

## Motivation

Dependency injection is a common pattern in software development to decouple components while
making them easier to test. Another benefit is that it allows Refena to build a dependency graph.

Dependency injection plays a big role if you use `Provider`, `ViewProvider`, `NotifierProvider`, or `ReduxProvider`.

## ViewProvider

A `ViewProvider` rebuilds itself whenever the value of a provider changes.
Always use `ref.watch` to read other providers.

```dart
final userDataRepository = ViewProvider<UserDataRepository>((ref) {
  final id = ref.watch(userIdProvider);
  return UserDataRepository(id);
});
```

## Provider, NotifierProvider, and ReduxProvider

Since `Provider`, `NotifierProvider`, and `ReduxProvider` never rebuild themselves,
you can't use `ref.watch` inside them.

There are two ways to read other providers:

### ➤ Non-rebuildable providers

If you read non-rebuildable providers (e.g. `Provider`, `NotifierProvider`, or `ReduxProvider`),
you can just use `ref.read` since the value of the provider never changes.

```dart
final settingsProvider = NotifierProvider<SettingsService, SettingsState>((ref) {
  // The persistenceProvider is initialized once and never change.
  final persistenceService = ref.read(persistenceProvider);
  return SettingsService(persistenceService);
});
```

### ➤ Rebuildable providers

If you read rebuildable providers (e.g. `ViewProvider`),
you should use `ref.accessor` to inject a `StateAccessor` into the notifier.
It allows you to read the latest state of the provider.

```dart
final settingsProvider = NotifierProvider<SettingsService, SettingsState>((ref) {
  // Here, the userDataRepository might change
  // if the user logs in or out.
  final repository = ref.accessor(userDataRepository);
  return SettingsService(repository);
});

class SettingsService extends Notifier<SettingsState> {
  final StateAccessor<UserDataRepository> repository;
  
  SettingsService(this.repository);

  @override
  SettingsState init() => SettingsState.initial();
  
  void setLocale(Locale locale) {
    // With .state, you can access the latest state of the provider
    repository.state.setLocale(locale);
    state = state.copyWith(locale: locale);
  }
}
```

## Why not always ref.watch?

Refena differentiates between rebuildable and non-rebuildable providers.

There are several reasons for this:

### ➤ Implicit documentation

Having `Provider` and `ViewProvider` allows you to see at a glance whether a provider is rebuildable or not.

For example, if you don't expect a singleton to rebuild itself, make it a `Provider`.

### ➤ Notifiers should not rebuild

When you are implementing a notifier method, you might modify the state of an injected provider.

If the `NotifierProvider` is rebuildable,
a change of the injected provider will also rebuild the `NotifierProvider` itself because
it depends on the injected provider.
This will cause the current instance of the `NotifierProvider` to be disposed
(even when the method is not finished yet).

To avoid this, Refena requires most of the providers (especially notifier-oriented providers) to be non-rebuildable.

```dart
final childProvider = NotifierProvider<Child, ChildState>((ref) {
  // ref.watch will throw a compile-time error
  final parentState = ref.read(parentProvider);
  return Child(parentState);
});

class Child extends Notifier<ChildState> {
  final ParentState parentState;
  
  Child(this.parentState);

  @override
  ChildState init() => ChildState.initial(
    count: parentState.count,
  );
  
  void increment() {
    // This will rebuild the parentProvider
    ref.notifier(parentProvider).increment();
    
    // If the NotifierProvider is rebuildable, this will throw an exception
    // because current instance is already disposed.
    // To prevent this kind of bug, ref.watch is prohibited in NotifierProvider.
    state = state.copyWith(count: state.count + 1);
  }
}
```

## Doesn't it introduce bugs?

If you want to change a `Provider` to a `ViewProvider`,
then all non-rebuildable consumers should use `ref.accessor` instead of `ref.read`.

This is why Riverpod suggests using `ref.watch` everywhere.

However, this is not needed if you have a clear distinction between rebuildable and non-rebuildable providers.
This additional type system allows Refena to provide lint rules that prevent this kind of bug.

## Summary

| Provider                                              | Inject rebuildable       | Inject non-rebuildable |
|-------------------------------------------------------|--------------------------|------------------------|
| Rebuildable<br>`ViewProvider`, `FutureProvider`       | `ref.watch`              | `ref.watch`            |
| Non-rebuildable<br>`NotiferProvider`, `ReduxProvider` | `ref.accessor`           | `ref.read`             |
| `Provider`                                            | change to `ViewProvider` | `ref.read`             |
