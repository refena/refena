import 'package:riverpie/src/notifier/types/state_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/notifier_provider.dart';
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
class StateProvider<T> extends NotifierProvider<StateNotifier<T>, T>
    with ProviderSelectMixin<StateNotifier<T>, T>
    implements NotifyableProvider<StateNotifier<T>, T> {
  StateProvider(T Function(Ref ref) builder, {String? debugLabel})
      : super(
          (ref) => StateNotifier<T>(
            builder(ref),
            debugLabel: debugLabel ?? 'StateProvider<$T>',
          ),
          debugLabel: debugLabel ?? 'StateProvider<$T>',
        );

  ProviderOverride overrideWithInitialState(T Function(Ref ref) builder) {
    return ProviderOverride<StateNotifier<T>, T>(
      provider: this,
      createState: (ref) => StateNotifier<T>(
        builder(ref),
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }
}
