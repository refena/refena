import 'package:flutter/material.dart';
import 'package:riverpie/src/notifier/notifier.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/provider/provider.dart';
import 'package:riverpie/src/widget/consumer.dart';

/// The observer receives every [RiverpieEvent].
/// It is up to the implementation of how to use it.
abstract class RiverpieObserver {
  const RiverpieObserver();

  void handleEvent(RiverpieEvent event);
}

/// A plug-and-play [RiverpieObserver] that prints every action into
/// the console for easier debugging.
class RiverpieDebugObserver extends RiverpieObserver {
  static const _s = '########################################';

  /// You can integrate this observer into the logging library
  /// used by your project.
  ///
  /// Usage:
  /// final _riverpieLogger = Logger('Riverpie');
  /// RiverpieDebugObserver(
  ///   onLine: (s) => _riverpieLogger.info(s),
  /// )
  final void Function(String s)? onLine;

  /// If the given function returns `true`, then the event
  /// won't be logged.
  final bool Function(RiverpieEvent event)? exclude;

  const RiverpieDebugObserver({
    this.onLine,
    this.exclude,
  });

  @override
  void handleEvent(RiverpieEvent event) {
    if (exclude != null && exclude!(event)) {
      return;
    }

    switch (event) {
      case NotifyEvent event:
        onLine?.call(_s);
        final label = _getProviderDebugLabel(null, event.notifier);
        _line('Notify by <$label>');
        _line(
          ' - Prev: ${event.prev.toString().toSingleLine()}',
          followUp: true,
        );
        _line(
          ' - Next: ${event.next.toString().toSingleLine()}',
          followUp: true,
        );
        final states = event.flagRebuild;
        _line(
          ' - Rebuild (${states.length}): ${states.isEmpty ? '<none>' : states.map((s) => '<${s.widget.getDebugLabel()}>').join(', ')}',
          followUp: true,
        );
        onLine?.call(_s);
        break;
      case ProviderInitEvent event:
        onLine?.call(_s);
        final label = _getProviderDebugLabel(event.provider, event.notifier);
        _line('Provider initialized: <$label>');
        _line(' - Reason: ${event.cause.description}', followUp: true);
        _line(' - Value: ${event.value.toString().toSingleLine()}',
            followUp: true);
        onLine?.call(_s);
        break;
      case ListenerAddedEvent event:
        final label = _getProviderDebugLabel(null, event.notifier);
        _line(
            'Listener added: <${event.state.widget.getDebugLabel()}> on <$label>');
        break;
      case ListenerRemovedEvent event:
        final label = _getProviderDebugLabel(null, event.notifier);
        _line(
            'Listener removed: <${event.state.widget.getDebugLabel()}> on <$label>');
        break;
    }
  }

  void _line(String line, {bool followUp = false}) {
    if (onLine != null) {
      // use given callback
      onLine!.call(line);
      return;
    }

    // default to print
    if (followUp) {
      print('           $line');
    } else {
      print('[Riverpie] $line');
    }
  }
}

extension on ProviderInitCause {
  String get description {
    return switch (this) {
      ProviderInitCause.override => 'SCOPE OVERRIDE',
      ProviderInitCause.access => 'INITIAL ACCESS',
    };
  }
}

extension on String {
  String toSingleLine() {
    return replaceAll('\n', '\\n');
  }
}

extension on Widget {
  String getDebugLabel() {
    final widget = this;
    if (widget is ExpensiveConsumer) {
      return widget.debugLabel;
    }
    return runtimeType.toString();
  }
}

String _getProviderDebugLabel(BaseProvider? provider, BaseNotifier? notifier) {
  return notifier?.debugLabel ??
      provider?.debugLabel ??
      notifier?.runtimeType.toString() ??
      provider!.runtimeType.toString();
}
