import 'package:meta/meta.dart';
import 'package:riverpie/src/async_value.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/ref.dart';

/// Use an [AsyncNotifierProvider] to implement a stateful provider.
/// Changes to the state are propagated to all consumers that
/// called [watch] on the provider.
class AsyncNotifierProvider<N extends AsyncNotifier<T>, T>
    extends BaseProvider<N, AsyncValue<T>>
    implements NotifyableProvider<N, AsyncValue<T>> {
  @internal
  final N Function(Ref ref) builder;

  AsyncNotifierProvider(this.builder, {super.debugLabel});

  @internal
  @override
  N createState(Ref ref) {
    return builder(ref);
  }

  ProviderOverride<N, AsyncValue<T>> overrideWithNotifier(
    N Function(Ref ref) builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => builder(ref),
    );
  }
}
