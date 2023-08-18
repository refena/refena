import 'dart:async';

import 'package:riverpie/src/notifier/base_notifier.dart';

/// A proxy class to provide a custom [debugOwnerLabel] for [emit].
///
/// Usage:
/// ref.redux(myReduxProvider).emit(AddEvent(2));
class Emittable<N extends BaseReduxNotifier, E extends Object> {
  Emittable({
    required this.notifier,
    required this.debugOwnerLabel,
  });

  final N notifier;
  final String debugOwnerLabel;

  /// Emits an event to the [notifier].
  ///
  /// ref.redux(myReduxProvider).emit(AddEvent(2));
  /// ...
  /// Emittable<ServiceB, EventType> serviceB = ref.redux(providerB);
  /// ...
  /// serviceB.emit(AddEvent(11));
  FutureOr<void> emit(E event, {String? debugLabel}) {
    return notifier.emit(event, debugLabel: debugLabel ?? debugOwnerLabel);
  }
}
