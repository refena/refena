import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// A provider instructs Riverpie how to create a state.
/// It is stateless.
abstract class BaseProvider<T> {
  @internal
  BaseProviderState<T> createState(Ref ref);
}

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
  final T Function() create;

  Provider(this.create);

  @internal
  @override
  ProviderState<T> createState(Ref ref) {
    return ProviderState(create());
  }

  ProviderOverride<T> overrideWithValue(T value) {
    return ProviderOverride(this, ProviderState(value));
  }
}

/// Use a [NotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class NotifierProvider<N extends Notifier<T>, T> extends BaseProvider<T> {
  @internal
  final N Function() create;

  NotifierProvider(this.create);

  @internal
  @override
  NotifierProviderState<N, T> createState(Ref ref) {
    final state = NotifierProviderState<N, T>(create());

    // ignore: invalid_use_of_protected_member
    state.getNotifier().setRefAndInit(ref);

    return state;
  }

  ProviderOverride<T> overrideWithNotifier(N notifier) {
    return ProviderOverride(this, NotifierProviderState(notifier));
  }
}
