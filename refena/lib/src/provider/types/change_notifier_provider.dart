import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/types/change_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// Use a [NotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class ChangeNotifierProvider<N extends ChangeNotifier>
    extends BaseProvider<N, void>
    implements NotifyableProvider<N, void>, Watchable<N, void, N> {
  ChangeNotifierProvider(
    this._builder, {
    void Function(Ref)? onChanged,
    super.debugLabel,
  }) : super(
          onChanged: onChanged == null ? null : (_, __, ref) => onChanged(ref),
        );

  final N Function(Ref ref) _builder;

  @internal
  @override
  N createState(ProxyRef ref) {
    return _build(ref, _builder);
  }

  @override
  BaseProvider<N, void> get provider => this;

  /// The default behavior to return the notifier when
  /// using `ref.watch(provider)`.
  @override
  N getSelectedState(N notifier, void state) => notifier;

  /// Overrides with a predefined notifier.
  ///
  /// {@category Initialization}
  ProviderOverride<N, void> overrideWithNotifier(N Function(Ref ref) builder) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => _build(ref, builder),
    );
  }
}

/// Builds the notifier and also registers the dependencies.
N _build<N extends ChangeNotifier>(
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
