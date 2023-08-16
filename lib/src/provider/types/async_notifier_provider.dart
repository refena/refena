import 'package:flutter/cupertino.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/ref.dart';
import 'package:riverpie/src/widget/scope.dart';

/// Use an [AsyncNotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class AsyncNotifierProvider<N extends AsyncNotifier<T>, T>
    extends BaseProvider<N, AsyncSnapshot<T>>
    implements NotifyableProvider<N, AsyncSnapshot<T>> {
  @internal
  final N Function(Ref ref) builder;

  AsyncNotifierProvider(this.builder, {super.debugLabel});

  @internal
  @override
  N createState(
    RiverpieScope scope,
    RiverpieObserver? observer,
  ) {
    return builder(scope);
  }

  ProviderOverride<N, AsyncSnapshot<T>> overrideWithNotifier(
    N Function() notifier,
  ) {
    return ProviderOverride(
      provider: this,
      state: notifier(),
    );
  }
}
