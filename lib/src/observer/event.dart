import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/provider/base_provider.dart';

/// The base event.
sealed class RiverpieEvent {}

/// The most frequent event.
/// A notifier changed its state and notifies all listeners
/// that they should rebuild.
class ChangeEvent<T> extends RiverpieEvent {
  /// The notifier that fired the change event.
  final BaseNotifier<T> notifier;

  /// The previous state before the event.
  final T prev;

  /// The state after the change.
  final T next;

  /// A list of rebuildable objects that should be rebuilt.
  final List<Rebuildable> flagRebuild;

  ChangeEvent({
    required this.notifier,
    required this.prev,
    required this.next,
    required this.flagRebuild,
  });
}

enum ProviderInitCause {
  /// The provider has been overridden.
  /// It will be initialized during the initialization of [RiverpieScope].
  override,

  /// The provider is specified to initialize right away.
  /// It will be initialized during the initialization of [RiverpieScope].
  initial,

  /// The provider is accessed the first time.
  /// This can happen by any [ref] operator.
  access,
}

/// A provider is initialized (happens only once per runtime).
/// This happens either immediately during provider override or
/// lazily when the provider is accessed the first time.
class ProviderInitEvent extends RiverpieEvent {
  /// The provider that has been initialized.
  final BaseProvider provider;

  /// The notifier that is associated with the provider.
  final BaseNotifier notifier;

  /// The cause of the initialization.
  final ProviderInitCause cause;

  /// The initial value of the provider.
  final Object? value;

  ProviderInitEvent({
    required this.provider,
    required this.notifier,
    required this.cause,
    required this.value,
  });
}

/// A listener is added to a notifier.
/// This happens on ref.watch the first time the call happens within a state.
class ListenerAddedEvent<N extends BaseNotifier> extends RiverpieEvent {
  final N notifier;
  final Rebuildable rebuildable;

  ListenerAddedEvent({
    required this.notifier,
    required this.rebuildable,
  });
}

/// Listener is removed from a notifier.
/// This usually happens when a notifier tries to notify or
/// periodically when new listeners are added.
class ListenerRemovedEvent<N extends BaseNotifier> extends RiverpieEvent {
  final N notifier;
  final Rebuildable rebuildable;

  ListenerRemovedEvent({
    required this.notifier,
    required this.rebuildable,
  });
}
