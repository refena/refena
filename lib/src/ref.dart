import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';

/// The base ref to read and notify providers.
/// These methods can be called anywhere.
class Ref {
  /// Get the current value of a provider without listening to changes.
  final T Function<T>(BaseProvider<T> provider) read;

  /// Get the notifier of a provider.
  final N Function<N extends Notifier<T>, T>(NotifierProvider<N, T> provider)
      notify;

  Ref({
    required this.read,
    required this.notify,
  });
}

/// The ref to watch providers (in addition to read and notify).
/// Only call [watch] during build.
class WatchableRef extends Ref {
  /// Get the current value of a provider and listen to changes.
  /// The listener will be disposed automatically when the widget is disposed.
  final T Function<T>(BaseProvider<T> provider) watch;

  /// Get the current value of a provider and listen to changes.
  /// In addition, a callback can be provided to be notified of changes.
  /// The listener will be disposed automatically when the widget is disposed.
  final T Function<T>(BaseProvider<T> provider, ListenerCallback<T> listener)
      listen;

  WatchableRef({
    required this.watch,
    required this.listen,
    required super.read,
    required super.notify,
  });
}
