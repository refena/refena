part of 'tracing_page.dart';

// ignore_for_file: invalid_use_of_internal_member

/// A configuration for the tracing page.
abstract class TracingInputBuilder {
  const TracingInputBuilder();

  /// If not null, then [build] will be called on every new stream event.
  Stream? get refreshStream;

  /// If true, then the tracing page will not be shown if the tracing provider
  /// is not available.
  bool get requireTracingProvider;

  /// Builds the input list either from the state of the app or
  /// from a state fetched from the client.
  Iterable<InputEvent> build(Ref ref);
}

/// Builds the model from the state
class _StateTracingInputBuilder extends TracingInputBuilder {
  const _StateTracingInputBuilder();

  @override
  Stream? get refreshStream => null;

  @override
  bool get requireTracingProvider => true;

  @override
  Iterable<InputEvent> build(Ref ref) {
    return ref.notifier(tracingProvider).events.map((e) {
      ActionLifecycle? actionLifecycle;
      String? actionError;
      String? actionStackTrace;
      if (e is ActionErrorEvent) {
        actionLifecycle = e.lifecycle;
        actionError = e.error.toString();
        actionStackTrace = e.stackTrace.toString();
      }
      return InputEvent(
        id: e.id,
        type: switch (e) {
          ChangeEvent() => InputEventType.change,
          RebuildEvent() => InputEventType.rebuild,
          ProviderInitEvent() => InputEventType.init,
          ProviderDisposeEvent() => InputEventType.dispose,
          ActionDispatchedEvent() => InputEventType.actionDispatched,
          ActionFinishedEvent() => InputEventType.actionFinished,
          ActionErrorEvent() => InputEventType.actionError,
          MessageEvent() => InputEventType.message,
        },
        millisSinceEpoch: e.millisSinceEpoch,
        event: e,
        label: switch (e) {
          ChangeEvent() =>
            e.notifier.customDebugLabel ?? e.stateType.toString(),
          RebuildEvent() =>
            e.rebuildable.isWidget ? e.debugLabel : e.stateType.toString(),
          ActionDispatchedEvent() => e.action.debugLabel,
          ActionFinishedEvent() => '',
          ActionErrorEvent() => '',
          ProviderInitEvent() => e.provider.debugLabel,
          ProviderDisposeEvent() => e.provider.debugLabel,
          MessageEvent() => e.message,
        },
        debugOrigin: switch (e) {
          ActionDispatchedEvent() => e.debugOrigin,
          MessageEvent() => e.origin.debugLabel,
          _ => null,
        },
        data: switch (e) {
          ChangeEvent() => {
              'Notifier': e.notifier.debugLabel,
              if (e.action != null) 'Triggered by': e.action!.debugLabel,
              'Prev': e.prev.toString(),
              'Next': e.next.toString(),
              'Rebuild': e.rebuild.isEmpty
                  ? '<none>'
                  : e.rebuild.map((r) => r.debugLabel).join(', '),
            },
          RebuildEvent() => e.rebuildable.isWidget
              ? {}
              : {
                  'Notifier': e.rebuildable.debugLabel,
                  'Triggered by':
                      e.causes.map((e) => e.stateType.toString()).join(', '),
                  'Prev': e.prev.toString(),
                  'Next': e.next.toString(),
                  'Rebuild': e.rebuild.isEmpty
                      ? '<none>'
                      : e.rebuild.map((r) => r.debugLabel).join(', '),
                },
          ActionDispatchedEvent() => {
              'Origin': e.debugOrigin,
              'Action Group': e.notifier.debugLabel,
              'Action': e.action.toString(),
            },
          ActionFinishedEvent() => {},
          ActionErrorEvent() => {},
          ProviderInitEvent() => {
              'Provider': e.provider.toString(),
              'Initial': e.value.toString(),
              'Reason': e.cause.name.toUpperCase(),
            },
          ProviderDisposeEvent() => {
              'Provider': e.provider.toString(),
            },
          MessageEvent() => {
              'Origin': e.origin.debugLabel,
              'Message': e.message,
            },
        },
        rebuildWidgets: switch (e) {
          AbstractChangeEvent() => e.rebuild
              .where((r) => r.isWidget)
              .map((e) => e.debugLabel)
              .toList(),
          _ => null,
        },
        parentEvents: switch (e) {
          RebuildEvent() => e.causes.map((e) => e.id).toList(),
          _ => null,
        },
        parentAction: switch (e) {
          ActionDispatchedEvent() => switch (e.debugOriginRef) {
              ReduxAction a => a.id,
              _ => null,
            },
          MessageEvent() => switch (e.origin) {
              ReduxAction a => a.id,
              _ => null,
            },
          _ => null,
        },
        actionId: switch (e) {
          ChangeEvent() => e.action?.id,
          ActionDispatchedEvent() => e.action.id,
          ActionFinishedEvent() => e.action.id,
          ActionErrorEvent() => e.action.id,
          _ => null,
        },
        actionLabel: switch (e) {
          ChangeEvent() => e.action?.debugLabel,
          ActionDispatchedEvent() => e.action.debugLabel,
          _ => null,
        },
        actionResult: switch (e) {
          ActionFinishedEvent() => e.result?.toString(),
          _ => null,
        },
        actionLifecycle: actionLifecycle,
        actionError: actionError,

        // the inspector page uses the original error instead of the parsed data
        actionErrorData: null,

        actionStackTrace: actionStackTrace,
      );
    });
  }
}
