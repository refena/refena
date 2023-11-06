import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/types/future_family_provider_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/ref.dart';

typedef FutureBuilder<T, P> = Future<T> Function(Ref ref, P param);

/// A [FutureFamilyProvider] is a special version of [FutureProvider] that
/// allows you to watch a collection of [Future]s.
class FutureFamilyProvider<T, P> extends BaseProvider<
    FutureFamilyProviderNotifier<T, P>, Map<P, AsyncValue<T>>> {
  FutureFamilyProvider(
    this._builder, {
    String Function(AsyncValue<T> state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  final FutureBuilder<T, P> _builder;

  final String Function(AsyncValue<T> state)? _describeState;

  @internal
  @override
  FutureFamilyProviderNotifier<T, P> createState(Ref ref) {
    return FutureFamilyProviderNotifier(
      _builder,
      describeState: _describeState,
      debugLabel: customDebugLabel ?? 'FutureFamilyProvider<$T, $P>',
    );
  }

  /// Overrides the future builder.
  ///
  /// {@category Initialization}
  ProviderOverride<FutureFamilyProviderNotifier<T, P>, Map<P, AsyncValue<T>>>
      overrideWithFutureBuilder(
    FutureBuilder<T, P> Function(Ref ref) builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => FutureFamilyProviderNotifier(
        builder(ref),
        describeState: _describeState,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }

  /// Provide accessor for one parameter.
  FamilySelectedWatchable<Map<P, AsyncValue<T>>, P, AsyncValue<T>> call(
    P param,
  ) {
    return FamilySelectedWatchable(this, param, (map) => map[param]!);
  }
}
