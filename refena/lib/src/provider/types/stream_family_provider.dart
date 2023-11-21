import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/stream_provider.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/ref.dart';

typedef StreamFamilyBuilder<T, P> = Stream<T> Function(
  WatchableRef ref,
  P param,
);

/// A [StreamFamilyProvider] is a special version of [StreamProvider] that
/// allows you to watch a collection of [Stream]s.
class StreamFamilyProvider<T, P> extends BaseProvider<
    FamilyNotifier<AsyncValue<T>, P, StreamProvider<T>>,
    Map<P, AsyncValue<T>>> {
  StreamFamilyProvider(
    this._builder, {
    super.onChanged,
    String Function(AsyncValue<T> state)? describeState,
    String? debugLabel,
    super.debugVisibleInGraph = true,
  })  : _describeState = describeState,
        super(debugLabel: debugLabel ?? 'StreamFamilyProvider<$T, $P>');

  final StreamFamilyBuilder<T, P> _builder;

  final String Function(AsyncValue<T> state)? _describeState;

  @internal
  @override
  FamilyNotifier<AsyncValue<T>, P, StreamProvider<T>> createState(Ref ref) {
    return _buildFamilyNotifier(this, _builder, _describeState);
  }

  /// Overrides the stream builder.
  ///
  /// {@category Initialization}
  ProviderOverride<FamilyNotifier<AsyncValue<T>, P, StreamProvider<T>>,
      Map<P, AsyncValue<T>>> overrideWithStreamBuilder(
    StreamFamilyBuilder<T, P> builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => _buildFamilyNotifier(this, builder, _describeState),
    );
  }

  /// Provide accessor for one parameter.
  FamilySelectedWatchable<StreamProvider<T>, StreamProviderNotifier<T>,
      AsyncValue<T>, P, AsyncValue<T>, Stream<T>> call(
    P param,
  ) {
    return FamilySelectedWatchable(this, param, (map) => map[param]!);
  }
}

FamilyNotifier<AsyncValue<T>, P, StreamProvider<T>> _buildFamilyNotifier<T, P>(
  StreamFamilyProvider<T, P> provider,
  StreamFamilyBuilder<T, P> builder,
  String Function(AsyncValue<T> state)? describeState,
) {
  return FamilyNotifier<AsyncValue<T>, P, StreamProvider<T>>(
    (param) => StreamProvider<T>(
      (ref) => builder(ref, param),
      debugLabel: '${provider.debugLabel}($param)',
    ),
    describeState: describeState,
    debugLabel: provider.debugLabel,
  );
}
