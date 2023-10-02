import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// Holds a [ReduxNotifier]
class ReduxProvider<N extends BaseReduxNotifier<T>, T>
    extends BaseWatchableProvider<N, T>
    with ProviderSelectMixin<N, T>
    implements NotifyableProvider<N, T> {
  @internal
  final N Function(Ref ref) builder;

  ReduxProvider(this.builder, {super.debugLabel});

  @internal
  @override
  N createState(ProxyRef ref) {
    return _build(ref, builder);
  }

  ProviderOverride<N, T> overrideWithNotifier(N Function(Ref ref) builder) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => _build(ref, builder),
    );
  }
}

/// Builds the notifier and also registers the dependencies.
N _build<N extends BaseReduxNotifier<T>, T>(
  ProxyRef ref,
  N Function(Ref ref) builder,
) {
  final dependencies = <BaseNotifier>{};

  final notifier = ref.trackNotifier(
    onAccess: (notifier) => dependencies.add(notifier),
    run: () => builder(ref),
  );

  notifier.dependencies.addAll(dependencies);
  for (final dependency in dependencies) {
    dependency.dependents.add(notifier);
  }

  return notifier;
}
