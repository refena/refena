// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

List<_TracingEntry> _buildEntries(
  Iterable<InputEvent> events,
  ErrorParser? errorParser,
) {
  final result = <_TracingEntry>[];
  for (final e in events) {
    switch (e.type) {
      case InputEventType.change:
        if (e.actionId != null) {
          final existing = _findEventWithAction(result, e.actionId!);

          if (existing != null) {
            final created = _TracingEntry(e, []);

            _addWidgetEntries(created, e.rebuildWidgets!);

            existing.children.add(created);
            continue;
          }
        }

        final created = _TracingEntry(e, []);
        _addWidgetEntries(created, e.rebuildWidgets!);
        result.add(created);
        break;
      case InputEventType.rebuild:
        final causes = e.parentEvents!;
        for (int i = 0; i < causes.length; i++) {
          final existing = _findEvent(result, causes[i]);
          if (existing != null) {
            final superseded = i != causes.length - 1;
            final created = _TracingEntry(
              e,
              [],
              superseded: superseded,
            );

            if (!superseded) {
              _addWidgetEntries(created, e.rebuildWidgets!);
            }

            existing.children.add(created);
          }
        }
        break;
      case InputEventType.actionDispatched:
        final originActionId = e.parentAction;
        if (originActionId != null) {
          final existing = _findEventWithAction(result, originActionId);

          if (existing != null) {
            existing.children.add(_TracingEntry(e, []));
            continue;
          }
        }
        result.add(_TracingEntry(e, []));
        break;
      case InputEventType.actionFinished:
        final existing = _findEventWithAction(result, e.actionId!);
        if (existing != null) {
          existing.result = e.actionResult;
          existing.millis =
              e.millisSinceEpoch - existing.event.millisSinceEpoch;
        }
        break;
      case InputEventType.actionError:
        final existing = _findEventWithAction(result, e.actionId!);
        if (existing != null) {
          existing.millis =
              e.millisSinceEpoch - existing.event.millisSinceEpoch;
          existing.error = _ErrorEntry(
            actionLabel: existing.event.actionLabel!,
            actionLifecycle: e.actionLifecycle!,
            originalError: e.event as ActionErrorEvent?,
            error: e.actionError!,
            stackTrace: e.actionStackTrace!,
            parsedErrorData: e.actionErrorData,
            errorParser: errorParser,
          );
        }
        break;
      case InputEventType.init:
        result.add(_TracingEntry(e, []));
        break;
      case InputEventType.dispose:
        final parentEvent = e.parentEvents?.firstOrNull;
        if (parentEvent != null) {
          final existing = _findEvent(result, parentEvent);

          if (existing != null) {
            existing.children.add(_TracingEntry(e, []));
            break;
          }
        }
        result.add(_TracingEntry(e, []));
        break;
      case InputEventType.message:
        if (e.parentAction != null) {
          final existing = _findEventWithAction(result, e.parentAction!);

          if (existing != null) {
            existing.children.add(_TracingEntry(e, []));
            continue;
          }
        }
        result.add(_TracingEntry(e, []));
        break;
    }
  }
  return result;
}

// recursively find the action in the result list
_TracingEntry? _findEventWithAction(List<_TracingEntry> result, int actionId) {
  for (final entry in result.reversed) {
    if (entry.event.type == InputEventType.actionDispatched) {
      if (entry.event.actionId == actionId) {
        return entry;
      }
    }
    final found = _findEventWithAction(entry.children, actionId);
    if (found != null) {
      return found;
    }
  }
  return null;
}

/// Recursively find the event in the result list.
_TracingEntry? _findEvent(
  List<_TracingEntry> result,
  int eventId,
) {
  for (final entry in result.reversed) {
    if (entry.event.id == eventId) {
      return entry;
    }

    final found = _findEvent(entry.children, eventId);
    if (found != null) {
      return found;
    }
  }

  return null;
}

void _addWidgetEntries(_TracingEntry entry, List<String> rebuildableList) {
  for (final rebuild in rebuildableList) {
    entry.children.add(_TracingEntry(
      InputEvent.only(
        id: -1,
        type: InputEventType.rebuild,
        millisSinceEpoch: entry.timestamp.millisecondsSinceEpoch,
        label: rebuild,
        data: {},
      ),
      [],
      isWidget: true,
    ));
    break;
  }
}

// query is already lower case
bool _contains(_TracingEntry entry, String query) {
  final e = entry.event;
  final contains = e.label.toLowerCase().contains(query) ||
      e.data.toString().toLowerCase().contains(query);

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
