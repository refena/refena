import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';

/// A wrapper class to make [ref.watch] work with both
/// [BaseProvider] and [BaseProvider.select].
abstract class Watchable<N extends BaseNotifier<T>, T, R> {
  @internal
  BaseProvider<N, T> get provider;

  @internal
  R getSelectedState(T state);
}

/// A concrete implementation of [Watchable] that is used
/// when [BaseProvider.select] is called.
class SelectedWatchable<N extends BaseNotifier<T>, T, R>
    implements Watchable<N, T, R> {
  final BaseProvider<N, T> _provider;
  final R Function(T) _selector;

  SelectedWatchable(this._provider, this._selector);

  @override
  BaseProvider<N, T> get provider => _provider;

  @override
  R getSelectedState(T state) => _selector(state);
}
