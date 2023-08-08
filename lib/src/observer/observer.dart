import 'package:flutter/material.dart';
import 'package:riverpie/src/observer/event.dart';
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
  /// You can integrate this observer into the logging library
  /// used by your project.
  ///
  /// Usage:
  /// final _riverpieLogger = Logger('Riverpie');
  /// RiverpieDebugObserver(
  //    onLine: (s) => _riverpieLogger.info(s),
  //  )
  final void Function(String s)? onLine;

  const RiverpieDebugObserver({this.onLine});

  @override
  void handleEvent(RiverpieEvent event) {
    switch (event) {
      case NotifyEvent event:
        onLine?.call('########################################');
        _line('Notify by ${event.notifier.runtimeType}');
        _line(
          'Prev state: ${event.prev.toString().toSingleLine()}',
          followUp: true,
        );
        _line(
          'Next state: ${event.next.toString().toSingleLine()}',
          followUp: true,
        );
        final states = event.flagRebuild;
        _line(
          'Flag for rebuild: ${states.isEmpty ? '<none>' : states.map((s) => s.widget.getDebugLabel()).join(', ')}',
          followUp: true,
        );
        onLine?.call('########################################');
        break;
      case ProviderInitEvent event:
        final label =
            (event.provider.debugLabel ?? event.notifier?.runtimeType) ??
                event.provider.runtimeType;
        _line(
            'Provider initialized (${event.cause.description}): $label = ${event.value.toString().toSingleLine()}');
        break;
      case ListenerAddedEvent event:
        _line(
            'Listener added: ${event.state.widget.getDebugLabel()} on ${event.notifier.runtimeType}');
        break;
      case ListenerRemovedEvent event:
        _line(
            'Listener removed: ${event.state.widget.getDebugLabel()} on ${event.notifier.runtimeType}');
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
