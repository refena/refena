import 'package:meta/meta.dart';
import 'package:riverpie/src/labeled_reference.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/provider/types/change_notifier_provider.dart';
import 'package:riverpie/src/provider/types/future_family_provider.dart';
import 'package:riverpie/src/provider/watchable.dart';
import 'package:riverpie/src/proxy_ref.dart';
import 'package:riverpie/src/ref.dart';

/// A "provider" instructs Riverpie how to create a state.
/// A "provider" is stateless.
///
/// You may add a [debugLabel] for better logging.
abstract class BaseProvider<N extends BaseNotifier<T>, T>
    with LabeledReference {
  final String? customDebugLabel;

  @override
  String get debugLabel => customDebugLabel ?? N.toString();

  BaseProvider({String? debugLabel}) : customDebugLabel = debugLabel;

  @internal
  N createState(ProxyRef ref);

  @override
  String toString() {
    final type = runtimeType.toString();
    if (type == debugLabel) {
      return type;
    }
    return '$type(label: $debugLabel)';
  }
}

/// A provider with default behaviour for [WatchableRef.watch].
/// Inherited by all providers except for
/// [ChangeNotifierProvider] and [FutureFamilyProvider].
abstract class BaseWatchableProvider<N extends BaseNotifier<T>, T>
    extends BaseProvider<N, T> implements Watchable<N, T, T> {
  BaseWatchableProvider({super.debugLabel});

  @override
  BaseProvider<N, T> get provider => this;

  /// The default behavior to return the whole state when
  /// using `ref.watch(provider)`.
  @override
  T getSelectedState(N notifier, T state) => state;
}

mixin ProviderSelectMixin<N extends BaseNotifier<T>, T>
    on BaseWatchableProvider<N, T> {
  /// Used for ref.watch(provider.select(...)).
  /// Select a part of the state.
  SelectedWatchable<N, T, R> select<R>(R Function(T state) selector) {
    return SelectedWatchable(this, selector);
  }
}

/// A flag to indicate that the notifier is accessible from [Ref].
/// Every [NotifyableProvider] is a [BaseProvider] although not
/// visible in the type hierarchy.
///
/// This restriction is used to discourage direct access to the notifier.
/// You may get around this in your tests with RiverpieContainer.anyNotifier().
abstract interface class NotifyableProvider<N extends BaseNotifier<T>, T> {}
