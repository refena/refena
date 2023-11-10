import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/types/future_provider_notifier.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/async_notifier_provider.dart';
import 'package:refena/src/provider/types/future_family_provider.dart';
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
  final String Function(AsyncValue<T> state)? _describeState;

  FutureProvider(
    Future<T> Function(Ref ref) builder, {
    super.onChanged,
    String Function(AsyncValue<T> state)? describeState,
    String? debugLabel,
  })  : _describeState = describeState,
        super(
          (ref) => FutureProviderNotifier<T>(
            builder(ref),
            describeState: describeState,
            debugLabel: debugLabel ?? 'FutureProvider<$T>',
          ),
          debugLabel: debugLabel ?? 'FutureProvider<$T>',
        );

  /// Overrides the future.
  ///
  /// {@category Initialization}
  ProviderOverride<FutureProviderNotifier<T>, AsyncValue<T>> overrideWithFuture(
    Future<T> Function(Ref ref) builder,
  ) {
    return ProviderOverride<FutureProviderNotifier<T>, AsyncValue<T>>(
      provider: this,
      createState: (ref) => FutureProviderNotifier<T>(
        builder(ref),
        describeState: _describeState,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }

  /// A shorthand for [FutureFamilyProvider].
  static FutureFamilyProvider<T, P> family<T, P>(
    FutureBuilder<T, P> future, {
    String Function(AsyncValue<T> state)? describeState,
    String? debugLabel,
  }) {
    return FutureFamilyProvider(
      future,
      describeState: describeState,
      debugLabel: debugLabel ?? 'FutureFamilyProvider<$T, $P>',
    );
  }
}
