import 'dart:async';

import 'package:riverpie/src/notifier/base_notifier.dart';

/// A proxy class to provide a custom [debugOrigin] for [emit].
///
/// Usage:
/// ref.redux(myReduxProvider).emit(AddEvent(2));
class Emittable<N extends BaseReduxNotifier, E extends Object> {
  Emittable({
    required this.notifier,
    required this.debugOrigin,
  });

  /// The notifier to emit events to.
  final N notifier;

  /// The origin of the emitted event.
  /// Used for debugging purposes.
  /// Usually, the class name of the widget, provider or notifier.
  final String debugOrigin;

  /// Emits an event to the [notifier].
  ///
  /// ref.redux(myReduxProvider).emit(AddEvent(2));
  /// ...
  /// Emittable<ServiceB, EventType> serviceB = ref.redux(providerB);
  /// ...
  /// serviceB.emit(AddEvent(11));
  FutureOr<void> emit(E event, {String? debugOrigin}) {
    return notifier.emit(event, debugOrigin: debugOrigin ?? this.debugOrigin);
  }
}
