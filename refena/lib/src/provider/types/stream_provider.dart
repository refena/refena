import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/types/stream_provider_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// A provider that listens to a [Stream] and exposes its latest value.
///
/// Set [describeState] to customize the description of the state.
/// See [BaseNotifier.describeState].
///
/// Set [debugLabel] to customize the debug label of the provider.
class StreamProvider<T>
    extends BaseWatchableProvider<StreamProviderNotifier<T>, AsyncValue<T>>
    with ProviderSelectMixin<StreamProviderNotifier<T>, AsyncValue<T>> {
  final Stream<T> Function(Ref ref) _builder;
  final String Function(AsyncValue<T> state)? _describeState;

  StreamProvider(
    this._builder, {
    String Function(AsyncValue<T> state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  @internal
  @override
  StreamProviderNotifier<T> createState(ProxyRef ref) {
    return _build(
      ref: ref,
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
        ref: ref,
        builder: builder,
        describeState: _describeState,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }
}

/// Builds the notifier and also registers the dependencies.
StreamProviderNotifier<T> _build<T>({
  required ProxyRef ref,
  required Stream<T> Function(Ref ref) builder,
  required String Function(AsyncValue<T> state)? describeState,
  required String debugLabel,
}) {
  final dependencies = <BaseNotifier>{};

  final notifier = ref.trackNotifier(
    onAccess: (notifier) => dependencies.add(notifier),
    run: () => StreamProviderNotifier(
      builder(ref),
      describeState: describeState,
      debugLabel: debugLabel,
    ),
  );

  notifier.dependencies.addAll(dependencies);
  for (final dependency in dependencies) {
    dependency.dependents.add(notifier);
  }

  return notifier;
}
