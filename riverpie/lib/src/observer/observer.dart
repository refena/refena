import 'package:meta/meta.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/observer/event.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/proxy_container.dart';
import 'package:riverpie/src/ref.dart';

/// The observer receives every [RiverpieEvent].
/// It is up to the implementation of how to use it.
abstract class RiverpieObserver {
  RiverpieObserver();

  late Ref _ref;

  /// Use the [ref] to access the state.
  Ref get ref => _ref;

  /// Override this method to have additional initialization logic.
  /// You can use [ref] at this point.
  void init() {}

  /// Called when an event occurs.
  /// Override this method to handle the event.
  void handleEvent(RiverpieEvent event);

  /// Override this getter to provide a custom label.
  String get debugLabel => runtimeType.toString();

  @internal
  void internalSetup(RiverpieContainer container) {
    _ref = container;
  }
}

/// An observer where you can specify the behavior right in the constructor.
/// This is useful for testing to avoid boilerplate code.
class RiverpieCallbackObserver {
  final void Function(RiverpieEvent event) onEvent;

  const RiverpieCallbackObserver({
    required this.onEvent,
  });

  void handleEvent(RiverpieEvent event) {
    onEvent(event);
  }
}

/// The observer to use multiple observers at once.
class RiverpieMultiObserver extends RiverpieObserver {
  final List<RiverpieObserver> observers;

  RiverpieMultiObserver({required this.observers});

  @override
  void init() {
    for (final observer in observers) {
      observer.init();
    }
  }

  @override
  void handleEvent(RiverpieEvent event) {
    for (final observer in observers) {
      observer.handleEvent(event);
    }
  }

  @internal
  @override
  void internalSetup(RiverpieContainer container) {
    for (final observer in observers) {
      observer.internalSetup(ProxyContainer(
        container,
        observer.debugLabel,
        observer,
      ));
    }
  }
}

/// A plug-and-play [RiverpieObserver] that prints every action into
/// the console for easier debugging.
class RiverpieDebugObserver extends RiverpieObserver {
  static const _t = '┌────────────────────────────────────────────────────────';
  static const _b = '└────────────────────────────────────────────────────────';

  /// You can integrate this observer into the logging library
  /// used by your project.
  ///
  /// Usage:
  /// final _riverpieLogger = Logger('Riverpie');
  /// RiverpieDebugObserver(
  ///   onLine: (s) => _riverpieLogger.info(s),
  /// )
  final void Function(String s)? onLine;

  /// Similar to [onLine] but only called when an error occurs.
  /// Fallbacks to [onLine] if not specified.
  final void Function(String s, Object e, StackTrace st)? onErrorLine;

  /// If the given function returns `true`, then the event
  /// won't be logged.
  final bool Function(RiverpieEvent event)? exclude;

  RiverpieDebugObserver({
    this.onLine,
    this.onErrorLine,
    this.exclude,
  });

  @override
  void handleEvent(RiverpieEvent event) {
    if (exclude != null && exclude!(event)) {
      return;
    }

    switch (event) {
      case ChangeEvent event:
        onLine?.call(_t);
        final label = _getProviderDebugLabel(null, event.notifier);
        final actionStr = event.action == null
            ? ''
            : ' triggered by [${event.action.runtimeType}]';
        _line('Change by [$label]$actionStr', intentWhenLogger: true);
        _line(
          ' - Prev: ${event.prev.toString().toSingleLine()}',
          followUp: true,
        );
        _line(
          ' - Next: ${event.next.toString().toSingleLine()}',
          followUp: true,
        );
        final rebuildable = event.rebuild;
        _line(
          ' - Rebuild (${rebuildable.length}): ${rebuildable.isEmpty ? '<none>' : rebuildable.map((r) => '[${r.debugLabel}]').join(', ')}',
          followUp: true,
        );
        onLine?.call(_b);
        break;
      case RebuildEvent event:
        onLine?.call(_t);
        final label =
            _getProviderDebugLabel(null, event.rebuildable as BaseNotifier);
        final causes =
            ' triggered by [${event.causes.map((c) => c.toString()).join(', ')}]';
        _line('Rebuild by [$label]$causes', intentWhenLogger: true);
        _line(
          ' - Prev: ${event.prev.toString().toSingleLine()}',
          followUp: true,
        );
        _line(
          ' - Next: ${event.next.toString().toSingleLine()}',
          followUp: true,
        );
        final rebuildable = event.rebuild;
        _line(
          ' - Rebuild (${rebuildable.length}): ${rebuildable.isEmpty ? '<none>' : rebuildable.map((r) => '[${r.debugLabel}]').join(', ')}',
          followUp: true,
        );
        onLine?.call(_b);
      case ProviderInitEvent event:
        onLine?.call(_t);
        final label = _getProviderDebugLabel(event.provider, event.notifier);
        _line('Provider initialized: [$label]', intentWhenLogger: true);
        _line(' - Reason: ${event.cause.description}', followUp: true);
        _line(
          ' - Value: ${event.value.toString().toSingleLine()}',
          followUp: true,
        );
        onLine?.call(_b);
        break;
      case ProviderDisposeEvent event:
        onLine?.call(_t);
        final label = _getProviderDebugLabel(event.provider, event.notifier);
        _line('Provider disposed: [$label]');
        onLine?.call(_b);
        break;
      case ListenerAddedEvent event:
        final label = _getProviderDebugLabel(null, event.notifier);
        _line('Listener added: [${event.rebuildable.debugLabel}] on [$label]');
        break;
      case ListenerRemovedEvent event:
        final label = _getProviderDebugLabel(null, event.notifier);
        _line(
            'Listener removed: [${event.rebuildable.debugLabel}] on [$label]');
        break;
      case ActionDispatchedEvent event:
        final label = _getProviderDebugLabel(null, event.notifier);
        _line(
            'Action dispatched: [$label.${event.action.runtimeType}] by [${event.debugOrigin}]');
        break;
      case ActionErrorEvent event:
        final label = _getProviderDebugLabel(null, event.action.notifier);
        _line(
          'Action error: [$label.${event.action.debugLabel}] has thrown the following error:',
          error: event.error,
          stackTrace: event.stackTrace,
        );
        break;
    }
  }

  void _line(
    String line, {
    bool followUp = false,
    bool intentWhenLogger = false,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (error != null) {
      if (onErrorLine != null) {
        onErrorLine!.call(line, error, stackTrace!);
        return;
      }

      if (onLine != null) {
        onLine!.call('  $line\n$error\n$stackTrace');
        return;
      }
    }

    if (onLine != null) {
      // use given callback
      if (intentWhenLogger) {
        onLine!.call('  $line');
      } else {
        onLine!.call(line);
      }
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
      ProviderInitCause.initial => 'INITIAL DURING STARTUP',
      ProviderInitCause.access => 'INITIAL ACCESS',
    };
  }
}

extension on String {
  String toSingleLine() {
    return replaceAll('\n', '\\n');
  }
}

String _getProviderDebugLabel(BaseProvider? provider, BaseNotifier? notifier) {
  assert(provider != null || notifier != null);

  return notifier?.debugLabel ??
      provider?.debugLabel ??
      notifier?.runtimeType.toString() ??
      provider!.runtimeType.toString();
}
