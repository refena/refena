import 'package:meta/meta.dart';
import 'package:refena/src/observer/event.dart';

@internal
enum InputEventType {
  change,
  rebuild,
  init,
  dispose,
  actionDispatched,
  actionFinished,
  actionError,
  message,
}

/// A merged model to easily serialize and deserialize the events.
@internal
class InputEvent {
  final int id;
  final InputEventType type;
  final int millisSinceEpoch;

  /// The original event.
  /// Only available locally.
  final RefenaEvent? event;

  final String label;
  final String? debugOrigin;
  final Map<String, String> data;

  // extensions

  // should create dummy events for these
  final List<String>? rebuildWidgets;

  // should bind this event to these events
  final List<int>? parentEvents; // event ids
  final int? parentAction; // action id

  // ActionDispatchedEvent
  final int? actionId;
  final String? actionLabel;

  // ActionFinishedEvent
  final String? actionResult;

  // ActionErrorEvent
  final ActionLifecycle? actionLifecycle;
  final String? actionError;
  final Map<String, dynamic>? actionErrorData;
  final String? actionStackTrace;

  InputEvent({
    required this.id,
    required this.type,
    required this.millisSinceEpoch,
    required this.event,
    required this.label,
    required this.debugOrigin,
    required this.data,
    required this.rebuildWidgets,
    required this.parentEvents,
    required this.parentAction,
    required this.actionId,
    required this.actionLabel,
    required this.actionResult,
    required this.actionLifecycle,
    required this.actionError,
    required this.actionErrorData,
    required this.actionStackTrace,
  });

  InputEvent.only({
    required this.id,
    required this.type,
    required this.millisSinceEpoch,
    this.event,
    required this.label,
    this.debugOrigin,
    required this.data,
    this.rebuildWidgets,
    this.parentEvents,
    this.parentAction,
    this.actionId,
    this.actionLabel,
    this.actionResult,
    this.actionLifecycle,
    this.actionError,
    this.actionErrorData,
    this.actionStackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'millisSinceEpoch': millisSinceEpoch,
      'label': label,
      'debugOrigin': debugOrigin,
      'data': data,
      'ext': {
        'rebuildWidgets': rebuildWidgets,
        'parentEvents': parentEvents,
        'parentAction': parentAction,
        'actionId': actionId,
        'actionLabel': actionLabel,
        'actionResult': actionResult,
        'actionLifecycle': actionLifecycle?.index,
        'actionError': actionError,
        'actionErrorData': actionErrorData,
        'actionStackTrace': actionStackTrace,
      },
    };
  }

  factory InputEvent.fromJson(Map<String, dynamic> json) {
    final ext = json['ext'] as Map<String, dynamic>;
    return InputEvent(
      id: json['id'] as int,
      type: InputEventType.values[json['type'] as int],
      millisSinceEpoch: json['millisSinceEpoch'] as int,
      event: null,
      label: json['label'] as String,
      debugOrigin: json['debugOrigin'] as String?,
      data: Map<String, String>.from(json['data'] as Map),
      rebuildWidgets: (ext['rebuildWidgets'] as List?)?.cast<String>(),
      parentEvents: (ext['parentEvents'] as List?)?.cast<int>(),
      parentAction: ext['parentAction'] as int?,
      actionId: ext['actionId'] as int?,
      actionLabel: ext['actionLabel'] as String?,
      actionResult: ext['actionResult'] as String?,
      actionLifecycle: ext['actionLifecycle'] == null
          ? null
          : ActionLifecycle.values[ext['actionLifecycle'] as int],
      actionError: ext['actionError'] as String?,
      actionErrorData: ext['actionErrorData'] as Map<String, dynamic>?,
      actionStackTrace: ext['actionStackTrace'] as String?,
    );
  }
}
