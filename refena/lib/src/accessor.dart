import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/ref.dart';

/// Provides access to the latest state of a provider.
///
/// {@category Dependency Injection}
class StateAccessor<R> {
  final Ref ref;
  final BaseWatchable<BaseNotifier, dynamic, R> provider;

  const StateAccessor({
    required this.ref,
    required this.provider,
  });

  /// Returns the latest state of the provider.
  R get state => ref.read<BaseNotifier, dynamic, R>(provider);
}
