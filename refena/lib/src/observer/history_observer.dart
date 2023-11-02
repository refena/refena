import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/observer/observer.dart';

/// The configuration of the [RefenaHistoryObserver].
/// It defines which events are saved.
class HistoryObserverConfig {
  /// Whether the observer should start immediately.
  final bool startImmediately;

  /// Whether the observer should save [ProviderInitEvent]s.
  final bool saveProviderInitEvents;

  /// Whether the observer should save [ProviderDisposeEvent]s.
  final bool saveProviderDisposeEvents;

  /// Whether the observer should save [ChangeEvent]s.
  final bool saveChangeEvents;

  /// Whether the observer should save [RebuildEvent]s.
  final bool saveRebuildEvents;

  /// Whether the observer should save [ActionDispatchedEvent]s.
  final bool saveActionDispatchedEvents;

  /// Whether the observer should save [ActionFinishedEvent]s.
  final bool saveActionFinishedEvents;

  /// Whether the observer should save [ActionErrorEvent]s.
  final bool saveActionErrorEvents;

  /// Whether the observer should save [MessageEvent]s.
  final bool saveMessageEvents;

  const HistoryObserverConfig({
    this.startImmediately = true,
    this.saveProviderInitEvents = false,
    this.saveProviderDisposeEvents = false,
    this.saveChangeEvents = true,
    this.saveRebuildEvents = true,
    this.saveActionDispatchedEvents = true,
    this.saveActionFinishedEvents = true,
    this.saveActionErrorEvents = true,
    this.saveMessageEvents = true,
  });

  /// By default, only [ChangeEvent]s are saved.
  static const defaultConfig = HistoryObserverConfig();

  /// Saves all events.
  static const all = HistoryObserverConfig(
    saveProviderInitEvents: true,
    saveProviderDisposeEvents: true,
    saveChangeEvents: true,
    saveRebuildEvents: true,
    saveActionDispatchedEvents: true,
    saveActionErrorEvents: true,
    saveMessageEvents: true,
  );

  /// Saves only the specified events.
  static HistoryObserverConfig only({
    bool startImmediately = true,
    bool providerInit = false,
    bool providerDispose = false,
    bool change = false,
    bool rebuild = false,
    bool actionDispatched = false,
    bool actionFinished = false,
    bool actionError = false,
    bool message = false,
  }) {
    return HistoryObserverConfig(
      startImmediately: startImmediately,
      saveProviderInitEvents: providerInit,
      saveProviderDisposeEvents: providerDispose,
      saveChangeEvents: change,
      saveRebuildEvents: rebuild,
      saveActionDispatchedEvents: actionDispatched,
      saveActionFinishedEvents: actionFinished,
      saveActionErrorEvents: actionError,
      saveMessageEvents: message,
    );
  }
}

/// An observer that stores every event in a list.
/// This is useful for testing to keep track of the events.
///
/// {@category Testing}
class RefenaHistoryObserver extends RefenaObserver {
  /// The history of events.
  final List<RefenaEvent> history = [];

  /// Dispatched actions.
  /// Make sure that [HistoryObserverConfig.saveActionDispatchedEvents] is true.
  List<BaseReduxAction> get dispatchedActions =>
      history.whereType<ActionDispatchedEvent>().map((e) => e.action).toList();

  /// The configuration of the observer.
  final HistoryObserverConfig config;

  /// Whether the observer is currently listening to events.
  bool listening;

  RefenaHistoryObserver([this.config = HistoryObserverConfig.defaultConfig])
      : listening = config.startImmediately;

  factory RefenaHistoryObserver.all() {
    return RefenaHistoryObserver(HistoryObserverConfig.all);
  }

  factory RefenaHistoryObserver.only({
    bool startImmediately = true,
    bool providerInit = false,
    bool providerDispose = false,
    bool listenerAdded = false,
    bool listenerRemoved = false,
    bool change = false,
    bool rebuild = false,
    bool actionDispatched = false,
    bool actionFinished = false,
    bool actionError = false,
    bool message = false,
  }) {
    return RefenaHistoryObserver(HistoryObserverConfig.only(
      startImmediately: startImmediately,
      providerInit: providerInit,
      providerDispose: providerDispose,
      change: change,
      rebuild: rebuild,
      actionDispatched: actionDispatched,
      actionFinished: actionFinished,
      actionError: actionError,
      message: message,
    ));
  }

  @override
  void handleEvent(RefenaEvent event) {
    if (!listening) {
      return;
    }

    switch (event) {
      case ProviderInitEvent():
        if (config.saveProviderInitEvents) {
          history.add(event);
        }
        break;
      case ProviderDisposeEvent():
        if (config.saveProviderDisposeEvents) {
          history.add(event);
        }
        break;
      case ChangeEvent():
        if (config.saveChangeEvents) {
          history.add(event);
        }
        break;
      case RebuildEvent():
        if (config.saveRebuildEvents) {
          history.add(event);
        }
        break;
      case ActionDispatchedEvent():
        if (config.saveActionDispatchedEvents) {
          history.add(event);
        }
        break;
      case ActionFinishedEvent():
        if (config.saveActionFinishedEvents) {
          history.add(event);
        }
        break;
      case ActionErrorEvent():
        if (config.saveActionErrorEvents) {
          history.add(event);
        }
        break;
      case MessageEvent():
        if (config.saveMessageEvents) {
          history.add(event);
        }
        break;
    }
  }

  /// Starts the observer to store events.
  void start({bool clearHistory = false}) {
    if (clearHistory) {
      clear();
    }
    listening = true;
  }

  /// Stops the observer from storing events.
  void stop() {
    listening = false;
  }

  /// Clears the history.
  void clear() {
    history.clear();
  }
}
