import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/provider/watchable.dart';
import 'package:riverpie/src/ref.dart';

/// A "provider" instructs Riverpie how to create a state.
/// A "provider" is stateless.
///
/// You may add a [debugLabel] for better logging.
abstract class BaseProvider<N extends BaseNotifier<T>, T>
    implements Watchable<N, T, T> {
  final String? debugLabel;

  BaseProvider({this.debugLabel});

  @internal
  N createState(Ref ref);

  @override
  String toString() {
    return debugLabel ?? runtimeType.toString();
  }

  @override
  BaseProvider<N, T> get provider => this;

  /// The default behavior to return the whole state when
  /// using `ref.watch(provider)`.
  @override
  T getSelectedState(T state) => state;

  /// Used for ref.watch(provider.select(...)).
  /// Select a part of the state.
  SelectedWatchable<N, T, R> select<R>(R Function(T state) selector) {
    return SelectedWatchable(this, selector);
  }
}

/// A flag to indicate that the notifier is accessible from [Ref].
/// Every [NotifyableProvider] is a [BaseProvider] although not
/// visible in the type hierarchy.
abstract class NotifyableProvider<N extends BaseNotifier<T>, T> {}
