import 'package:riverpie/src/provider/base_provider.dart';
import 'package:riverpie/src/provider/state.dart';

/// Instructs Riverpie to set a predefined state for a provider.
class ProviderOverride<T> {
  /// The reference to the provider.
  final BaseProvider<T> provider;

  /// The state of the provider.
  final BaseProviderState<T> state;

  ProviderOverride(this.provider, this.state);
}
