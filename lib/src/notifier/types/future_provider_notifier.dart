import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';

@internal
class FutureProviderNotifier<T> extends AsyncNotifier<T> {
  final Future<T> _future;

  FutureProviderNotifier(this._future, {super.debugLabel});

  @override
  Future<T> init() {
    return _future;
  }

  @internal
  @override
  void preInit(Ref ref, RiverpieObserver? observer) {
    super.preInit(ref, observer);
  }
}
