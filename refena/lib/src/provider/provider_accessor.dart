import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';

/// Provides access to a provider.
/// This abstraction is needed to allow family providers and
/// non-family providers to be used in the same way.
///
/// [P] is the type of the **child** provider.
/// [N] is the type of the **child** notifier.
/// [T] is the type of the **child** notifier state.
///
/// For non-family providers, [provider] is [P].
@internal
abstract interface class ProviderAccessor<P extends BaseProvider<N, T>,
    N extends BaseNotifier<T>, T> {
  BaseProvider<BaseNotifier<Object?>, Object?> get provider;

  P getActualProvider(BaseNotifier<Object?> notifier);
}
