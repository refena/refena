part of 'tracing_page.dart';

// ignore_for_file: invalid_use_of_internal_member

/// A configuration for the tracing page.
abstract class TracingInputBuilder {
  const TracingInputBuilder();

  /// If not null, then [build] will be called on every new stream event.
  Stream<void>? get refreshStream;

  /// If true, then a loading indicator is shown for unfinished actions.
  /// If false, then it will be considered true as soon as the first
  /// [ActionFinishedEvent] is received.
  ///
  /// This flag is only for performance reasons and is used
  /// by the inspector.
  bool get hasFinishedEvents;

  /// If false, then an error will be shown
  /// if the tracing provider is not available.
  bool hasTracingProvider(Ref ref);

  /// Clears the events.
  void clearEvents(Ref ref);

  /// Builds the input list either from the state of the app or
  /// from a state fetched from the client.
  Iterable<InputEvent> build(Ref ref);
}

/// Builds the model from the state
class _StateTracingInputBuilder extends TracingInputBuilder {
  const _StateTracingInputBuilder();

  @override
  Stream<void>? get refreshStream => null;

  @override
  bool get hasFinishedEvents => false;

  @override
  bool hasTracingProvider(Ref ref) => ref.notifier(tracingProvider).initialized;

  @override
  void clearEvents(Ref ref) => ref.notifier(tracingProvider).clear();

  @override
  Iterable<InputEvent> build(Ref ref) {
    return ref.notifier(tracingProvider).events.map((e) {
      return InputEvent.fromEvent(
        event: e,
        errorParser: null,
        shouldParseError: false,
      );
    });
  }
}
