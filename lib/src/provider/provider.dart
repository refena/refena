import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// A "provider" instructs Riverpie how to create a state.
/// A "provider" is stateless.
///
/// You may add a [debugLabel] for better logging.
abstract class BaseProvider<T> {
  final String? debugLabel;

  BaseProvider({this.debugLabel});

  @internal
  BaseProviderState<T> createState(
    Ref ref,
    RiverpieObserver? observer,
  );
}

/// Instructs Riverpie to set a predefined state for a provider.
class ProviderOverride<T> {
  /// The reference to the provider.
  final BaseProvider<T> provider;

  /// The state of the provider.
  final BaseProviderState<T> state;

  ProviderOverride(this.provider, this.state);
}

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

/// Use a [NotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class NotifierProvider<N extends BaseNotifier<T>, T> extends BaseProvider<T> {
  @internal
  final N Function(Ref ref) create;

  NotifierProvider(this.create, {super.debugLabel});

  @internal
  @override
  NotifierProviderState<N, T> createState(
    Ref ref,
    RiverpieObserver? observer,
  ) {
    final state = NotifierProviderState<N, T>(create(ref));

    // ignore: invalid_use_of_protected_member
    state.getNotifier().preInit(ref, observer);

    return state;
  }

  ProviderOverride<T> overrideWithNotifier(N Function() notifier) {
    return ProviderOverride(this, NotifierProviderState(notifier()));
  }
}
