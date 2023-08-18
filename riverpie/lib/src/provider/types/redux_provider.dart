import 'package:meta/meta.dart';
import 'package:riverpie/riverpie.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/override.dart';

/// Holds a [ReduxNotifier]
class ReduxProvider<N extends BaseReduxNotifier<T, E>, T, E extends Object>
    extends BaseProvider<N, T> {
  @internal
  final N Function(Ref ref) builder;

  ReduxProvider(this.builder, {super.debugLabel});

  @internal
  @override
  N createState(Ref ref) {
    return builder(ref);
  }

  ProviderOverride<N, T> overrideWithNotifier(N Function(Ref ref) builder) {
    return ProviderOverride(
      provider: this,
      createState: (ref) => builder(ref),
    );
  }
}
