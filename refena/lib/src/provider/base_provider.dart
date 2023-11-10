import 'package:meta/meta.dart';
import 'package:refena/src/container.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/provider_changed_callback.dart';
import 'package:refena/src/provider/types/change_notifier_provider.dart';
import 'package:refena/src/provider/types/future_family_provider.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';
import 'package:refena/src/reference.dart';

/// A "provider" instructs Refena how to create a state.
/// A "provider" is stateless.
///
/// You may add a [debugLabel] for better logging.
abstract class BaseProvider<N extends BaseNotifier<T>, T>
    implements LabeledReference {
  final String? customDebugLabel;
  final ProviderChangedCallback<T>? _onChanged;

  @override
  String get debugLabel => customDebugLabel ?? N.toString();

  BaseProvider({
    required ProviderChangedCallback<T>? onChanged,
    required String? debugLabel,
  })  : _onChanged = onChanged,
        customDebugLabel = debugLabel;

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

  /// Subclasses should not override this method.
  /// It is used internally by [RefenaContainer] to map a provider to a state.
  @override
  @nonVirtual
  bool operator ==(Object other) => identical(this, other);

  @override
  @nonVirtual
  int get hashCode => super.hashCode;
}

@internal
extension InternalBaseProviderExt<T> on BaseProvider<BaseNotifier<T>, T> {
  ProviderChangedCallback<T>? get onChanged => _onChanged;
}

/// A provider with default behaviour for [WatchableRef.watch].
/// Inherited by all providers except for
/// [ChangeNotifierProvider] and [FutureFamilyProvider].
abstract class BaseWatchableProvider<N extends BaseNotifier<T>, T>
    extends BaseProvider<N, T> implements Watchable<N, T, T> {
  BaseWatchableProvider({
    required super.onChanged,
    super.debugLabel,
  });

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
/// You may get around this in your tests with RefenaContainer.anyNotifier().
abstract interface class NotifyableProvider<N extends BaseNotifier<T>, T> {}
