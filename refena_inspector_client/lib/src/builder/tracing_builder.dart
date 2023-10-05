// ignore_for_file: invalid_use_of_internal_member

import 'package:meta/meta.dart';
import 'package:refena/refena.dart';

// ignore: implementation_imports
import 'package:refena/src/tools/tracing_input_model.dart';

@internal
class TracingBuilder {
  static List<InputEvent> buildFullDto({
    required Ref ref,
    required ErrorParser? errorParser,
  }) {
    return ref.notifier(tracingProvider).events.map((e) {
      return InputEvent.fromEvent(
        event: e,
        errorParser: errorParser,
        shouldParseError: true,
      );
    }).toList();
  }

  static List<InputEvent> buildEventsDto({
    required List<RefenaEvent> events,
    required ErrorParser? errorParser,
  }) {
    return events.map((e) {
      return InputEvent.fromEvent(
        event: e,
        errorParser: errorParser,
        shouldParseError: true,
      );
    }).toList();
  }
}
