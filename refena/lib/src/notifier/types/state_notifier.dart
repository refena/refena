import 'package:refena/src/notifier/listener.dart';
import 'package:refena/src/notifier/types/pure_notifier.dart';

/// A pre-implemented notifier for simple use cases.
/// You may add a [listener] to retrieve every [setState] event.
class StateNotifier<T> extends PureNotifier<T> {
  final ListenerCallback<T>? _listener;

  StateNotifier(T initial, {ListenerCallback<T>? listener, String? debugLabel})
      : _listener = listener,
        super(debugLabel: debugLabel) {
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
    if (_listener != null) {
      _listener!.call(oldState, newState);
    }
  }
}
