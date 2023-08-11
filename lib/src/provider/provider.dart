import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/notifier.dart';
import 'package:riverpie/src/notifier/view_provider_notifier.dart';
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

/// A provider that holds a [BaseNotifier].
/// Only notifiers are able to add listeners.
abstract class BaseNotifierProvider<N extends BaseNotifier<T>, T>
    extends BaseProvider<T> {
  BaseNotifierProvider({super.debugLabel});

  @internal
  @override
  NotifierProviderState<N, T> createState(
    Ref ref,
    RiverpieObserver? observer,
  );
}

/// Use a [NotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class NotifierProvider<N extends BaseNotifier<T>, T>
    extends BaseNotifierProvider<N, T> {
  @internal
  final N Function(Ref ref) builder;

  NotifierProvider(this.builder, {super.debugLabel});

  @internal
  @override
  NotifierProviderState<N, T> createState(
    Ref ref,
    RiverpieObserver? observer,
  ) {
    final notifier = builder(ref);
    final state = NotifierProviderState<N, T>(notifier);

    // ignore: invalid_use_of_protected_member
    notifier.preInit(ref, observer);

    return state;
  }

  ProviderOverride<T> overrideWithNotifier(N Function() notifier) {
    return ProviderOverride(this, NotifierProviderState(notifier()));
  }
}

/// The [ViewProvider] is the only provider that can watch other providers.
/// Its builder is similar to a normal [Provider].
/// A common use case is to define a view model that depends on many providers.
/// Don't worry about the [ref], you can use it freely inside any function.
/// The [ref] will never become invalid.
class ViewProvider<T> extends BaseNotifierProvider<ViewProviderNotifier<T>, T> {
  @internal
  final T Function(WatchableRef ref) builder;

  ViewProvider(this.builder, {super.debugLabel});

  @override
  NotifierProviderState<ViewProviderNotifier<T>, T> createState(
    Ref ref,
    RiverpieObserver? observer,
  ) {
    final notifier = ViewProviderNotifier<T>(
      builder,
      debugLabel: debugLabel ?? runtimeType.toString(),
    );
    final state = NotifierProviderState<ViewProviderNotifier<T>, T>(notifier);

    notifier.preInit(ref, observer);

    return state;
  }

  ProviderOverride<T> overrideWithBuilder(T Function(WatchableRef) builder) {
    return ProviderOverride(
      this,
      NotifierProviderState(
        ViewProviderNotifier(
          builder,
          debugLabel: debugLabel ?? runtimeType.toString(),
        ),
      ),
    );
  }
}
