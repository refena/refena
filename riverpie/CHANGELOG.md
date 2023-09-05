## 0.24.0

- feat: add `GlobalAction`, a family of actions that don't belong to any notifier
- **BREAKING**: Change `with AddonActions` to `with GlobalActions`

## 0.23.0

- feat: throw full async stack trace when using `dispatchAsync`
- feat: add `postInit` for notifiers
- **BREAKING**: `ReduxNotifier`s should not dispatch actions directly anymore, override the getter `initialAction` instead

## 0.22.0

- feat: make add-on actions customizable
- feat: add `errorParser` to `RiverpieTracingPage` to better visualize errors
- feat: add default parser for `DioException` (without introducing a dependency to `dio`)
- fix: should emit events within `init` of a `ReduxNotifier`
- **BREAKING**: events now have `millisSinceEpoch` instead of `microsSinceEpoch`

## 0.21.0

- feat: add `addon` to `ReduxAction`
- feat: show execution time of `ReduxAction` in `RiverpieTracingPage`
- **BREAKING**: change `ref.emitMessage` to `ref.message`

## 0.20.0

- feat: add `NavigationService`, example usage: `ref.read(navigationProvider).push(MyPage())`
- feat: add `SnackBarService`, example usage: `ref.read(snackBarProvider).showSnackBar('Hello')`
- feat: add `ref.dispose(provider)`
- feat: add `ref.emitMessage` to emit custom messages to the observer

## 0.19.0

- feat: add error handling for redux actions
- feat: access `ref` within observers
- feat: add `defaultNotifyStrategy` parameter for `RiverpieScope`
- feat: improve `RiverpieTracingPage` UI
- feat: export `ProviderOverride`

## 0.18.0

- feat: improve `RiverpieTracingPage` UI

## 0.17.0

- feat: add `RiverpieTracingObserver` and `RiverpieTracingPage`
- **BREAKING**: distinguish between sync and async `ReduxAction` (see updated documentation)

## 0.16.0

- fix: should update `ref.watch` config
- feat: add `Provider.overrideWithValue`
- **BREAKING**: `Provider.overrideWithValue` to `Provider.overrideWithBuilder`
- **BREAKING**: renaming `setup` to `internalSetup` to avoid name clashes

## 0.15.1

- fix: missing `FutureFamilyProvider` export

## 0.15.0

- **BREAKING**: `ReduxAction` is now action based instead of event based

## 0.14.0

- feat: add `ChangeNotifierProvider`
- feat: add `FutureFamilyProvider`

## 0.13.0

- feat: add `provider.overrideWithFuture` for regular providers (should call `scope.ensureOverrides`)
- fix: refer to non-override from override

## 0.12.0

- feat: add origin of event (widget or notifier) to `EventEmittedEvent`
- feat: add `Notifier.test`, `AsyncNotifier.test` and `ReduxNotifier.test`
- **BREAKING**: `ReduxNotifier` requires a `ReduxProvider` now
- **BREAKING**: recommended emit method is `ref.redux(myReduxProvider).emit(MyEvent())`

## 0.11.0

- feat: add `ReduxNotifier`
- feat: add `ref.watch(provider.select(...))` to only rebuild when a specific value changes
- feat: add `toString` implementation to `AsyncValue`
- feat: add `toString` implementation to providers
- feat: add more options for `RiverpieHistoryObserver`
- fix: missing `ref` in `AsyncNotifier`
- **BREAKING**: add `ref` parameter to provider overrides
- **BREAKING**: rename `ChangeEvent.flagRebuild` to `ChangeEvent.rebuild`

## 0.10.0

- **BREAKING**: use `riverpie_flutter` for Flutter projects
- **BREAKING**: change `AsyncSnapshot` to `AsyncValue` to decouple from Flutter

## 0.9.0

- feat: add `AsyncNotifierProvider` and the corresponding `AsyncNotifier`
- feat: add `ref.future` to access the `Future` of an `AsyncNotifierProvider` or a `FutureProvider`
- feat: add `ref.watchWithPrev` to access the previous value of an `AsyncNotifierProvider`

## 0.8.0

- feat: add `context.ref` to also access `ref` inside `StatelessWidget`
- feat: add `RiverpieMultiObserver` to use multiple observers at once

## 0.7.0

- feat: add `ViewProvider`, the only provider that can watch other providers
- feat: add `initialProviders` parameter for `RiverpieScope`
- feat: add `exclude` parameter for `RiverpieDebugObserver`
- **BREAKING**: `setState` of `StateProvider` accepts a builder instead of a value

## 0.6.0

- feat: add `RiverpieObserver` and `RiverpieDebugObserver`
- feat: add `StateProvider` for simple use cases
- **BREAKING**: add `ref` parameter for `ensureRef` callback

## 0.5.1

- fix: lint fixes

## 0.5.0

- feat: `RiverpieScope.defaultRef` for global access to `ref`
- feat: `ref.stream` for manual stream access
- feat: `ref.watch(myProvider, rebuildWhen: (prev, next) => ...)` for more control over when to rebuild
- feat: use `ensureRef` within `initState` for `ref` access within initialization logic
- **BREAKING**: removed `ref.listen`, use `ref.watch(myProvider, listener: (prev, next) => ...)` instead

## 0.4.0

- **BREAKING**: `Consumer` does not have a `child` anymore, use `ExpensiveConsumer` instead

## 0.3.0

- feat: add `FutureProvider`

## 0.2.0

- feat: introduction of `PureNotifier`, a `Notifier` without access to `ref`
- **BREAKING**: add `ref` as parameter to every provider
- **BREAKING**: change `ref.notify` to `ref.notifier`

## 0.1.1

- docs: update README.md

## 0.1.0

- Initial release
