import 'package:riverpie/riverpie.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/provider/override.dart';

/// A notifier where the state can be updated by emitting events.
/// Events are emitted by calling [emit].
/// They are handled by the notifier with [reduce].
///
/// You do not have access to [ref] in this notifier, so you need to pass
/// the required dependencies via constructor.
abstract class ReduxNotifier<T, E extends Object>
    extends BaseReduxNotifier<T, E> {
  ReduxNotifier({String? debugLabel}) : super(debugLabel: debugLabel);
}

typedef Reducer<T, E extends Object> = T Function(T state, E event);

extension ReduxNotifierOverrideExt<N extends ReduxNotifier<T, E>, T,
    E extends Object> on NotifierProvider<N, T> {
  /// Overrides the reducer with the given [overrides].
  ///
  /// Usage:
  /// final ref = RiverpieContainer(
  ///   overrides: [
  ///     notifierProvider.overrideWithReducer(
  ///       overrides: {
  ///         MyEvent: (state, event) => state + 1,
  ///         MyAnotherEvent: null, // empty reducer
  ///         MyEnum.value: null, // enum event
  ///         ...
  ///       },
  ///     ),
  ///   ],
  /// );
  ProviderOverride<N, T> overrideWithReducer({
    N Function()? notifier,
    required Map<Object, Reducer<T, E>?> overrides,
  }) {
    return ProviderOverride<N, T>(
      provider: this,
      createState: (ref) {
        return (notifier?.call() ?? createState(ref))..setOverrides(overrides);
      },
    );
  }
}
