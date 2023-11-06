import 'package:refena/src/notifier/types/pure_notifier.dart';

/// A pre-implemented notifier for simple use cases.
/// You may add a [listener] to retrieve every [setState] event.
final class StateNotifier<T> extends PureNotifier<T> {
  final String Function(T state)? _describeState;

  StateNotifier(
    T initial, {
    String Function(T state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState {
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

  @override
  String describeState(T state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }
}
