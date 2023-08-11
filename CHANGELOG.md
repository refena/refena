## 0.7.0

- feat: add `ViewProvider`, the only provider that can watch other providers
- feat: add `exclude` parameter for `RiverpieDebugObserver`

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
