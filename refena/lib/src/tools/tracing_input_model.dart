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

  // non-null depending on type

  // ChangeEvent and RebuildEvent
  final String? stateType;
  final String? prevState;
  final String? nextState;
  final List<String>? rebuildWidgets;

  // RebuildEvent
  final List<int>? rebuildCauses; // event ids
  final List<String>? rebuildCausesLabels; // debug labels
  final String? rebuildableLabel;

  // ProviderInitEvent
  final String? providerLabel;
  final String? notifierLabel;
  final ProviderInitCause? providerInitCause;
  final String? value;

  // ActionDispatchedEvent
  final int? originActionId;
  final int? actionId;
  final String? debugOrigin;
  final String? actionLabel;
  final String? actionToString;

  // ActionFinishedEvent
  final String? actionResult;

  // ActionErrorEvent
  final ActionLifecycle? actionLifecycle;
  final String? actionError;
  final Map<String, dynamic>? actionErrorData;
  final String? actionStackTrace;

  // MessageEvent
  final String? message;

  InputEvent({
    required this.id,
    required this.type,
    required this.millisSinceEpoch,
    required this.event,
    required this.stateType,
    required this.prevState,
    required this.nextState,
    required this.rebuildWidgets,
    required this.rebuildCauses,
    required this.rebuildCausesLabels,
    required this.rebuildableLabel,
    required this.providerLabel,
    required this.notifierLabel,
    required this.providerInitCause,
    required this.value,
    required this.originActionId,
    required this.actionId,
    required this.debugOrigin,
    required this.actionLabel,
    required this.actionToString,
    required this.actionResult,
    required this.actionLifecycle,
    required this.actionError,
    required this.actionErrorData,
    required this.actionStackTrace,
    required this.message,
  });

  InputEvent.only({
    required this.id,
    required this.type,
    required this.millisSinceEpoch,
    this.event,
    this.stateType,
    this.prevState,
    this.nextState,
    this.rebuildWidgets,
    this.rebuildCauses,
    this.rebuildCausesLabels,
    this.rebuildableLabel,
    this.providerLabel,
    this.notifierLabel,
    this.providerInitCause,
    this.value,
    this.originActionId,
    this.actionId,
    this.debugOrigin,
    this.actionLabel,
    this.actionToString,
    this.actionResult,
    this.actionLifecycle,
    this.actionError,
    this.actionErrorData,
    this.actionStackTrace,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'millisSinceEpoch': millisSinceEpoch,
      'data': {
        if (stateType != null) 'stateType': stateType,
        if (prevState != null) 'prevState': prevState,
        if (nextState != null) 'nextState': nextState,
        if (rebuildWidgets != null) 'rebuildWidgets': rebuildWidgets,
        if (rebuildCauses != null) 'rebuildCauses': rebuildCauses,
        if (rebuildCausesLabels != null)
          'rebuildCausesLabels': rebuildCausesLabels,
        if (rebuildableLabel != null) 'rebuildableLabel': rebuildableLabel,
        if (providerLabel != null) 'providerLabel': providerLabel,
        if (notifierLabel != null) 'notifierLabel': notifierLabel,
        if (providerInitCause != null)
          'providerInitCause': providerInitCause?.index,
        if (value != null) 'value': value,
        if (originActionId != null) 'originActionId': originActionId,
        if (actionId != null) 'actionId': actionId,
        if (debugOrigin != null) 'debugOrigin': debugOrigin,
        if (actionLabel != null) 'actionLabel': actionLabel,
        if (actionToString != null) 'actionToString': actionToString,
        if (actionResult != null) 'actionResult': actionResult,
        if (actionLifecycle != null) 'actionLifecycle': actionLifecycle?.index,
        if (actionError != null) 'actionError': actionError,
        if (actionErrorData != null) 'actionErrorData': actionErrorData,
        if (actionStackTrace != null) 'actionStackTrace': actionStackTrace,
        if (message != null) 'message': message,
      },
    };
  }

  factory InputEvent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return InputEvent(
      id: json['id'] as int,
      type: InputEventType.values[json['type'] as int],
      millisSinceEpoch: json['millisSinceEpoch'] as int,
      event: null,
      stateType: data['stateType'] as String?,
      prevState: data['prevState'] as String?,
      nextState: data['nextState'] as String?,
      rebuildWidgets: (data['rebuildWidgets'] as List<dynamic>).cast<String>(),
      rebuildCauses: (data['rebuildCauses'] as List<dynamic>).cast<int>(),
      rebuildCausesLabels: (data['rebuildCausesLabels'] as List).cast<String>(),
      rebuildableLabel: data['rebuildableLabel'] as String?,
      providerLabel: data['providerLabel'] as String?,
      notifierLabel: data['notifierLabel'] as String?,
      providerInitCause: data['providerInitCause'] != null
          ? ProviderInitCause.values[data['providerInitCause'] as int]
          : null,
      value: data['value'] as String?,
      originActionId: data['originActionId'] as int?,
      actionId: data['actionId'] as int?,
      debugOrigin: data['debugOrigin'] as String?,
      actionLabel: data['actionLabel'] as String?,
      actionToString: data['actionToString'] as String?,
      actionResult: data['actionResult'] as String?,
      actionLifecycle: data['actionLifecycle'] != null
          ? ActionLifecycle.values[data['actionLifecycle'] as int]
          : null,
      actionError: data['actionError'] as String?,
      actionErrorData: data['actionErrorData'] as Map<String, dynamic>?,
      actionStackTrace: data['actionStackTrace'] as String?,
      message: data['message'] as String?,
    );
  }
}
