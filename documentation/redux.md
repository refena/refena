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
    final count = context.ref.watch(counterProvider);
    return Scaffold(
      body: Center(
        child: Text('$count'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.ref.redux(counterProvider).dispatch(IncrementAction());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## Action Types

Riverpie favors type-safety. Therefore, there are different types of `ReduxAction` that you can use.

You can optionally use the returned value of `dispatch` to get the new state.

| Action Type                  | State Change | Reduce method signature   |
|------------------------------|--------------|---------------------------|
| `ReduxAction`                | sync         | `S reduce()`              |
| `AsyncReduxAction`           | async        | `Future<S> reduce()`      |
| `ReduxActionWithResult`      | sync         | `(S, R) reduce()`         |
| `AsyncReduxActionWithResult` | async        | `Future<(S, R)> reduce()` |

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

## Error handling

You can easily handle errors like in any other Dart code.

It is important to notice that errors thrown in `after()` are not rethrown to the caller.

```dart
class IncrementAction extends AsyncReduxAction<Counter, int> {
  @override
  Future<int> reduce() {
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
