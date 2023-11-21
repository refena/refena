import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/provider_accessor.dart';
import 'package:refena/src/ref.dart';

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
/// [P] is the type of the **child** provider.
/// [N] is the type of the **child** notifier.
/// [T] is the type of the **child** notifier state.
/// [F] is the type of the family parameter.
/// [R] is the type of the selected state.
/// [B] is the builder return type.
///
/// [B] is used to add the [RebuildableProvider] interface.
/// It is assumed that all family providers are also rebuildable.
///
/// The complexity of this class is due to the fact that we need to
/// support [BaseWatchable], [RebuildableProvider] and [ProviderAccessor]
/// at the same time. So the user can use [WatchableRef.watch], [Ref.rebuild],
/// [Ref.future], and [Ref.stream] on the same object (via the [call] operator).
final class FamilySelectedWatchable<P extends BaseProvider<N, T>,
        N extends BaseNotifier<T>, T, F, R, B>
    implements
        BaseWatchable<FamilyNotifier<T, F, P>, Map<F, T>, R>,
        RebuildableProvider<RebuildableNotifier<Map<F, T>, B>, Map<F, T>, B>,
        ProviderAccessor<P, N, T> {
  final BaseProvider<FamilyNotifier<T, F, P>, Map<F, T>> _provider;
  final R Function(Map<F, T>) _selector;

  /// The family parameter.
  final F param;

  FamilySelectedWatchable(this._provider, this.param, this._selector);

  @override
  BaseProvider<FamilyNotifier<T, F, P>, Map<F, T>> get provider => _provider;

  @override
  R getSelectedState(FamilyNotifier<T, F, P> notifier, Map<F, T> state) {
    return _selector(state);
  }

  /// A select statement on a family select.
  /// ref.read(provider(param).select(...))
  ///
  /// [R2] is the new type of the selected state.
  FamilySelectedWatchable<P, N, T, F, R2, B> select<R2>(
    R2 Function(R state) selector,
  ) {
    return FamilySelectedWatchable<P, N, T, F, R2, B>(_provider, param,
        (state) {
      return selector(_selector(state));
    });
  }

  @override
  P getActualProvider(BaseNotifier<Object?> notifier) {
    return (notifier as FamilyNotifier<T, F, P>).getProviderMap()[param]!;
  }
}
