import 'dart:async';

import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/proxy_ref.dart';

/// Instructs Refena to set a predefined state for a provider.
class ProviderOverride<N extends BaseNotifier<T>, T> {
  /// The reference to the provider.
  final BaseProvider<N, T> provider;

  /// The state of the provider.
  final FutureOr<N> Function(ProxyRef ref) createState;

  ProviderOverride({
    required this.provider,
    required this.createState,
  });
}
