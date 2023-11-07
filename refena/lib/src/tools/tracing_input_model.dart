import 'package:meta/meta.dart';
import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/observer/error_parser.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/util/object_formatter.dart';

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

  factory InputEvent.fromEvent({
    required RefenaEvent event,
    required ErrorParser? errorParser,
    required bool shouldParseError,
  }) {
    ActionLifecycle? actionLifecycle;
    String? actionError;
    String? actionStackTrace;
    if (event is ActionErrorEvent) {
      actionLifecycle = event.lifecycle;
      actionError = event.error.toString();
      actionStackTrace = event.stackTrace.toString();
    }
    return InputEvent(
      id: event.id,
      type: switch (event) {
        ChangeEvent() => InputEventType.change,
        RebuildEvent() => InputEventType.rebuild,
        ProviderInitEvent() => InputEventType.init,
        ProviderDisposeEvent() => InputEventType.dispose,
        ActionDispatchedEvent() => InputEventType.actionDispatched,
        ActionFinishedEvent() => InputEventType.actionFinished,
        ActionErrorEvent() => InputEventType.actionError,
        MessageEvent() => InputEventType.message,
      },
      millisSinceEpoch: event.millisSinceEpoch,
      event: event,
      label: switch (event) {
        ChangeEvent() => event.notifier.customDebugLabel ??
            switch (event.stateType.toString()) {
              'bool' ||
              'bool?' ||
              'int' ||
              'int?' ||
              'double' ||
              'double?' ||
              'String' ||
              'String?' =>
                event.notifier.debugLabel, // avoid primitive types
              _ => event.stateType.toString(), // use the type
            },
        RebuildEvent() => event.rebuildable.isWidget
            ? event.debugLabel
            : (event.rebuildable as BaseNotifier).customDebugLabel ??
                event.stateType.toString(),
        ActionDispatchedEvent() => event.action.debugLabel,
        ActionFinishedEvent() => '',
        ActionErrorEvent() => '',
        ProviderInitEvent() => event.provider.debugLabel,
        ProviderDisposeEvent() => event.provider.debugLabel,
        MessageEvent() => event.message,
      },
      debugOrigin: switch (event) {
        ProviderDisposeEvent() => event.debugOrigin.debugLabel,
        ActionDispatchedEvent() => event.debugOrigin,
        MessageEvent() => event.origin.debugLabel,
        _ => null,
      },
      data: switch (event) {
        ChangeEvent() => {
            'Notifier': event.notifier.debugLabel,
            if (event.action != null) 'Triggered by': event.action!.debugLabel,
            'Prev': formatValue(event.notifier.describeState(event.prev)),
            'Next': formatValue(event.notifier.describeState(event.next)),
            'Rebuild': event.rebuild.isEmpty
                ? '<none>'
                : event.rebuild.map((r) => r.debugLabel).join(', '),
          },
        RebuildEvent() => event.rebuildable.isWidget
            ? {}
            : {
                'Notifier': event.rebuildable.debugLabel,
                'Triggered by':
                    event.causes.map((e) => e.stateType.toString()).join(', '),
                'Prev': formatValue((event.rebuildable as BaseNotifier)
                    .describeState(event.prev)),
                'Next': formatValue((event.rebuildable as BaseNotifier)
                    .describeState(event.next)),
                'Rebuild': event.rebuild.isEmpty
                    ? '<none>'
                    : event.rebuild.map((r) => r.debugLabel).join(', '),
              },
        ActionDispatchedEvent() => {
            'Origin': event.debugOrigin,
            'Action Group': event.notifier.debugLabel,
            'Action': event.action.toString(),
          },
        ActionFinishedEvent() => {},
        ActionErrorEvent() => {},
        ProviderInitEvent() => {
            'Provider': event.provider.toString(),
            'Initial': formatValue(event.notifier.describeState(event.value)),
            'Reason': event.cause.name.toUpperCase(),
          },
        ProviderDisposeEvent() => {
            'Origin': switch (event.debugOrigin) {
              ProviderDisposeEvent e => e.provider.debugLabel,
              _ => event.debugOrigin.debugLabel,
            },
            'Provider': event.provider.toString(),
          },
        MessageEvent() => {
            'Origin': event.origin.debugLabel,
            'Message': event.message,
          },
      },
      rebuildWidgets: switch (event) {
        AbstractChangeEvent() => event.rebuild
            .where((r) => r.isWidget)
            .map((e) => e.debugLabel)
            .toList(),
        _ => null,
      },
      parentEvents: switch (event) {
        RebuildEvent() => event.causes.map((e) => e.id).toList(),
        ProviderDisposeEvent() => switch (event.debugOrigin) {
            ProviderDisposeEvent e => [e.id],
            _ => null,
          },
        _ => null,
      },
      parentAction: switch (event) {
        ActionDispatchedEvent() => switch (event.debugOriginRef) {
            BaseReduxAction a => a.id,
            _ => null,
          },
        MessageEvent() => switch (event.origin) {
            BaseReduxAction a => a.id,
            _ => null,
          },
        _ => null,
      },
      actionId: switch (event) {
        ChangeEvent() => event.action?.id,
        ActionDispatchedEvent() => event.action.id,
        ActionFinishedEvent() => event.action.id,
        ActionErrorEvent() => event.action.id,
        _ => null,
      },
      actionLabel: switch (event) {
        ChangeEvent() => event.action?.debugLabel,
        ActionDispatchedEvent() => event.action.debugLabel,
        _ => null,
      },
      actionResult: switch (event) {
        ActionFinishedEvent() =>
          event.result != null ? formatValue(event.result) : null,
        _ => null,
      },
      actionLifecycle: actionLifecycle,
      actionError: actionError,
      actionErrorData: switch (event) {
        ActionErrorEvent() when shouldParseError =>
          parseError(event.error, errorParser),
        _ => null,
      },
      actionStackTrace: actionStackTrace,
    );
  }
}
