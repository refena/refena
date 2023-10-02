import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';

/// A wrapper class to make [ref.watch] work with both
/// [BaseProvider] and [BaseProvider.select].
abstract class Watchable<N extends BaseNotifier<T>, T, R> {
  @internal
  BaseProvider<N, T> get provider;

  @internal
  R getSelectedState(N notifier, T state);
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
  R getSelectedState(N notifier, T state) => _selector(state);
}

/// Additionally to [SelectedWatchable], this class holds a [param]
/// that is passed to the selector function.
class FamilySelectedWatchable<N extends BaseNotifier<T>, T, P, R>
    extends SelectedWatchable<N, T, R> {
  FamilySelectedWatchable(super._provider, this.param, super._selector);

  /// The family parameter.
  final P param;
}
