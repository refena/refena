import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/immutable_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/ref.dart';

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
  ImmutableNotifier<T> createState(Ref ref) {
    return ImmutableNotifier(
      builder(ref),
      debugLabel: customDebugLabel ?? runtimeType.toString(),
    );
  }

  /// Overrides the state of a provider with a predefined value.
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
  ProviderOverride<ImmutableNotifier<T>, T> overrideWithBuilder(
    T Function(Ref ref) builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => ImmutableNotifier(
        builder(ref),
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }

  /// Overrides the state of a provider with a predefined value.
  /// Here, you can use a future to build the state.
  ProviderOverride<ImmutableNotifier<T>, T> overrideWithFuture(
    Future<T> Function(Ref ref) builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) async => ImmutableNotifier(
        await builder(ref),
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }
}
