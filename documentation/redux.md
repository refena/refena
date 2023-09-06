# Redux

Riverpie has a wide variety of providers.
`ReduxProvider` is a provider that allows you to implement Redux architecture in your app.

Its state is altered by dispatching actions. Actions are simple classes that contain all the information needed to alter the state.

Actions are dispatched to the notifier using the `ref.redux(notifier).dispatch(action)` method.

The anatomy of an action is inspired by [async_redux](https://pub.dev/packages/async_redux).

## Example

```dart
final counterProvider = ReduxProvider<Counter, int>((ref) {
  return Counter();
});

class Counter extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class IncrementAction extends ReduxAction<Counter, int> {
  @override
  int reduce() {
    return state + 1;
  }
}
```

The widget:

```dart
class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final count = ref.watch(counterProvider);
    return Scaffold(
      body: Center(
        child: Text('$count'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.redux(counterProvider).dispatch(IncrementAction());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## Action Types

Riverpie favors type-safety. Therefore, there are different types of `ReduxAction` that you can use.

| Action Type                  | State Change | Additional Result | Reduce method signature   |
|------------------------------|--------------|-------------------|---------------------------|
| `ReduxAction`                | sync         | no                | `S reduce()`              |
| `AsyncReduxAction`           | async        | no                | `Future<S> reduce()`      |
| `ReduxActionWithResult`      | sync         | yes               | `(S, R) reduce()`         |
| `AsyncReduxActionWithResult` | async        | yes               | `Future<(S, R)> reduce()` |

This type-system allows you to easily distinguish between synchronous and asynchronous actions.

You cannot use `dispatch` to dispatch an asynchronous action. You are forced to use `dispatchAsync` instead.

With the `unawaited_futures` lint, you can easily spot asynchronous actions that are not awaited.

Furthermore, you are always able to obtain the new state:

```dart
// inferred as int
final newStateA = ref.redux(counterProvider).dispatch(IncrementAction());

// also inferred as int
final newStateB = await ref.redux(counterProvider).dispatchAsync(MyAsyncIncrementAction());

// compile-time error
final newStateC = ref.redux(counterProvider).dispatch(MyAsyncIncrementAction());
```

Enjoy compile-time type-safety and type inference.

| Action Type                  | Dispatch method                                                       |
|------------------------------|-----------------------------------------------------------------------|
| `ReduxAction`                | `dispatch`                                                            |
| `AsyncReduxAction`           | `dispatchAsync`                                                       |
| `ReduxActionWithResult`      | `dispatch`, `dispatchWithResult`, `dispatchTakeResult`                |
| `AsyncReduxActionWithResult` | `dispatchAsync`, `dispatchAsyncWithResult`, `dispatchAsyncTakeResult` |

### ➤ ReduxAction

This is the most basic type of action. The state is altered synchronously.

```dart
class IncrementAction extends ReduxAction<Counter, int> {
  @override
  int reduce() {
    return state + 1;
  }
}
```

```dart
int newState = ref.redux(counterProvider).dispatch(IncrementAction());
```

### ➤ AsyncReduxAction

This action is used when you want to perform asynchronous operations.

```dart
class IncrementAction extends AsyncReduxAction<Counter, int> {
  @override
  Future<int> reduce() async {
    await Future.delayed(Duration(seconds: 1));
    return state + 1;
  }
}
```

```dart
int newState = await ref.redux(counterProvider).dispatchAsync(IncrementAction());
```

### ➤ ReduxActionWithResult

Sometimes, you want to have some kind of "feedback" from the action, but you don't want to save it in the state.

There are multiple plausible scenarios for this:

- The feedback is not relevant to the state.
- The feedback is too big to be saved in the state (e.g., binary data)

```dart
enum IncrementResult {
  success,
  failure,
}

class IncrementAction extends ReduxActionWithResult<Counter, int, IncrementResult> {
  @override
  (int, IncrementResult) reduce() {
    if (state < 10) {
      return (state + 1, IncrementResult.success);
    } else {
      return (state, IncrementResult.failure);
    }
  }
}
```

```dart
// get new state and result
final (newState, result) = ref.redux(counterProvider).dispatchWithResult(IncrementAction());

// dispatch but only get the result
final result = ref.redux(counterProvider).dispatchTakeResult(IncrementAction());
```

### ➤ AsyncReduxActionWithResult

The counterpart to `ReduxActionWithResult` for asynchronous actions.

```dart
class LoginAction extends AsyncReduxActionWithResult<AuthService, AuthState, String?> {
  final String email;
  final String password;

  LoginAction(this.email, this.password);

  @override
  Future<(AuthState, String?)> reduce() async {
    try {
      final response = await _apiService.login(email, password);
      return (state.copyWith(user: response.user), response.token);
    } catch (e) {
      return (state, null);
    }
  }
}
```

```dart
void loginHandler() async {
  final token = await ref.redux(authProvider).dispatchAsyncTakeResult(LoginAction(email, password));
  if (token != null) {
    // navigate to home
  } else {
    // show error
  }
}
```

## Notifier lifecycle

Inside a notifier, you are not allowed to dispatch actions directly.

However, there are two actions that are dispatched during the lifecycle of a notifier:
`initialAction` and `disposeAction`.

Implement those actions for post-initialization actions, long-running polling actions, or cleanup actions.

Remember: In Riverpie, notifiers are never disposed, except you call `ref.dispose(provider)` explicitly.

```dart
class Counter extends ReduxNotifier<int> {
  @override
  int init() => 0;
  
  @override
  get initialAction => IncrementAction();
  
  @override
  get disposeAction => CleanupAction();
}
```

## Action lifecycle

The lifecycle of an action is as follows:

1. `before()` is called, if it fails, the action is aborted.
2. `reduce()` is called, if it fails, the action is aborted.
3. `after()` is called (regardless of any previous failures).

```dart
class IncrementAction extends ReduxAction<Counter, int> {
  @override
  void before() {
    // called before reduce()
  }

  @override
  int reduce() {
    return state + 1;
  }

  @override
  void after() {
    // called after reduce()
  }
}
```

Optionally, you can also override `wrapReduce()` to wrap the `reduce()` method in a `try-catch` block.

```dart
class IncrementAction extends ReduxAction<Counter, int> {
  @override
  int wrapReduce() {
    try {
      return super.wrapReduce();
    } catch (e) {
      // handle error
    }
  }

  @override
  int reduce() {
    return state + 1;
  }
}
```

It is important to note that `before()` is called before `wrapReduce()`, and `after()` is called after `wrapReduce()`.

## Dispatching actions from actions

You can dispatch actions from actions. This is useful when you want to perform multiple actions in a row.

```dart
class IncrementAction extends ReduxAction<Counter, int> {
  @override
  int reduce() {
    dispatch(SomeAction());
    dispatch(AnotherAction());
    return state + 1;
  }
  
  @override
  void after() {
    dispatch(CleanupAction());
  }
}
```

Only actions of the same notifier are allowed to be dispatched.

To dispatch external actions, you first need to specify them via dependency injection.

```dart
final counterProvider = ReduxProvider<Counter, int>((ref) {
  MyService externalService = ref.notifier(externalServiceProvider);
  return Counter(externalService);
});

class Counter extends ReduxNotifier<int> {
  final MyService externalService;
    
  Counter(this.externalService);
  
  @override
  int init() => 0;
}
```

Then you can dispatch them with `external(notifier).dispatch(action)`.

```dart
class IncrementAction extends ReduxAction<Counter, int> {
  @override
  int reduce() {
    external(notifier.externalService).dispatch(SomeAction());
    return state + 1;
  }
}
```

## Global actions

Sometimes, you want to implement an action that does not belong to any notifier.

You can do this by implementing a `GlobalAction`.

These actions do not belong to any notifier and therefore have no state.

Inside the action, you can access `ref` to dispatch other actions or to read other providers.

Do not use global actions excessively as they have no restrictions or scope.
This means that it is hard to track all the side effects that they might cause.

```dart
class ResetAppAction extends GlobalAction {
  @override
  void reduce() {
    // dispatch actions from other providers
    ref.redux(authProvider).dispatch(LogoutAction());
    ref.redux(persistenceProvider).dispatch(ClearPersistenceAction());
    
    // dispatch other global actions
    ref.dispatch(AnotherGlobalAction());
    
    // read other providers
    final theme = ref.read(themeProvider);
  }
}
```

When you have access to `Ref`, you can just call `ref.dispatch(action)`.

```dart
ref.dispatch(ResetAppAction());
```

Inside an ordinary action, you need to add the `GlobalActions` mixin first.

Then you can dispatch global actions with `global.dispatch(action)`.

```dart
class IncrementAction extends ReduxAction<Counter, int> with GlobalActions {
  @override
  int reduce() {
    global.dispatch(ResetAppAction());
    return state + 1;
  }
}
```

Similar to regular actions, there are also asynchronous global actions or global actions with a result.

| Action Type                   | Additional Result | Reduce method signature |
|-------------------------------|-------------------|-------------------------|
| `GlobalAction`                | no                | `void reduce()`         |
| `AsyncGlobalAction`           | no                | `Future<void> reduce()` |
| `GlobalActionWithResult`      | yes               | `R reduce()`            |
| `AsyncGlobalActionWithResult` | yes               | `Future<R> reduce()`    |

When you dispatch, there is no need to distinguish between actions with and without a result anymore.
The return type is just `void` for actions without a result.

| Action Type                   | Dispatch method | Return type    |
|-------------------------------|-----------------|----------------|
| `GlobalAction`                | `dispatch`      | `void`         |
| `GlobalActionWithResult`      | `dispatch`      | `R`            |
| `AsyncGlobalAction`           | `dispatchAsync` | `Future<void>` |
| `AsyncGlobalActionWithResult` | `dispatchAsync` | `Future<R>`    |

## Error handling

You can easily handle errors like in any other Dart code.

The error type and the stack trace are unmodified.

It is important to notice that errors thrown in `after()` are not rethrown to the caller.

```dart
class IncrementAction extends AsyncReduxAction<Counter, int> {
  @override
  Future<int> reduce() async {
    try {
      await dispatchAsync(AsyncErrorAction());
    } catch (e) {
      // handle error
    }
  }
}

class AsyncErrorAction extends AsyncReduxAction<Counter, int> {
  @override
  Future<int> reduce() async {
    throw Exception('Something went wrong');
  }
}
```

In case there are no try-catch blocks, the error will be thrown to the caller.

```dart
void onTap() async {
  try {
    await context.ref.redux(counterProvider).dispatchAsync(AsyncErrorAction());
  } catch (e) {
    // handle error
  }
}
```

To safely observe all errors (e.g., to send them to a crash reporting service),
you can implement a `RiverpieObserver`.

```dart
class MyObserver extends RiverpieObserver {
  @override
  void handleEvent(RiverpieEvent event) {
    if (event is ActionErrorEvent) {
      BaseAction action = event.action;
      ActionLifecycle lifecycle = event.lifecycle; // before, reduce, after
      Object error = event.error;
      StackTrace stackTrace = event.stackTrace;
      
      // you can access ref inside the observer
      ref.read(crashReporterProvider).report(error, stackTrace);
      
      if (error is ConnectionException) {
        // show snackbar
        ref.dispatch(ShowSnackBarAction(message: 'No internet connection'));
      }
    }
  }
}
```

Register the observer in the `RiverpieScope`:

```dart
void main() {
  runApp(RiverpieScope(
    observer: RiverpieMultiObserver(
      observers: [
        RiverpieDebugObserver(),
        MyObserver(),
      ],
    ),
    child: MyApp(),
  ));
}
```

## Tracing

All errors are also logged by the `RiverpieTracingObserver`.

They can be shown by opening the `RiverpieTracingPage`:

Here is how it looks like:

![tracing-ui](https://raw.githubusercontent.com/Tienisto/riverpie/main/resources/tracing-ui.png)
