# Initialization

## Early initialization

By default, all providers are initialized lazily.

You can also tell Refena to initialize some providers right away
by setting the `initialProviders` parameter:

```dart
void main() {
  runApp(
    RefenaScope(
      initialProviders: [
        databaseProvider,
      ],
      child: const MyApp(),
    ),
  );
}
```

## Overriding providers

All providers are initialized synchronously.

If one of your providers needs to do some asynchronous work,
you will need to override them at startup.

```dart
final persistenceProvider = Provider<PersistenceService>((ref) => throw 'Not initialized');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final PersistenceService persistenceService = await initPersistenceService();

  runApp(RefenaScope(
    overrides: [
      persistenceProvider.overrideWithValue(persistenceService),
    ],
    child: const MyApp(),
  ));
}
```

You can have multiple overrides depending on each other.

The override order is important:
An exception will be thrown on app start if you reference a provider that is not yet initialized.

If you have at least one `Provider` with `overrideWithFuture`,
you should await the initialization with `scope.ensureOverrides()`.

`scope.ensureOverrides()` returns a Future,
so you can also show a loading indicator while the app is initializing.

```dart
final persistenceProvider = Provider<PersistenceService>((ref) => throw 'Not initialized');
final apiProvider = Provider<ApiService>((ref) => throw 'Not initialized');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final scope = RefenaScope(
    overrides: [
      // order is important
      persistenceProvider.overrideWithFuture((ref) async {
        final prefs = await SharedPreferences.getInstance();
        return PersistenceService(prefs);
      }),
      apiProvider.overrideWithFuture((ref) async {
        // uses persistenceService from above
        final persistenceService = ref.read(persistenceProvider);
        final anotherService = await initAnotherService();
        return ApiService(persistenceService, anotherService);
      }),
    ],
    child: const MyApp(),
  );

  runApp(scope);
}
```

You can also override providers on demand:

```dart
// Access container for advanced use cases
RefenaContainer container = ref.container;

// Override the provider
container.set(persistenceProvider.overrideWithValue(persistenceService));
```

## Explicit container

Since `RefenaScope` just creates an implicit container in the background,
you can also create an explicit container and pass it to the `RefenaScope`.

This is useful for more advanced initialization scenarios before the first frame.

```dart
void main() async {
  final container = await init();

  runApp(
    RefenaScope.withContainer(
      container: container, // pass the container
      child: const MyApp(),
    ),
  );
}

Future<RefenaContainer> init() async {
  WidgetsFlutterBinding.ensureInitialized();

  final ref = RefenaContainer(
    overrides: [
      persistenceProvider.overrideWithFuture(getPersistenceService()),
    ],
  );

  // Optional if you have overrideWithFuture
  await ref.ensureOverrides();

  // Some initialization logic
  ref.read(persistenceProvider).init();
  ref.read(analyticsService).appStarted();
  ref.redux(profileProvider).dispatchAsync(InitProfileAction());

  return ref;
}
```
