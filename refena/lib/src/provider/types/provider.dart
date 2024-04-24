import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/types/immutable_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// Use a [Provider] to implement a stateless provider.
/// Useful for dependency injection.
/// Often used with [overrideWithValue] during initialization of the app.
///
/// Set [describeState] to customize the description of the state.
/// See [BaseNotifier.describeState].
///
/// Set [debugLabel] to customize the debug label of the provider.
class Provider<T>
    extends BaseWatchableProvider<Provider<T>, ImmutableNotifier<T>, T>
    with ProviderSelectMixin<Provider<T>, ImmutableNotifier<T>, T> {
  final T Function(Ref ref) _builder;
  final String Function(T state)? _describeState;

  Provider(
    this._builder, {
    String Function(T state)? describeState,
    String? debugLabel,
    super.debugVisibleInGraph = true,
  })  : _describeState = describeState,
        super(
          onChanged: null, // Providers are immutable
          debugLabel: debugLabel ?? 'Provider<$T>',
        );

  @internal
  @override
  ImmutableNotifier<T> createState(ProxyRef ref) {
    return _build(ref, _builder);
  }

  /// Overrides the state of a provider with a predefined value.
  ///
  /// {@category Initialization}
  ProviderOverride<ImmutableNotifier<T>, T> overrideWithValue(
    T value,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => _build(
        ref,
        (_) => value,
      ),
    );
  }

  /// Overrides the state of a provider with a predefined value.
  ///
  /// {@category Initialization}
  ProviderOverride<ImmutableNotifier<T>, T> overrideWithBuilder(
    T Function(Ref ref) builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => _build(ref, builder),
    );
  }

  /// Overrides the state of a provider with a predefined value.
  /// Here, you can use a future to build the state.
  ///
  /// {@category Initialization}
  ProviderOverride<ImmutableNotifier<T>, T> overrideWithFuture(
    Future<T> Function(Ref ref) builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => _buildAsync(ref, builder),
    );
  }

  ImmutableNotifier<T> _build(
    ProxyRef ref,
    T Function(Ref ref) builder,
  ) {
    final dependencies = <BaseNotifier>{};

    final initialState = ref.trackNotifier(
      onAccess: (notifier) => dependencies.add(notifier),
      run: () => builder(ref),
    );

    final notifier = ImmutableNotifier<T>(
      initialState,
      describeState: _describeState,
    );
    notifier.setCustomDebugLabel(customDebugLabel ?? runtimeType.toString());

    notifier.dependencies.addAll(dependencies);
    for (final dependency in dependencies) {
      dependency.dependents.add(notifier);
    }

    return notifier;
  }

  Future<ImmutableNotifier<T>> _buildAsync(
    ProxyRef ref,
    Future<T> Function(Ref ref) builder,
  ) async {
    final dependencies = <BaseNotifier>{};

    final initialState = await ref.trackNotifierAsync(
      onAccess: (notifier) => dependencies.add(notifier),
      run: () => builder(ref),
    );

    final notifier = ImmutableNotifier<T>(
      initialState,
      describeState: _describeState,
    );
    notifier.setCustomDebugLabel(customDebugLabel ?? runtimeType.toString());

    notifier.dependencies.addAll(dependencies);
    for (final dependency in dependencies) {
      dependency.dependents.add(notifier);
    }

    return notifier;
  }
}
