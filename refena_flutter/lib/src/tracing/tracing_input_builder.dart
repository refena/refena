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
      List<int>? rebuildCauses;
      List<String>? rebuildCausesLabels;
      String? rebuildableLabel;
      if (e is RebuildEvent) {
        rebuildCauses = e.causes.map((e) => e.id).toList();
        rebuildCausesLabels =
            e.causes.map((e) => e.stateType.toString()).toList();
        rebuildableLabel = e.rebuildable.debugLabel;
      }

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
        stateType: switch (e) {
          AbstractChangeEvent() => e.stateType.toString(),
          _ => null,
        },
        prevState: switch (e) {
          AbstractChangeEvent() => e.prev.toString(),
          _ => null,
        },
        nextState: switch (e) {
          AbstractChangeEvent() => e.next.toString(),
          _ => null,
        },
        rebuildWidgets: switch (e) {
          AbstractChangeEvent() => e.rebuild
              .where((r) => r.isWidget)
              .map((e) => e.debugLabel)
              .toList(),
          _ => null,
        },
        rebuildCauses: rebuildCauses,
        rebuildCausesLabels: rebuildCausesLabels,
        rebuildableLabel: rebuildableLabel,
        providerLabel: switch (e) {
          ProviderInitEvent() => e.provider.debugLabel,
          ProviderDisposeEvent() => e.provider.debugLabel,
          _ => null,
        },
        notifierLabel: switch (e) {
          ChangeEvent() => e.notifier.debugLabel,
          ProviderInitEvent() => e.notifier.debugLabel,
          ProviderDisposeEvent() => e.notifier.debugLabel,
          ActionDispatchedEvent() => e.notifier.debugLabel,
          _ => null,
        },
        providerInitCause: switch (e) {
          ProviderInitEvent() => e.cause,
          _ => null,
        },
        value: switch (e) {
          ProviderInitEvent() => e.value.toString(),
          _ => null,
        },
        originActionId: switch (e) {
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
        debugOrigin: switch (e) {
          ActionDispatchedEvent() => e.debugOrigin,
          MessageEvent() => e.origin.debugLabel,
          _ => null,
        },
        actionLabel: switch (e) {
          ChangeEvent() => e.action?.debugLabel,
          ActionDispatchedEvent() => e.action.debugLabel,
          _ => null,
        },
        actionToString: switch (e) {
          ActionDispatchedEvent() => e.action.toString(),
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
        message: switch (e) {
          MessageEvent() => e.message,
          _ => null,
        },
      );
    });
  }
}
