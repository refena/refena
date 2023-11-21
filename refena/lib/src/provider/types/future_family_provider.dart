import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/future_provider.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/ref.dart';

typedef FutureFamilyBuilder<T, P> = Future<T> Function(
  WatchableRef ref,
  P param,
);

/// A [FutureFamilyProvider] is a special version of [FutureProvider] that
/// allows you to watch a collection of [Future]s.
class FutureFamilyProvider<T, P> extends BaseProvider<
    FamilyNotifier<AsyncValue<T>, P, FutureProvider<T>>,
    Map<P, AsyncValue<T>>> {
  FutureFamilyProvider(
    this._builder, {
    super.onChanged,
    String Function(AsyncValue<T> state)? describeState,
    String? debugLabel,
    super.debugVisibleInGraph = true,
  })  : _describeState = describeState,
        super(debugLabel: debugLabel ?? 'FutureFamilyProvider<$T, $P>');

  final FutureFamilyBuilder<T, P> _builder;

  final String Function(AsyncValue<T> state)? _describeState;

  @internal
  @override
  FamilyNotifier<AsyncValue<T>, P, FutureProvider<T>> createState(Ref ref) {
    return _buildFamilyNotifier(this, _builder, _describeState);
  }

  /// Overrides the future builder.
  ///
  /// {@category Initialization}
  ProviderOverride<FamilyNotifier<AsyncValue<T>, P, FutureProvider<T>>,
      Map<P, AsyncValue<T>>> overrideWithFutureBuilder(
    FutureFamilyBuilder<T, P> builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => _buildFamilyNotifier(this, builder, _describeState),
    );
  }

  /// Provide accessor for one parameter.
  FamilySelectedWatchable<
      FutureFamilyProvider<T, P>,
      FutureProvider<T>,
      FamilyNotifier<AsyncValue<T>, P, FutureProvider<T>>,
      FutureProviderNotifier<T>,
      AsyncValue<T>,
      P,
      AsyncValue<T>,
      Future<T>> call(
    P param,
  ) {
    return FamilySelectedWatchable(this, param, (map) => map[param]!);
  }
}

FamilyNotifier<AsyncValue<T>, P, FutureProvider<T>> _buildFamilyNotifier<T, P>(
  FutureFamilyProvider<T, P> provider,
  FutureFamilyBuilder<T, P> builder,
  String Function(AsyncValue<T> state)? describeState,
) {
  return FamilyNotifier<AsyncValue<T>, P, FutureProvider<T>>(
    (param) => FutureProvider<T>(
      (ref) => builder(ref, param),
      debugLabel: '${provider.debugLabel}($param)',
    ),
    describeState: describeState,
    debugLabel: provider.debugLabel,
  );
}
