import 'package:riverpie/src/notifier/listener.dart';
import 'package:riverpie/src/notifier/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// A [StateProvider] is a custom implementation of a [NotifierProvider]
/// that implements a default notifier with a [setState] method.
///
/// This is handy for simple use cases where you don't need any
/// business logic.
///
/// Usage:
/// final myProvider = StateProvider((ref) => 10); // define
/// ref.watch(myProvider); // read
/// ref.notifier(myProvider).setState((old) => old + 1); // write
class StateProvider<T> extends NotifierProvider<StateNotifier<T>, T> {
  StateProvider(T Function(Ref ref) builder, {super.debugLabel})
      : super((ref) => StateNotifier<T>(
              builder(ref),
              debugLabel: debugLabel ?? 'StateProvider<$T>',
            ));

  ProviderOverride overrideWithInitialState(T state) {
    return ProviderOverride<T>(
      this,
      NotifierProviderState<StateNotifier<T>, T>(
        StateNotifier<T>(
          state,
          debugLabel: debugLabel ?? runtimeType.toString(),
        ),
      ),
    );
  }
}

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
