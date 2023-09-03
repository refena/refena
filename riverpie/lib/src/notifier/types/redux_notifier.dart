import 'package:riverpie/src/notifier/base_notifier.dart';

/// A notifier where the state can be updated by dispatching actions
/// by calling [dispatch].
///
/// You do not have access to [Ref] in this notifier, so you need to pass
/// the required dependencies via constructor.
///
/// From outside, you can should dispatch actions with
/// `ref.redux(provider).dispatch(action)`.
///
/// Dispatching from the notifier itself is also possible but
/// you will lose the implicit [debugOrigin] stored in a [Ref].
abstract class ReduxNotifier<T> extends BaseReduxNotifier<T> {
  ReduxNotifier({super.debugLabel});

  /// Returns a debug version of the [notifier] where
  /// you can set the state directly and dispatch actions
  ///
  /// Usage:
  /// final counter = ReduxNotifier.test(
  ///   redux: Counter(),
  ///   initialState: 11,
  /// );
  ///
  /// expect(counter.state, 11);
  /// counter.dispatch(IncrementAction());
  static TestableReduxNotifier<T> test<T, E extends Object>({
    required BaseReduxNotifier<T> redux,
    bool runInitialAction = false,
    T? initialState,
  }) {
    return TestableReduxNotifier(
      notifier: redux,
      runInitialAction: runInitialAction,
      initialState: initialState,
    );
  }
}
