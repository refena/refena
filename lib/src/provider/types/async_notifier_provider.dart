import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// Use an [AsyncNotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class AsyncNotifierProvider<N extends AsyncNotifier<T>, T>
    extends BaseNotifierProvider<N, AsyncSnapshot<T>>
    implements AwaitableProvider<T> {
  @internal
  final N Function(Ref ref) builder;

  AsyncNotifierProvider(this.builder, {super.debugLabel});

  @internal
  @override
  NotifierProviderState<N, AsyncSnapshot<T>> createState(
    Ref ref,
    RiverpieObserver? observer,
  ) {
    final notifier = builder(ref);
    final state = NotifierProviderState<N, AsyncSnapshot<T>>(notifier);

    // ignore: invalid_use_of_protected_member
    notifier.preInit(ref, observer);

    return state;
  }

  ProviderOverride<AsyncSnapshot<T>> overrideWithNotifier(
    N Function() notifier,
  ) {
    return ProviderOverride(this, NotifierProviderState(notifier()));
  }
}
