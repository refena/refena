// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

List<_TracingEntry> _buildEntries(
  Iterable<InputEvent> events,
  ErrorParser? errorParser,
) {
  final maxId = events.lastOrNull?.id ?? 0;
  final result = <_TracingEntry>[];
  for (final e in events) {
    mainSwitch:
    switch (e.type) {
      case InputEventType.change:
        if (e.actionId != null) {
          final existing = _findEventWithAction(result, e.actionId!);

          if (existing != null) {
            final created = _TracingEntry(e, []);

            _addWidgetEntries(maxId, created, e.rebuildWidgets!);

            existing.children.add(created);
            continue;
          }
        }

        final created = _TracingEntry(e, []);
        _addWidgetEntries(maxId, created, e.rebuildWidgets!);
        result.add(created);
        break;
      case InputEventType.rebuild:
        // Ref.rebuild inside an action
        final originActionId = e.parentAction;
        if (originActionId != null) {
          final existing = _findEventWithAction(result, originActionId);

          if (existing != null) {
            existing.children.add(_createRebuildEntry(e, false, maxId));
            continue;
          }

          result.add(_createRebuildEntry(e, false, maxId));
          continue;
        }

        // Ref.rebuild outside an action
        final debugOrigin = e.debugOrigin;
        if (debugOrigin != null) {
          result.add(_createRebuildEntry(e, false, maxId));
          continue;
        }

        // Rebuild due to a change of a parent
        final causes = e.parentEvents!;
        for (int i = 0; i < causes.length; i++) {
          final existing = _findEvent(result, causes[i]);
          if (existing != null) {
            final superseded = i != causes.length - 1;
            existing.children.add(_createRebuildEntry(e, superseded, maxId));
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

        // Rebuild due to a change of a parent
        final causes = e.parentEvents;
        if (causes != null) {
          for (final cause in causes) {
            final existing = _findEvent(result, cause);
            if (existing != null) {
              existing.children.add(_TracingEntry(e, []));

              // We expect only one parent
              break mainSwitch;
            }
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

        // Rebuild due to a change of a parent
        final causes = e.parentEvents;
        if (causes != null) {
          for (final cause in causes) {
            final existing = _findEvent(result, cause);
            if (existing != null) {
              existing.children.add(_TracingEntry(e, []));

              // We expect only one parent
              break mainSwitch;
            }
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

_TracingEntry _createRebuildEntry(
  InputEvent e,
  bool superseded,
  int maxId,
) {
  final created = _TracingEntry(
    e,
    [],
    superseded: superseded,
  );

  if (!superseded) {
    _addWidgetEntries(maxId, created, e.rebuildWidgets!);
  }

  return created;
}

final _idProvider = IdProvider();
void _addWidgetEntries(
    int startId, _TracingEntry entry, List<String> rebuildableList) {
  for (final rebuild in rebuildableList) {
    entry.children.add(_TracingEntry(
      InputEvent.only(
        id: startId + _idProvider.getNextId() + 1,
        type: InputEventType.rebuild,
        millisSinceEpoch: entry.event.millisSinceEpoch,
        label: rebuild,
        data: {},
      ),
      [],
      isWidget: true,
    ));
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
