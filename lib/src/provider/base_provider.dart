import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// A "provider" instructs Riverpie how to create a state.
/// A "provider" is stateless.
///
/// You may add a [debugLabel] for better logging.
abstract class BaseProvider<T> {
  final String? debugLabel;

  BaseProvider({this.debugLabel});

  @internal
  BaseProviderState<T> createState(
    Ref ref,
    RiverpieObserver? observer,
  );
}

/// A provider that holds a [BaseNotifier].
/// Only notifiers are able to add listeners.
abstract class BaseNotifierProvider<N extends BaseNotifier<T>, T>
    extends BaseProvider<T> {
  BaseNotifierProvider({super.debugLabel});

  @internal
  @override
  NotifierProviderState<N, T> createState(
    Ref ref,
    RiverpieObserver? observer,
  );
}

/// A provider that can be awaited on.
/// This is just a flag as the provider does not hold any state.
abstract class AwaitableProvider<T> {}
