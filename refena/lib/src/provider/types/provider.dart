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
class Provider<T> extends BaseWatchableProvider<ImmutableNotifier<T>, T>
    with ProviderSelectMixin<ImmutableNotifier<T>, T> {
  @internal
  final T Function(Ref ref) builder;

  Provider(this.builder, {String? debugLabel})
      : super(debugLabel: debugLabel ?? 'Provider<$T>');

  @internal
  @override
  ImmutableNotifier<T> createState(ProxyRef ref) {
    return _build(ref, builder);
  }

  /// Overrides the state of a provider with a predefined value.
  ///
  /// {@category Initialization}
  ProviderOverride<ImmutableNotifier<T>, T> overrideWithValue(
    T value,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => ImmutableNotifier(
        value,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
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
      debugLabel: customDebugLabel ?? runtimeType.toString(),
    );

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
      debugLabel: customDebugLabel ?? runtimeType.toString(),
    );

    notifier.dependencies.addAll(dependencies);
    for (final dependency in dependencies) {
      dependency.dependents.add(notifier);
    }

    return notifier;
  }
}
