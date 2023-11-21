import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/async_notifier_provider.dart';
import 'package:refena/src/provider/types/future_family_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// A [FutureProvider] is a custom implementation of a [AsyncNotifierProvider]
/// that allows you to watch a [Future].
///
/// The advantage over using a [FutureBuilder] (by Flutter) is that the
/// value is cached and only the first call to the [Future] is executed.
///
/// Usage:
/// final myProvider = FutureProvider((ref) async {
///   return await fetchApi();
/// }
///
/// Example use cases:
/// - fetch static data from an API (that does not change)
/// - fetch device information (that does not change)
class FutureProvider<T>
    extends BaseWatchableProvider<FutureProviderNotifier<T>, AsyncValue<T>>
    with ProviderSelectMixin<FutureProviderNotifier<T>, AsyncValue<T>> {
  FutureProvider(
    this._builder, {
    super.onChanged,
    String Function(AsyncValue<T> state)? describeState,
    String? debugLabel,
    super.debugVisibleInGraph = true,
  })  : _describeState = describeState,
        super(
          debugLabel: debugLabel ?? 'FutureProvider<$T>',
        );

  final Future<T> Function(WatchableRef ref) _builder;
  final String Function(AsyncValue<T> state)? _describeState;

  @internal
  @override
  FutureProviderNotifier<T> createState(ProxyRef ref) {
    return _createState(
      ref: ref,
      builder: _builder,
    );
  }

  /// Overrides the future.
  ///
  /// {@category Initialization}
  ProviderOverride<FutureProviderNotifier<T>, AsyncValue<T>> overrideWithFuture(
    Future<T> Function(Ref ref) builder,
  ) {
    return ProviderOverride<FutureProviderNotifier<T>, AsyncValue<T>>(
      provider: this,
      createState: (ref) => FutureProviderNotifier<T>(
        builder,
        describeState: _describeState,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }

  FutureProviderNotifier<T> _createState({
    required ProxyRef ref,
    required Future<T> Function(WatchableRef ref) builder,
  }) {
    return FutureProviderNotifier<T>(
      builder,
      describeState: _describeState,
      debugLabel: customDebugLabel ?? runtimeType.toString(),
    );
  }

  /// A shorthand for [FutureFamilyProvider].
  static FutureFamilyProvider<T, P> family<T, P>(
    FutureFamilyBuilder<T, P> future, {
    String Function(AsyncValue<T> state)? describeState,
    String? debugLabel,
  }) {
    return FutureFamilyProvider(
      future,
      describeState: describeState,
      debugLabel: debugLabel ?? 'FutureFamilyProvider<$T, $P>',
    );
  }
}
