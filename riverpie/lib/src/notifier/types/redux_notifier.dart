import 'package:riverpie/src/notifier/base_notifier.dart';

/// A notifier where the state can be updated by emitting events.
/// Events are emitted by calling [emit].
/// They are handled by the notifier with [reduce].
///
/// You do not have access to [ref] in this notifier, so you need to pass
/// the required dependencies via constructor.
abstract class ReduxNotifier<T, E extends Object>
    extends BaseReduxNotifier<T, E> {
  ReduxNotifier({super.debugLabel});

  /// Returns a debug version of the [notifier] where
  /// you can set the state directly.
  static TestableReduxNotifier<T, E> test<T, E extends Object>({
    required BaseReduxNotifier<T, E> redux,
    T? initialState,
  }) {
    return TestableReduxNotifier(
      notifier: redux,
      initialState: initialState,
    );
  }
}
