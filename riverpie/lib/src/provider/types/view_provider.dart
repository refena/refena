import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/view_provider_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';
import 'package:riverpie/src/ref.dart';

/// The [ViewProvider] is the only provider that can watch other providers.
/// Its builder is similar to a normal [Provider].
/// A common use case is to define a view model that depends on many providers.
/// Don't worry about the [ref], you can use it freely inside any function.
/// The [ref] will never become invalid.
class ViewProvider<T> extends BaseProvider<ViewProviderNotifier<T>, T> {
  @internal
  final T Function(WatchableRef ref) builder;

  ViewProvider(this.builder, {super.debugLabel});

  @override
  ViewProviderNotifier<T> createState(Ref ref) {
    return ViewProviderNotifier<T>(
      builder,
      debugLabel: debugLabel ?? runtimeType.toString(),
    );
  }

  ProviderOverride<ViewProviderNotifier<T>, T> overrideWithBuilder(
      T Function(WatchableRef) builder) {
    return ProviderOverride(
      provider: this,
      createState: (_) => ViewProviderNotifier(
        builder,
        debugLabel: debugLabel ?? runtimeType.toString(),
      ),
    );
  }
}
