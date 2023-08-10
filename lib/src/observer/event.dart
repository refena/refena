import 'package:flutter/material.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';

/// The base event.
sealed class RiverpieEvent {}

/// The most frequent event.
/// A notifier changed its state and notifies all listeners
/// that they should rebuild.
class NotifyEvent<T> extends RiverpieEvent {
  /// The notifier that fired the change event.
  final BaseNotifier<T> notifier;

  /// The previous state before the event.
  final T prev;

  /// The state after the change.
  final T next;

  /// A list of states that are flagged to rebuild in the next frame.
  final List<State> flagRebuild;

  NotifyEvent({
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

  /// The provider is accessed the first time.
  /// This can happen by any [ref] operator.
  access,
}

/// A provider is initialized (happens only once per runtime).
/// This happens either immediately during provider override or
/// lazily when the provider is accessed the first time.
class ProviderInitEvent<T> extends RiverpieEvent {
  final BaseProvider<T> provider;
  final BaseNotifier<T>? notifier;
  final ProviderInitCause cause;
  final T value;

  ProviderInitEvent({
    required this.provider,
    required this.notifier,
    required this.cause,
    required this.value,
  });
}

/// A listener is added to a notifier.
/// This happens on ref.watch the first time the call happens within a state.
class ListenerAddedEvent<N extends BaseNotifier<T>, T> extends RiverpieEvent {
  final N notifier;
  final State state;

  ListenerAddedEvent({
    required this.notifier,
    required this.state,
  });
}

/// Listener is removed from a notifier.
/// This usually happens when a notifier tries to notify or
/// periodically when new listeners are added.
class ListenerRemovedEvent<N extends BaseNotifier<T>, T> extends RiverpieEvent {
  final N notifier;
  final State state;

  ListenerRemovedEvent({
    required this.notifier,
    required this.state,
  });
}
