import 'package:refena/src/notifier/types/pure_notifier.dart';

/// A pre-implemented notifier for simple use cases.
/// You may add a [listener] to retrieve every [setState] event.
class StateNotifier<T> extends PureNotifier<T> {
  StateNotifier(T initial, {super.debugLabel}) {
    state = initial;
  }

  @override
  T init() => state;

  /// Use this to change the state of the notifier.
  ///
  /// Usage:
  /// ref.notifier(myProvider).setState((_) => 'new value');
  void setState(T Function(T old) newStateBuilder) {
    final oldState = state;
    final newState = newStateBuilder(oldState);
    state = newState;
  }
}
