// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

List<_TracingEntry> _buildEntries(Iterable<TimedRiverpieEvent> events) {
  final result = <_TracingEntry>[];
  for (final event in events) {
    switch (event.event) {
      case ChangeEvent e:
        if (e.action != null) {
          final existing = _findEventWithAction(result, e.action!);

          if (existing != null) {
            final created = _TracingEntry(
              event,
              [],
            );

            _addWidgetEntries(created, e.rebuild);

            existing.children.add(created);
            continue;
          }
        }

        final created = _TracingEntry(event, []);
        _addWidgetEntries(created, e.rebuild);
        result.add(created);
        break;
      case RebuildEvent e:
        for (int i = 0; i < e.causes.length; i++) {
          final existing = <_TracingEntry>[];
          _findEvent(result, e.causes[i], existing);

          final superseded = i != e.causes.length - 1;
          for (final entry in existing) {
            final created = _TracingEntry(
              event,
              [],
              superseded: superseded,
            );

            if (!superseded) {
              _addWidgetEntries(created, e.rebuild);
            }

            entry.children.add(created);
          }
        }
        break;
      case ActionDispatchedEvent e:
        final origin = e.debugOriginRef;
        if (origin is BaseReduxAction) {
          final existing = _findEventWithAction(result, origin);

          if (existing != null) {
            existing.children.add(_TracingEntry(event, []));
            continue;
          }
        }
        result.add(_TracingEntry(event, []));
        break;
      case ActionErrorEvent e:
        final existing = _findEventWithAction(result, e.action);
        if (existing != null) {
          existing.error = e;
        }
        break;
      case ProviderInitEvent _:
        result.add(_TracingEntry(event, []));
        break;
      case ProviderDisposeEvent _:
        result.add(_TracingEntry(event, []));
        break;
      case MessageEvent e:
        final origin = e.origin;
        if (origin is BaseReduxAction) {
          final existing = _findEventWithAction(result, origin);

          if (existing != null) {
            existing.children.add(_TracingEntry(event, []));
            continue;
          }
        }
        result.add(_TracingEntry(event, []));
        break;
      case ListenerAddedEvent _:
        result.add(_TracingEntry(event, []));
        break;
      case ListenerRemovedEvent _:
        result.add(_TracingEntry(event, []));
        break;
    }
  }
  return result;
}

// recursively find the action in the result list
_TracingEntry? _findEventWithAction(
    List<_TracingEntry> result, BaseReduxAction action) {
  for (final entry in result.reversed) {
    if (entry.event.event is ActionDispatchedEvent) {
      if (identical(
          (entry.event.event as ActionDispatchedEvent).action, action)) {
        return entry;
      }
    }
    final found = _findEventWithAction(entry.children, action);
    if (found != null) {
      return found;
    }
  }
  return null;
}

// recursively find the event in the result list
// the first item in the list is the newest event
void _findEvent(
  List<_TracingEntry> result,
  RiverpieEvent event,
  List<_TracingEntry> found,
) {
  for (final entry in result.reversed) {
    _findEvent(entry.children, event, found);

    if (identical(entry.event.event, event)) {
      found.add(entry);
    }
  }
}

void _addWidgetEntries(_TracingEntry entry, List<Rebuildable> rebuildableList) {
  for (final rebuild in rebuildableList) {
    if (rebuild is ElementRebuildable) {
      entry.children.add(_TracingEntry(
        TimedRiverpieEvent(
          timestamp: entry.event.timestamp,
          event: FakeRebuildEvent(rebuild),
        ),
        [],
        isWidget: true,
      ));
      break;
    }
  }
}

// query is already lower case
bool _contains(_TracingEntry entry, String query) {
  final contains = switch (entry.event.event) {
    ChangeEvent event =>
      event.stateType.toString().toLowerCase().contains(query),
    RebuildEvent event =>
      event.rebuildable.debugLabel.toLowerCase().contains(query) ||
          (event is! FakeRebuildEvent &&
              event.stateType.toString().toLowerCase().contains(query)),
    ActionDispatchedEvent event =>
      event.action.debugLabel.toLowerCase().contains(query) ||
          event.debugOrigin.toLowerCase().contains(query),
    ActionErrorEvent _ => throw UnimplementedError(),
    ProviderInitEvent event =>
      event.provider.toString().toLowerCase().contains(query),
    ProviderDisposeEvent event =>
      event.provider.toString().toLowerCase().contains(query),
    MessageEvent event => event.message.toLowerCase().contains(query),
    ListenerAddedEvent event =>
      event.rebuildable.debugLabel.toLowerCase().contains(query) ||
          event.notifier.debugLabel?.toLowerCase().contains(query) == true,
    ListenerRemovedEvent event =>
      event.rebuildable.debugLabel.toLowerCase().contains(query) ||
          event.notifier.debugLabel?.toLowerCase().contains(query) == true,
  };

  if (contains) {
    return true;
  }

  // Recursively check children
  for (final child in entry.children) {
    if (_contains(child, query)) {
      return true;
    }
  }

  return false;
}

/// Count the number of items in the tree
int _countItems(List<_TracingEntry> entries) {
  var count = 0;
  for (final entry in entries) {
    count++;
    count += _countItems(entry.children);
  }
  return count;
}
