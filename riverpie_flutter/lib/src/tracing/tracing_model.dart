// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

class _TracingEntry {
  final TimedRiverpieEvent event;
  final List<_TracingEntry> children;
  final bool superseded;
  final bool isWidget;

  // set afterwards
  ActionErrorEvent? error;

  _TracingEntry(
    this.event,
    this.children, {
    this.superseded = false,
    this.isWidget = false,
  });
}

enum _EventType {
  change,
  rebuild,
  action,
  providerInit,
  providerDispose,
  listenerAdded,
  listenerRemoved,
}

class FakeRebuildEvent implements RebuildEvent {
  final Rebuildable _rebuildable;

  FakeRebuildEvent(this._rebuildable);

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
}

extension on BaseNotifier {
  String get customDebugLabel {
    return debugLabel ?? runtimeType.toString();
  }
}

extension on RiverpieEvent {
  _EventType get internalType {
    return switch (this) {
      ChangeEvent() => _EventType.change,
      RebuildEvent() => _EventType.rebuild,
      ActionDispatchedEvent() => _EventType.action,
      ActionErrorEvent() => throw UnimplementedError(),
      ProviderInitEvent() => _EventType.providerInit,
      ProviderDisposeEvent() => _EventType.providerDispose,
      ListenerAddedEvent() => _EventType.listenerAdded,
      ListenerRemovedEvent() => _EventType.listenerRemoved,
    };
  }
}
