import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/types/stream_provider_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// A provider that listens to a [Stream] and exposes its latest value.
class StreamProvider<T>
    extends BaseWatchableProvider<StreamProviderNotifier<T>, AsyncValue<T>>
    with ProviderSelectMixin<StreamProviderNotifier<T>, AsyncValue<T>> {
  final Stream<T> Function(Ref ref) _builder;

  StreamProvider(this._builder, {super.debugLabel});

  @internal
  @override
  StreamProviderNotifier<T> createState(ProxyRef ref) {
    return _build(
      ref: ref,
      builder: _builder,
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
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }
}

/// Builds the notifier and also registers the dependencies.
StreamProviderNotifier<T> _build<T>({
  required ProxyRef ref,
  required Stream<T> Function(Ref ref) builder,
  required String debugLabel,
}) {
  final dependencies = <BaseNotifier>{};

  final notifier = ref.trackNotifier(
    onAccess: (notifier) => dependencies.add(notifier),
    run: () => StreamProviderNotifier(builder(ref), debugLabel: debugLabel),
  );

  notifier.dependencies.addAll(dependencies);
  for (final dependency in dependencies) {
    dependency.dependents.add(notifier);
  }

  return notifier;
}
