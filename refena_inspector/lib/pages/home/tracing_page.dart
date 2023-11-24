// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/tools/tracing_input_model.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/service/tracing_service.dart';

class TracingPage extends StatelessWidget {
  const TracingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefenaTracingPage(
      title: 'Tracing',
      inputBuilder: _InspectorTracingInputBuilder(context.ref),
      loadDelay: Duration.zero,
      showTime: true,
    );
  }
}

class _InspectorTracingInputBuilder extends TracingInputBuilder {
  final Stream _stream;
  final Ref _ref;

  _InspectorTracingInputBuilder(this._ref)
      : _stream = _ref.stream(eventTracingProvider);

  @override
  Stream<void>? get refreshStream => _stream;

  @override
  bool get hasFinishedEvents {
    return _ref.read(eventTracingProvider).hasFinishedEvents;
  }

  @override
  bool hasTracingProvider(Ref ref) => ref.read(eventTracingProvider).hasTracing;

  @override
  void clearEvents(Ref ref) {
    ref.redux(eventTracingProvider).dispatch(ClearEventsAction());
  }

  @override
  List<InputEvent> build(Ref ref) {
    return _ref.read(eventTracingProvider).events;
  }
}
