import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/provider/base_provider.dart';

/// Instructs Riverpie to set a predefined state for a provider.
class ProviderOverride<N extends BaseNotifier<T>, T> {
  /// The reference to the provider.
  final BaseProvider<N, T> provider;

  /// The state of the provider.
  final N state;

  ProviderOverride({
    required this.provider,
    required this.state,
  });
}
