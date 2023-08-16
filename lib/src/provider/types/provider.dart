import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/immutable_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/ref.dart';

/// Use a [Provider] to implement a stateless provider.
/// Useful for dependency injection.
/// Often used with [overrideWithValue] during initialization of the app.
class Provider<T> extends BaseProvider<ImmutableNotifier<T>, T> {
  @internal
  final T Function(Ref ref) create;

  Provider(this.create, {super.debugLabel});

  @internal
  @override
  ImmutableNotifier<T> createState(Ref ref) {
    return ImmutableNotifier(
      create(ref),
      debugLabel: debugLabel ?? runtimeType.toString(),
    );
  }

  ProviderOverride<ImmutableNotifier<T>, T> overrideWithValue(T value) {
    return ProviderOverride(
      provider: this,
      state: ImmutableNotifier(
        value,
        debugLabel: debugLabel ?? runtimeType.toString(),
      ),
    );
  }
}
