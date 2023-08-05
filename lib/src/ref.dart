import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';

/// "read" function type
typedef RefRead = T Function<T>(BaseProvider<T> provider);

/// "notifier" function type
typedef RefNotifier = N Function<N extends BaseNotifier<T>, T>(
    NotifierProvider<N, T> provider);

/// "listen" function type
typedef RefListen = T Function<T>(
    BaseProvider<T> provider, ListenerCallback<T> listener);

/// The base ref to read and notify providers.
/// These methods can be called anywhere.
abstract class Ref {
  /// Get the current value of a provider without listening to changes.
  T read<T>(BaseProvider<T> provider);

  /// Get the notifier of a provider.
  N notifier<N extends BaseNotifier<T>, T>(NotifierProvider<N, T> provider);
}

/// The ref to watch providers (in addition to read and notify).
/// Only call [watch] during build.
class WatchableRef extends Ref {
  @override
  T read<T>(BaseProvider<T> provider) {
    return _read<T>(provider);
  }

  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifierProvider<N, T> provider) {
    return _notifier<N, T>(provider);
  }

  /// Get the current value of a provider and listen to changes.
  /// The listener will be disposed automatically when the widget is disposed.
  T watch<T>(BaseProvider<T> provider) {
    return _watch<T>(provider);
  }

  /// Get the current value of a provider and listen to changes.
  /// In addition, a callback can be provided to be notified of changes.
  /// The listener will be disposed automatically when the widget is disposed.
  T listen<T>(BaseProvider<T> provider, ListenerCallback<T> listener) {
    return _listen<T>(provider, listener);
  }

  final RefRead _read;
  final RefNotifier _notifier;
  final RefRead _watch;
  final RefListen _listen;

  WatchableRef({
    required RefRead read,
    required RefNotifier notifier,
    required RefRead watch,
    required RefListen listen,
  })  : _read = read,
        _notifier = notifier,
        _watch = watch,
        _listen = listen;
}
