import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/stream_family_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// A provider that listens to a [Stream] and exposes its latest value.
///
/// Set [describeState] to customize the description of the state.
/// See [BaseNotifier.describeState].
///
/// Set [debugLabel] to customize the debug label of the provider.
class StreamProvider<T> extends BaseWatchableProvider<StreamProvider<T>,
        StreamProviderNotifier<T>, AsyncValue<T>>
    with
        ProviderSelectMixin<StreamProvider<T>, StreamProviderNotifier<T>,
            AsyncValue<T>>
    implements
        RebuildableProvider<StreamProviderNotifier<T>, AsyncValue<T>,
            Stream<T>> {
  final Stream<T> Function(WatchableRef ref) _builder;
  final String Function(AsyncValue<T> state)? _describeState;

  StreamProvider(
    this._builder, {
    super.onChanged,
    String Function(AsyncValue<T> state)? describeState,
    super.debugLabel,
    super.debugVisibleInGraph = true,
  }) : _describeState = describeState;

  @internal
  @override
  StreamProviderNotifier<T> createState(ProxyRef ref) {
    return _build(
      builder: _builder,
      describeState: _describeState,
      debugLabel: customDebugLabel ?? runtimeType.toString(),
    );
  }

  @override
  String get debugLabel => customDebugLabel ?? runtimeType.toString();

  /// Overrides the stream.
  ///
  /// {@category Initialization}
  ProviderOverride<StreamProviderNotifier<T>, AsyncValue<T>> overrideWithStream(
    Stream<T> Function(Ref ref) builder,
  ) {
    return ProviderOverride<StreamProviderNotifier<T>, AsyncValue<T>>(
      provider: this,
      createState: (ref) => _build(
        builder: builder,
        describeState: _describeState,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }

  /// A shorthand for [StreamFamilyProvider].
  static StreamFamilyProvider<T, P> family<T, P>(
    StreamFamilyBuilder<T, P> stream, {
    String Function(AsyncValue<T> state)? describeState,
    String? debugLabel,
  }) {
    return StreamFamilyProvider(
      stream,
      describeState: describeState,
      debugLabel: debugLabel ?? 'StreamFamilyProvider<$T, $P>',
    );
  }
}

/// Builds the notifier and also registers the dependencies.
StreamProviderNotifier<T> _build<T>({
  required Stream<T> Function(WatchableRef ref) builder,
  required String Function(AsyncValue<T> state)? describeState,
  required String debugLabel,
}) {
  return StreamProviderNotifier(
    builder,
    describeState: describeState,
    debugLabel: debugLabel,
  );
}
