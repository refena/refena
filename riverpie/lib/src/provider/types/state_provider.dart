import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/types/state_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/types/notifier_provider.dart';
import 'package:riverpie/src/proxy_ref.dart';
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
class StateProvider<T> extends BaseWatchableProvider<StateNotifier<T>, T>
    with ProviderSelectMixin<StateNotifier<T>, T>
    implements NotifyableProvider<StateNotifier<T>, T> {
  final T Function(Ref ref) _builder;

  StateProvider(this._builder, {String? debugLabel})
      : super(debugLabel: debugLabel ?? 'StateProvider<$T>');

  @internal
  @override
  StateNotifier<T> createState(ProxyRef ref) {
    return _build(
      ref: ref,
      builder: _builder,
      debugLabel: customDebugLabel ?? runtimeType.toString(),
    );
  }

  ProviderOverride overrideWithInitialState(T Function(Ref ref) builder) {
    return ProviderOverride<StateNotifier<T>, T>(
      provider: this,
      createState: (ref) => _build(
        ref: ref,
        builder: builder,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }
}

/// Builds the notifier and also registers the dependencies.
StateNotifier<T> _build<T>({
  required ProxyRef ref,
  required T Function(Ref ref) builder,
  required String debugLabel,
}) {
  final dependencies = <BaseNotifier>{};

  final initialState = ref.trackNotifier(
    onAccess: (notifier) => dependencies.add(notifier),
    run: () => builder(ref),
  );

  final notifier = StateNotifier<T>(
    initialState,
    debugLabel: debugLabel,
  );

  notifier.dependencies.addAll(dependencies);
  for (final dependency in dependencies) {
    dependency.dependents.add(notifier);
  }

  return notifier;
}
