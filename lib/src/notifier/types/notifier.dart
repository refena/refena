import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';

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

  Notifier({String? debugLabel}) : super(debugLabel: debugLabel);

  @internal
  @override
  void preInit(Ref ref, RiverpieObserver? observer) {
    _ref = ref;
    super.preInit(ref, observer);
  }
}
