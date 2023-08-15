import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/view_provider_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// The [ViewProvider] is the only provider that can watch other providers.
/// Its builder is similar to a normal [Provider].
/// A common use case is to define a view model that depends on many providers.
/// Don't worry about the [ref], you can use it freely inside any function.
/// The [ref] will never become invalid.
class ViewProvider<T> extends BaseNotifierProvider<ViewProviderNotifier<T>, T> {
  @internal
  final T Function(WatchableRef ref) builder;

  ViewProvider(this.builder, {super.debugLabel});

  @override
  NotifierProviderState<ViewProviderNotifier<T>, T> createState(
    Ref ref,
    RiverpieObserver? observer,
  ) {
    final notifier = ViewProviderNotifier<T>(
      builder,
      debugLabel: debugLabel ?? runtimeType.toString(),
    );
    final state = NotifierProviderState<ViewProviderNotifier<T>, T>(notifier);

    notifier.preInit(ref, observer);

    return state;
  }

  ProviderOverride<T> overrideWithBuilder(T Function(WatchableRef) builder) {
    return ProviderOverride(
      this,
      NotifierProviderState(
        ViewProviderNotifier(
          builder,
          debugLabel: debugLabel ?? runtimeType.toString(),
        ),
      ),
    );
  }
}
