import 'package:meta/meta.dart';
import 'package:refena/src/action/redux_action.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/observer/event.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';
import 'package:refena/src/reference.dart';

/// The observer receives every [RefenaEvent].
/// It is up to the implementation of how to use it.
abstract class RefenaObserver implements LabeledReference {
  RefenaObserver();

  bool _initialized = false;

  /// Whether the observer has been initialized.
  /// The observer won't receive any events until it is initialized.
  bool get initialized => _initialized;

  late Ref _ref;

  /// Use the [ref] to access the state.
  Ref get ref => _ref;

  /// Override this method to have additional initialization logic.
  /// You can use [ref] at this point.
  void init() {}

  /// Called when an event occurs.
  /// Override this method to handle the event.
  void handleEvent(RefenaEvent event);

  /// Override this getter to provide a custom label.
  @override
  String get debugLabel => runtimeType.toString();

  @internal
  void internalSetup(ProxyRef ref) {
    _ref = ref;
    init();
    _initialized = true;
  }

  @internal
  void internalHandleEvent(RefenaEvent event) {
    if (!_initialized) {
      return;
    }
    handleEvent(event);
  }
}

/// An observer where you can specify the behavior right in the constructor.
/// This is useful for testing to avoid boilerplate code.
class RefenaCallbackObserver {
  final void Function(RefenaEvent event) onEvent;

  const RefenaCallbackObserver({
    required this.onEvent,
  });

  void handleEvent(RefenaEvent event) {
    onEvent(event);
  }
}

/// The observer to use multiple observers at once.
class RefenaMultiObserver extends RefenaObserver {
  final List<RefenaObserver> observers;

  RefenaMultiObserver({required this.observers});

  @override
  void init() {}

  @override
  void handleEvent(RefenaEvent event) {
    for (final observer in observers) {
      observer.internalHandleEvent(event);
    }
  }

  @internal
  @override
  void internalSetup(ProxyRef ref) {
    for (final observer in observers) {
      observer.internalSetup(ProxyRef(
        ref.container,
        observer.debugLabel,
        observer,
      ));
    }
    _initialized = true;
  }
}

/// A plug-and-play [RefenaObserver] that prints every action into
/// the console for easier debugging.
class RefenaDebugObserver extends RefenaObserver {
  static const _t = '┌────────────────────────────────────────────────────────';
  static const _b = '└────────────────────────────────────────────────────────';

  /// You can integrate this observer into the logging library
  /// used by your project.
  ///
  /// Usage:
  /// final _refenaLogger = Logger('Refena');
  /// RefenaDebugObserver(
  ///   onLine: (s) => _refenaLogger.info(s),
  /// )
  final void Function(String s)? onLine;

  /// Similar to [onLine] but only called when an error occurs.
  /// Fallbacks to [onLine] if not specified.
  final void Function(String s, Object e, StackTrace st)? onErrorLine;

  /// If the given function returns `true`, then the event
  /// won't be logged.
  final bool Function(RefenaEvent event)? exclude;

  RefenaDebugObserver({
    this.onLine,
    this.onErrorLine,
    this.exclude,
  });

  @override
  void handleEvent(RefenaEvent event) {
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
        final label = _getProviderDebugLabel(null, event.rebuildable);
        final causes =
            ' triggered by [${event.causes.map((c) => c.debugLabel).join(', ')}]';
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
        final label = _getProviderDebugLabel(event.provider, null);
        _line('Provider disposed: [$label]');
        onLine?.call(_b);
        break;
      case ActionDispatchedEvent event:
        final origin = event.debugOriginRef;
        final String originStr;
        final String externalStr;
        if (origin is BaseReduxAction) {
          originStr = '${origin.notifier.hideGlobalLabel}${origin.debugLabel}';
          externalStr = event.notifier is GlobalRedux
              ? ' (global)'
              : (origin.notifierType == event.action.notifierType
                  ? ''
                  : ' (external)');
        } else {
          originStr = event.debugOrigin;
          externalStr = event.notifier is GlobalRedux ? ' (global)' : '';
        }
        _line(
            'Action dispatched: [$originStr] -> [${event.notifier.hideGlobalLabel}${event.action.debugLabel}]$externalStr');
        break;
      case ActionFinishedEvent event:
        final resultString = event.result == null
            ? ''
            : ' with result: [${event.result.toString().toSingleLine()}]';
        _line(
            'Action finished:   [${event.action.notifier.hideGlobalLabel}${event.action.debugLabel}]$resultString');
        break;
      case ActionErrorEvent event:
        _line(
          'Action error:      [${event.action.notifier.debugLabel}.${event.action.debugLabel}.${event.lifecycle.name}] has thrown the following error:',
          error: event.error,
          stackTrace: event.stackTrace,
        );
        break;
      case MessageEvent event:
        _line(event.message);
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

      print('[Refena] $line\n$error\n$stackTrace');
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
      print('         $line');
    } else {
      print('[Refena] $line');
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

extension on BaseNotifier {
  String get hideGlobalLabel => this is GlobalRedux ? '' : '$debugLabel.';
}
