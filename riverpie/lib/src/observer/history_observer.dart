import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/observer/observer.dart';

/// The configuration of the [RiverpieHistoryObserver].
/// It defines which events are saved.
class HistoryObserverConfig {
  /// Whether the observer should start immediately.
  final bool startImmediately;

  /// Whether the observer should save [ProviderInitEvent]s.
  final bool saveProviderInitEvents;

  /// Whether the observer should save [ListenerAddedEvent]s.
  final bool saveListenerAddedEvents;

  /// Whether the observer should save [ListenerRemovedEvent]s.
  final bool saveListenerRemovedEvents;

  /// Whether the observer should save [ChangeEvent]s.
  final bool saveChangeEvents;

  /// Whether the observer should save [EventEmittedEvent]s.
  final bool saveEventEmittedEvents;

  const HistoryObserverConfig({
    this.startImmediately = true,
    this.saveProviderInitEvents = false,
    this.saveListenerAddedEvents = false,
    this.saveListenerRemovedEvents = false,
    this.saveChangeEvents = true,
    this.saveEventEmittedEvents = true,
  });

  /// By default, only [ChangeEvent]s are saved.
  static const defaultConfig = HistoryObserverConfig();

  /// Saves all events.
  static const all = HistoryObserverConfig(
    saveProviderInitEvents: true,
    saveListenerAddedEvents: true,
    saveListenerRemovedEvents: true,
    saveChangeEvents: true,
    saveEventEmittedEvents: true,
  );
}

/// An observer that stores every event in a list.
/// This is useful for testing to keep track of the events.
class RiverpieHistoryObserver extends RiverpieObserver {
  /// The history of events.
  final List<RiverpieEvent> history = [];

  /// The configuration of the observer.
  final HistoryObserverConfig config;

  /// Whether the observer is currently listening to events.
  bool listening;

  RiverpieHistoryObserver([this.config = HistoryObserverConfig.defaultConfig])
      : listening = config.startImmediately;

  factory RiverpieHistoryObserver.all() {
    return RiverpieHistoryObserver(HistoryObserverConfig.all);
  }

  @override
  void handleEvent(RiverpieEvent event) {
    if (!listening) {
      return;
    }

    switch (event) {
      case ProviderInitEvent():
        if (config.saveProviderInitEvents) {
          history.add(event);
        }
        break;
      case ListenerAddedEvent():
        if (config.saveListenerAddedEvents) {
          history.add(event);
        }
        break;
      case ListenerRemovedEvent():
        if (config.saveListenerRemovedEvents) {
          history.add(event);
        }
        break;
      case ChangeEvent():
        if (config.saveChangeEvents) {
          history.add(event);
        }
        break;
      case EventEmittedEvent():
        if (config.saveEventEmittedEvents) {
          history.add(event);
        }
        break;
    }
  }

  /// Starts the observer to store events.
  void start() {
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
