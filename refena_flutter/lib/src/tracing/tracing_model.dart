// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

class _TracingEntry {
  final DateTime timestamp;
  final InputEvent event;
  final List<_TracingEntry> children;
  final bool superseded;
  final bool isWidget;

  // set afterwards
  _ErrorEntry? error;

  // the result of the action
  // set afterwards
  Object? result;

  // the execution time of the action
  // set afterwards
  int? millis;

  _TracingEntry(
    this.event,
    this.children, {
    this.superseded = false,
    this.isWidget = false,
  }) : timestamp = DateTime.fromMillisecondsSinceEpoch(event.millisSinceEpoch);
}

class _ErrorEntry {
  final String actionLabel;
  final ActionLifecycle actionLifecycle;
  final ActionErrorEvent? originalError;
  final String error;
  final String stackTrace;
  final ErrorParser? errorParser;

  Map<String, dynamic>? _parsedErrorData;

  /// Whether the original error has been parsed.
  /// We need this flag because the result is nullable.
  bool _parsed = false;

  _ErrorEntry({
    required this.actionLabel,
    required this.actionLifecycle,
    required this.originalError,
    required this.error,
    required this.stackTrace,
    required Map<String, dynamic>? parsedErrorData,
    required this.errorParser,
  }) : _parsedErrorData = parsedErrorData;

  /// Returns the parsed error data if available.
  /// Otherwise, it parses the original error if available.
  Map<String, dynamic>? get parsedErrorData {
    print('original: $originalError');
    if (_parsedErrorData != null) {
      return _parsedErrorData;
    }
    if (!_parsed && originalError != null) {
      // Need to switch the flag here to avoid future parsing.
      _parsed = true;
      _parsedErrorData = parseError(originalError!.error, errorParser);
      return _parsedErrorData;
    }
    return null;
  }
}

enum _EventType {
  change,
  rebuild,
  action,
  providerInit,
  providerDispose,
  message,
}

extension on InputEventType {
  _EventType get internalType {
    // ActionFinishedEvent and ActionErrorEvent are merged into ActionDispatchedEvent
    return switch (this) {
      InputEventType.change => _EventType.change,
      InputEventType.rebuild => _EventType.rebuild,
      InputEventType.actionDispatched => _EventType.action,
      InputEventType.actionFinished => throw UnimplementedError(),
      InputEventType.actionError => throw UnimplementedError(),
      InputEventType.init => _EventType.providerInit,
      InputEventType.dispose => _EventType.providerDispose,
      InputEventType.message => _EventType.message,
    };
  }
}
