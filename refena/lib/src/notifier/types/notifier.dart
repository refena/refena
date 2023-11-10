import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/proxy_ref.dart';
import 'package:refena/src/ref.dart';

/// A notifier holds a state and notifies its listeners when the state changes.
/// The listeners are added automatically when calling [ref.watch].
///
/// Be aware that notifiers are never disposed.
/// If you hold a lot of data in the state,
/// you should consider implement a "reset" logic.
///
/// This [Notifier] has access to [ref] for fast development.
abstract class Notifier<T> extends BaseSyncNotifier<T> {
  late Ref _ref;

  @protected
  Ref get ref => _ref;

  Notifier({super.debugLabel});

  @internal
  @override
  void internalSetup(
    ProxyRef ref,
    BaseProvider<BaseNotifier<T>, T>? provider,
  ) {
    _ref = ref;
    super.internalSetup(ref, provider);
  }

  /// Returns a debug version of the [notifier] where
  /// you can set the state directly.
  static NotifierTester<N, T> test<N extends BaseSyncNotifier<T>, T>({
    required N notifier,
    T? initialState,
  }) {
    return NotifierTester(
      notifier: notifier,
      initialState: initialState,
    );
  }
}
