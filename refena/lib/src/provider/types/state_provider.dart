import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/types/state_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/notifier_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

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
  final String Function(T state)? _describeState;

  StateProvider(
    this._builder, {
    super.onChanged,
    String Function(T state)? describeState,
    String? debugLabel,
  })  : _describeState = describeState,
        super(debugLabel: debugLabel ?? 'StateProvider<$T>');

  @internal
  @override
  StateNotifier<T> createState(ProxyRef ref) {
    return _build(
      ref: ref,
      builder: _builder,
      describeState: _describeState,
      debugLabel: customDebugLabel ?? runtimeType.toString(),
    );
  }

  /// Overrides the initial state.
  ///
  /// {@category Initialization}
  ProviderOverride overrideWithInitialState(T Function(Ref ref) builder) {
    return ProviderOverride<StateNotifier<T>, T>(
      provider: this,
      createState: (ref) => _build(
        ref: ref,
        builder: builder,
        describeState: _describeState,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }
}

/// Builds the notifier and also registers the dependencies.
StateNotifier<T> _build<T>({
  required ProxyRef ref,
  required T Function(Ref ref) builder,
  required String Function(T state)? describeState,
  required String debugLabel,
}) {
  final dependencies = <BaseNotifier>{};

  final initialState = ref.trackNotifier(
    onAccess: (notifier) => dependencies.add(notifier),
    run: () => builder(ref),
  );

  final notifier = StateNotifier<T>(
    initialState,
    describeState: describeState,
    debugLabel: debugLabel,
  );

  notifier.dependencies.addAll(dependencies);
  for (final dependency in dependencies) {
    dependency.dependents.add(notifier);
  }

  return notifier;
}
