import 'package:meta/meta.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// Use a [Provider] to implement a stateless provider.
/// Useful for dependency injection.
/// Often used with [overrideWithValue] during initialization of the app.
class Provider<T> extends BaseProvider<T> {
  @internal
  final T Function(Ref ref) create;

  Provider(this.create, {super.debugLabel});

  @internal
  @override
  ProviderState<T> createState(Ref ref, RiverpieObserver? observer) {
    return ProviderState(create(ref));
  }

  ProviderOverride<T> overrideWithValue(T value) {
    return ProviderOverride(this, ProviderState(value));
  }
}
