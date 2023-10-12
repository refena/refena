import 'package:collection/collection.dart';
import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/container.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/rebuildable.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/reference.dart';
import 'package:refena/src/util/time_provider.dart';

const _eq = IterableEquality();
final _timeProvider = TimeProvider();

/// The base event.
sealed class RefenaEvent with IdReference implements LabeledReference {
  /// The timestamp when the event was fired.
  /// We use [int] to save memory.
  final int millisSinceEpoch = _timeProvider.getMillisSinceEpoch();

  @override
  String get debugLabel => runtimeType.toString();
}

/// A flag that is applied for [ChangeEvent] and [RebuildEvent].
sealed class AbstractChangeEvent<T> extends RefenaEvent {
  /// The previous state before the event.
  final T prev;

  /// The state after the change.
  final T next;

  /// A list of rebuildable objects that should be rebuilt in the next tick.
  /// This is the case if one view provider is dependent on another one.
  final List<Rebuildable> rebuild;

  AbstractChangeEvent({
    required this.prev,
    required this.next,
    required this.rebuild,
  });

  /// The generic type of the state.
  Type get stateType => T;
}

/// The most frequent event.
/// A notifier changed its state and notifies all listeners
/// that they should rebuild.
class ChangeEvent<T> extends AbstractChangeEvent<T> {
  /// The notifier that fired the change event.
  final BaseNotifier<T> notifier;

  /// The dispatched [action] if the change was triggered by an [ReduxNotifier].
  final BaseReduxAction? action;

  ChangeEvent({
    required this.notifier,
    required this.action,
    required super.prev,
    required super.next,
    required super.rebuild,
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
    return 'ChangeEvent<$T>(notifier: $notifier, action: $action, prev: $prev, next: $next, rebuild: $rebuild)';
  }
}

/// A [ViewProvider] has been rebuilt. (**NOT** widget rebuild)
/// This is very similar to a [ChangeEvent] but instead of one action,
/// there can be multiple pairs of actions and notifiers.
class RebuildEvent<T> extends AbstractChangeEvent<T> {
  /// The view notifier that has been rebuilt.
  final ViewProviderNotifier rebuildable;

  /// The causes leading to the rebuild.
  /// They are batched together to avoid unnecessary rebuilds in the same frame.
  final List<AbstractChangeEvent> causes;

  RebuildEvent({
    required this.rebuildable,
    required this.causes,
    required super.prev,
    required super.next,
    required super.rebuild,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RebuildEvent &&
            runtimeType == other.runtimeType &&
            rebuildable == other.rebuildable &&
            _eq.equals(causes, other.causes) &&
            prev == other.prev &&
            next == other.next &&
            _eq.equals(rebuild, other.rebuild);
  }

  @override
  int get hashCode =>
      rebuildable.hashCode ^
      causes.hashCode ^
      prev.hashCode ^
      next.hashCode ^
      rebuild.hashCode;

  @override
  String toString() {
    return 'RebuildEvent<$T>(notifier: $rebuildable, causes: $causes, prev: $prev, next: $next, rebuild: $rebuild)';
  }
}

enum ProviderInitCause {
  /// The provider has been overridden.
  /// It will be initialized during the construction of [RefenaContainer].
  override,

  /// The provider is configured to initialize right away.
  /// It will be initialized during the construction of [RefenaContainer].
  initial,

  /// The provider is accessed the first time.
  /// This can happen by any [ref] operator.
  access,
}

/// A provider is initialized (happens only once per runtime).
/// This happens either immediately during provider override or
/// lazily when the provider is accessed the first time.
class ProviderInitEvent extends RefenaEvent {
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

/// A provider has been disposed.
/// This does not happen automatically but only when
/// ref.dispose(provider) is called.
class ProviderDisposeEvent extends RefenaEvent {
  /// The reference to the origin.
  /// This may be the notifier, the action, the rebuildable, or another
  /// [ProviderDisposeEvent].
  final LabeledReference debugOrigin;

  /// The provider that has been disposed.
  final BaseProvider provider;

  ProviderDisposeEvent({
    required this.debugOrigin,
    required this.provider,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProviderDisposeEvent &&
          debugOrigin == other.debugOrigin &&
          provider == other.provider;

  @override
  int get hashCode => debugOrigin.hashCode ^ provider.hashCode;

  @override
  String toString() {
    return 'ProviderDisposeEvent(provider: $provider)';
  }
}

/// An action has been dispatched.
/// Usually, a [ChangeEvent] directly follows this event.
/// If the action is asynchronous, the [ChangeEvent] can be delayed.
class ActionDispatchedEvent extends RefenaEvent {
  /// Where the action has been dispatched.
  /// Usually, the class name of the widget, provider, notifier, or action.
  final String debugOrigin;

  /// The actual reference to the origin.
  /// This may be the notifier, the action, or the rebuildable.
  final LabeledReference debugOriginRef;

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

/// An action has been finished successfully.
class ActionFinishedEvent extends RefenaEvent {
  /// The action that has been dispatched.
  final BaseReduxAction action;

  /// The result of the action. (NOT the state)
  final Object? result;

  ActionFinishedEvent({
    required this.action,
    required this.result,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionFinishedEvent &&
          action == other.action &&
          result == other.result;

  @override
  int get hashCode => action.hashCode ^ result.hashCode;

  @override
  String toString() {
    return 'ActionFinishedEvent(action: $action, result: $result)';
  }
}

/// The location of an error.
enum ActionLifecycle {
  /// The error happened in the [before] method of the action.
  before,

  /// The error happened in the [reduce] method of the action.
  reduce,

  /// The error happened in the [after] method of the action.
  after,
}

/// An action threw an error.
class ActionErrorEvent extends RefenaEvent {
  /// The action that has thrown the error.
  final BaseReduxAction action;

  /// The location of the error.
  final ActionLifecycle lifecycle;

  /// The error that has been thrown.
  final Object error;

  /// The stack trace of the error.
  final StackTrace stackTrace;

  ActionErrorEvent({
    required this.action,
    required this.lifecycle,
    required this.error,
    required this.stackTrace,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionErrorEvent &&
          action == other.action &&
          lifecycle == other.lifecycle &&
          error == other.error;

  @override
  int get hashCode => action.hashCode ^ lifecycle.hashCode ^ error.hashCode;

  @override
  String toString() {
    return 'ActionErrorEvent(action: $action, lifecycle: $lifecycle, error: $error)';
  }
}

/// A custom message.
/// This is useful for debugging.
class MessageEvent extends RefenaEvent {
  /// The message.
  final String message;

  /// The origin of the message.
  /// This may be the global scope, the action, or the rebuildable.
  final LabeledReference origin;

  MessageEvent(this.message, this.origin);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageEvent &&
          message == other.message &&
          origin == other.origin;

  @override
  int get hashCode => message.hashCode ^ origin.hashCode;

  @override
  String toString() {
    return 'MessageEvent(message: $message, origin: ${origin.debugLabel})';
  }

  @override
  String get debugLabel => message;
}
