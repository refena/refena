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
        for (int i = 0; i < e.rebuildCauses!.length; i++) {
          final causes = e.rebuildCauses!;
          final existing = <_TracingEntry>[];
          _findEvent(result, causes[i], existing);

          final superseded = i != causes.length - 1;
          for (final entry in existing) {
            final created = _TracingEntry(
              e,
              [],
              superseded: superseded,
            );

            if (!superseded) {
              _addWidgetEntries(created, e.rebuildWidgets!);
            }

            entry.children.add(created);
          }
        }
        break;
      case InputEventType.actionDispatched:
        final originActionId = e.originActionId;
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
        result.add(_TracingEntry(e, []));
        break;
      case InputEventType.message:
        if (e.originActionId != null) {
          final existing = _findEventWithAction(result, e.originActionId!);

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

/// Recursively find the event in the result list
/// and add it to the [found] list.
/// The first item in the list is the newest event.
void _findEvent(
  List<_TracingEntry> result,
  int eventId,
  List<_TracingEntry> found,
) {
  for (final entry in result.reversed) {
    _findEvent(entry.children, eventId, found);

    if (entry.event.id == eventId) {
      found.add(entry);
    }
  }
}

void _addWidgetEntries(_TracingEntry entry, List<String> rebuildableList) {
  for (final rebuild in rebuildableList) {
    entry.children.add(_TracingEntry(
      InputEvent.only(
        id: -1,
        type: InputEventType.rebuild,
        millisSinceEpoch: entry.timestamp.millisecondsSinceEpoch,
        rebuildableLabel: rebuild,
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
  final contains = switch (e.type) {
    InputEventType.change => e.stateType!.toLowerCase().contains(query),
    InputEventType.rebuild =>
      e.rebuildableLabel!.toLowerCase().contains(query) ||
          (e.stateType != null &&
              e.stateType.toString().toLowerCase().contains(query)),
    InputEventType.actionDispatched =>
      e.actionLabel!.toLowerCase().contains(query) ||
          e.debugOrigin!.toLowerCase().contains(query),
    InputEventType.actionFinished => throw UnimplementedError(),
    InputEventType.actionError => throw UnimplementedError(),
    InputEventType.init =>
      e.providerLabel.toString().toLowerCase().contains(query),
    InputEventType.dispose =>
      e.providerLabel.toString().toLowerCase().contains(query),
    InputEventType.message => e.message!.toLowerCase().contains(query),
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
