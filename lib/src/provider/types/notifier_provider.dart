import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// Use a [NotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class NotifierProvider<N extends BaseNotifier<T>, T>
    extends BaseNotifierProvider<N, T> {
  @internal
  final N Function(Ref ref) builder;

  NotifierProvider(this.builder, {super.debugLabel});

  @internal
  @override
  NotifierProviderState<N, T> createState(
    Ref ref,
    RiverpieObserver? observer,
  ) {
    final notifier = builder(ref);
    final state = NotifierProviderState<N, T>(notifier);

    // ignore: invalid_use_of_protected_member
    notifier.preInit(ref, observer);

    return state;
  }

  ProviderOverride<T> overrideWithNotifier(N Function() notifier) {
    return ProviderOverride(this, NotifierProviderState(notifier()));
  }
}
