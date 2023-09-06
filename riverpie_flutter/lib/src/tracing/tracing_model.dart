// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

class _TracingEntry {
  final DateTime timestamp;
  final RiverpieEvent event;
  final List<_TracingEntry> children;
  final bool superseded;
  final bool isWidget;

  // set afterwards
  ActionErrorEvent? error;

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

enum _EventType {
  change,
  rebuild,
  action,
  providerInit,
  providerDispose,
  message,
}

class FakeRebuildEvent implements RebuildEvent {
  final Rebuildable _rebuildable;

  @override
  final int millisSinceEpoch;

  FakeRebuildEvent(this._rebuildable, this.millisSinceEpoch);

  @override
  List<AbstractChangeEvent> get causes => throw UnimplementedError();

  @override
  get next => throw UnimplementedError();

  @override
  Rebuildable get rebuildable => _rebuildable;

  @override
  get prev => throw UnimplementedError();

  @override
  List<Rebuildable> get rebuild => throw UnimplementedError();

  @override
  Type get stateType => throw UnimplementedError();

  @override
  String get debugLabel => throw UnimplementedError();

  @override
  bool compareIdentity(LabeledReference other) =>
      _rebuildable.compareIdentity(other);
}

extension on RiverpieEvent {
  _EventType get internalType {
    // ActionFinishedEvent and ActionErrorEvent are merged into ActionDispatchedEvent
    return switch (this) {
      ChangeEvent() => _EventType.change,
      RebuildEvent() => _EventType.rebuild,
      ActionDispatchedEvent() => _EventType.action,
      ActionFinishedEvent() => throw UnimplementedError(),
      ActionErrorEvent() => throw UnimplementedError(),
      ProviderInitEvent() => _EventType.providerInit,
      ProviderDisposeEvent() => _EventType.providerDispose,
      MessageEvent() => _EventType.message,
    };
  }
}
