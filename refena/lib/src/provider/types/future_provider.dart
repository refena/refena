import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/types/future_provider_notifier.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/async_notifier_provider.dart';
import 'package:refena/src/ref.dart';

/// A [FutureProvider] is a custom implementation of a [AsyncNotifierProvider]
/// that allows you to watch a [Future].
///
/// The advantage over using a [FutureBuilder] is that the
/// value is cached and only the first call to the [Future] is executed.
///
/// Usage:
/// final myProvider = FutureProvider((ref) async {
///   return await fetchApi();
/// }
///
/// Example use cases:
/// - fetch static data from an API (that does not change)
/// - fetch device information (that does not change)
class FutureProvider<T>
    extends AsyncNotifierProvider<FutureProviderNotifier<T>, T> {
  FutureProvider(Future<T> Function(Ref ref) builder, {String? debugLabel})
      : super(
          (ref) => FutureProviderNotifier<T>(
            builder(ref),
            debugLabel: debugLabel ?? 'FutureProvider<$T>',
          ),
          debugLabel: debugLabel ?? 'FutureProvider<$T>',
        );

  ProviderOverride<FutureProviderNotifier<T>, AsyncValue<T>> overrideWithFuture(
    Future<T> Function(Ref ref) builder,
  ) {
    return ProviderOverride<FutureProviderNotifier<T>, AsyncValue<T>>(
      provider: this,
      createState: (ref) => FutureProviderNotifier<T>(
        builder(ref),
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }
}