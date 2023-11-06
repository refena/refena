import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/family_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';

/// A wrapper class to make [ref.watch] work with both
/// [BaseProvider] and [BaseProvider.select].
///
/// Implemented by providers (including family) and their selected versions.
abstract interface class BaseWatchable<N extends BaseNotifier<T>, T, R> {
  @internal
  BaseProvider<N, T> get provider;

  @internal
  R getSelectedState(N notifier, T state);
}

/// Implemented by providers (non-family) and their selected versions.
/// This differentiation is needed to disallow using [ViewModelBuilder]
/// on family providers.
abstract interface class Watchable<N extends BaseNotifier<T>, T, R>
    implements BaseWatchable<N, T, R> {}

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

/// A concrete implementation of [Watchable] that is used
/// when a param on a family is called.
final class FamilySelectedWatchable<T, P, R>
    implements BaseWatchable<FamilyNotifier<T, P>, T, R> {
  final BaseProvider<FamilyNotifier<T, P>, T> _provider;
  final R Function(T) _selector;

  /// The family parameter.
  final P param;

  FamilySelectedWatchable(this._provider, this.param, this._selector);

  @override
  BaseProvider<FamilyNotifier<T, P>, T> get provider => _provider;

  @override
  R getSelectedState(FamilyNotifier<T, P> notifier, T state) {
    return _selector(state);
  }

  /// A select statement on a family select.
  /// ref.read(provider(param).select(...))
  FamilySelectedWatchable<T, P, R2> select<R2>(
    R2 Function(R state) selector,
  ) {
    return FamilySelectedWatchable<T, P, R2>(provider, param, (state) {
      return selector(_selector(state));
    });
  }
}
