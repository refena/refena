import 'package:meta/meta.dart';
import 'package:riverpie/src/async_value.dart';
import 'package:riverpie/src/notifier/types/future_family_provider_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/watchable.dart';
import 'package:riverpie/src/ref.dart';

typedef FutureBuilder<T, P> = Future<T> Function(Ref ref, P param);

/// A [FutureFamilyProvider] is a special version of [FutureProvider] that
/// allows you to watch a collection of [Future]s.
class FutureFamilyProvider<T, P> extends BaseProvider<
    FutureFamilyProviderNotifier<T, P>, Map<P, AsyncValue<T>>> {
  FutureFamilyProvider(this.builder, {super.debugLabel});

  @internal
  final FutureBuilder<T, P> builder;

  @internal
  @override
  FutureFamilyProviderNotifier<T, P> createState(Ref ref) {
    return FutureFamilyProviderNotifier(builder,
        debugLabel: customDebugLabel ?? 'FutureFamilyProvider<$T>');
  }

  ProviderOverride<FutureFamilyProviderNotifier<T, P>, Map<P, AsyncValue<T>>>
      overrideWithNotifier(
    FutureBuilder<T, P> Function(Ref ref) builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => FutureFamilyProviderNotifier(
        builder(ref),
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }

  FutureFamilyProviderProxy<T, P> call(P param) {
    return FutureFamilyProviderProxy(this, param);
  }
}

/// A proxy class to make [WatchableRef.watch] work with [FutureFamilyProvider].
class FutureFamilyProviderProxy<T, P> extends FamilySelectedWatchable<
    FutureFamilyProviderNotifier<T, P>,
    Map<P, AsyncValue<T>>,
    P,
    AsyncValue<T>> {
  FutureFamilyProviderProxy(FutureFamilyProvider<T, P> provider, P param)
      : super(provider, param, (map) {
          return map[param] ?? AsyncValue<T>.loading();
        });

  FamilySelectedWatchable<
      FutureFamilyProviderNotifier<T, P>,
      Map<P, AsyncValue<T>>,
      P,
      R> select<R>(R Function(AsyncValue<T> state) selector) {
    return FamilySelectedWatchable(provider, param, (map) {
      return selector(map[param] ?? AsyncValue<T>.loading());
    });
  }
}
