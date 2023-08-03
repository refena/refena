import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';

/// The base ref to read and notify providers.
/// These methods can be called anywhere.
class Ref {
  final T Function<T>(BaseProvider<T> provider) read;
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
  final T Function<T>(BaseProvider<T> provider) watch;

  WatchableRef({
    required this.watch,
    required super.read,
    required super.notify,
  });
}
