import 'package:collection/collection.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/notifier/redux_action.dart';
import 'package:riverpie/src/provider/base_provider.dart';

const _eq = IterableEquality();

/// The base event.
sealed class RiverpieEvent {}

/// The most frequent event.
/// A notifier changed its state and notifies all listeners
/// that they should rebuild.
final class ChangeEvent<T> extends RiverpieEvent {
  /// The notifier that fired the change event.
  final BaseNotifier<T> notifier;

  /// The dispatched [action] if the change was triggered by an [ReduxNotifier].
  final BaseReduxAction? action;

  /// The previous state before the event.
  final T prev;

  /// The state after the change.
  final T next;

  /// A list of rebuildable objects that should be rebuilt in the next tick.
  final List<Rebuildable> rebuild;

  ChangeEvent({
    required this.notifier,
    required this.action,
    required this.prev,
    required this.next,
    required this.rebuild,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ChangeEvent &&
            runtimeType == other.runtimeType &&
            notifier == other.notifier &&
            action == other.action &&
            prev == other.prev &&
            next == other.next &&
            _eq.equals(rebuild, other.rebuild);
  }

  @override
  int get hashCode =>
      notifier.hashCode ^
      action.hashCode ^
      prev.hashCode ^
      next.hashCode ^
      rebuild.hashCode;

  @override
  String toString() {
    return 'ChangeEvent(notifier: $notifier, action: $action, prev: $prev, next: $next, rebuild: $rebuild)';
  }
}

enum ProviderInitCause {
  /// The provider has been overridden.
  /// It will be initialized during the construction of [RiverpieScope].
  override,

  /// The provider is configured to initialize right away.
  /// It will be initialized during the construction of [RiverpieScope].
  initial,

  /// The provider is accessed the first time.
  /// This can happen by any [ref] operator.
  access,
}

/// A provider is initialized (happens only once per runtime).
/// This happens either immediately during provider override or
/// lazily when the provider is accessed the first time.
final class ProviderInitEvent extends RiverpieEvent {
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderInitEvent &&
          runtimeType == other.runtimeType &&
          provider == other.provider &&
          notifier == other.notifier &&
          cause == other.cause &&
          value == other.value;

  @override
  int get hashCode =>
      provider.hashCode ^ notifier.hashCode ^ cause.hashCode ^ value.hashCode;

  @override
  String toString() {
    return 'ProviderInitEvent(provider: $provider, notifier: $notifier, cause: $cause, value: $value)';
  }
}

/// A listener is added to a notifier.
/// This happens on ref.watch the first time the call happens within a state.
final class ListenerAddedEvent extends RiverpieEvent {
  final BaseNotifier notifier;
  final Rebuildable rebuildable;

  ListenerAddedEvent({
    required this.notifier,
    required this.rebuildable,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListenerAddedEvent &&
          runtimeType == other.runtimeType &&
          notifier == other.notifier &&
          rebuildable == other.rebuildable;

  @override
  int get hashCode => notifier.hashCode ^ rebuildable.hashCode;

  @override
  String toString() {
    return 'ListenerAddedEvent(notifier: $notifier, rebuildable: $rebuildable)';
  }
}

/// Listener is removed from a notifier.
/// This usually happens when a notifier tries to notify or
/// periodically when new listeners are added.
final class ListenerRemovedEvent extends RiverpieEvent {
  final BaseNotifier notifier;
  final Rebuildable rebuildable;

  ListenerRemovedEvent({
    required this.notifier,
    required this.rebuildable,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListenerRemovedEvent &&
          runtimeType == other.runtimeType &&
          notifier == other.notifier &&
          rebuildable == other.rebuildable;

  @override
  int get hashCode => notifier.hashCode ^ rebuildable.hashCode;

  @override
  String toString() {
    return 'ListenerRemovedEvent(notifier: $notifier, rebuildable: $rebuildable)';
  }
}

/// An action has been dispatched.
/// Usually, a [ChangeEvent] directly follows this event.
/// If the action is asynchronous, the [ChangeEvent] can be delayed.
class ActionDispatchedEvent extends RiverpieEvent {
  /// Where the action has been dispatched.
  /// Usually, the class name of the widget, provider, notifier, or action.
  final String debugOrigin;

  /// The actual reference to the origin.
  /// This may be null.
  final Object? debugOriginRef;

  /// The corresponding notifier.
  final BaseNotifier notifier;

  /// The action that has been dispatched.
  final BaseReduxAction action;

  ActionDispatchedEvent({
    required this.debugOrigin,
    required this.debugOriginRef,
    required this.notifier,
    required this.action,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionDispatchedEvent &&
          runtimeType == other.runtimeType &&
          debugOrigin == other.debugOrigin &&
          debugOriginRef == other.debugOriginRef &&
          notifier == other.notifier &&
          action == other.action;

  @override
  int get hashCode =>
      debugOrigin.hashCode ^
      debugOriginRef.hashCode ^
      notifier.hashCode ^
      action.hashCode;

  @override
  String toString() {
    return 'ActionDispatchedEvent(debugOrigin: $debugOrigin, debugOriginRef: $debugOriginRef, notifier: $notifier, action: $action)';
  }
}
