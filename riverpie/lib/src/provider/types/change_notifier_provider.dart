import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/change_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/watchable.dart';
import 'package:riverpie/src/ref.dart';

/// Use a [NotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class ChangeNotifierProvider<N extends ChangeNotifier>
    extends BaseProvider<N, void>
    implements NotifyableProvider<N, void>, Watchable<N, void, N> {
  ChangeNotifierProvider(this.builder, {super.debugLabel});

  @internal
  final N Function(Ref ref) builder;

  @internal
  @override
  N createState(Ref ref) {
    return builder(ref);
  }

  @override
  BaseProvider<N, void> get provider => this;

  /// The default behavior to return the notifier when
  /// using `ref.watch(provider)`.
  @override
  N getSelectedState(N notifier, void state) => notifier;

  ProviderOverride<N, void> overrideWithNotifier(N Function(Ref ref) builder) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => builder(ref),
    );
  }
}
