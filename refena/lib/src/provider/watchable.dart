import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/provider_accessor.dart';

/// A wrapper class to make [ref.watch] work with both
/// [BaseProvider] and [BaseProvider.select].
///
/// [T] is the type of the notifier state.
/// [R] is the type of the selected state.
/// [N] is the type of the notifier itself.
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
///
/// [F] is the type of the family parameter.
/// [B] is the builder return type.
/// [R] is the type of the selected state.
/// [T] is the type of **one** element of the family.
final class FamilySelectedWatchable<
        P extends BaseProvider<N, Map<F, T>>,
        P2 extends BaseProvider<N2, T>,
        N extends FamilyNotifier<T, F, P2>,
        N2 extends BaseNotifier<T>,
        T,
        F,
        R,
        B>
    implements
        BaseWatchable<FamilyNotifier<T, F, P2>, Map<F, T>, R>,
        RebuildableProvider<RebuildableNotifier<Map<F, T>, B>, Map<F, T>, B>,
        ProviderAccessor<P2, N2, T> {
  final P _provider;
  final R Function(Map<F, T>) _selector;

  /// The family parameter.
  final F param;

  FamilySelectedWatchable(this._provider, this.param, this._selector);

  @override
  P get provider => _provider;

  @override
  R getSelectedState(FamilyNotifier<T, F, P2> notifier, Map<F, T> state) {
    return _selector(state);
  }

  /// A select statement on a family select.
  /// ref.read(provider(param).select(...))
  FamilySelectedWatchable<P, P2, N, N2, T, F, R2, B> select<R2>(
    R2 Function(R state) selector,
  ) {
    return FamilySelectedWatchable<P, P2, N, N2, T, F, R2, B>(_provider, param,
        (state) {
      return selector(_selector(state));
    });
  }

  @override
  P2 getActualProvider(BaseNotifier<Object?> notifier) {
    return (notifier as FamilyNotifier<T, F, P2>).getProviderMap()[param]!;
  }
}
