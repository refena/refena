import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/types/async_notifier.dart';

/// The corresponding notifier for a [FutureProvider].
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
  set future(Future<T> value) {
    throw UnsupportedError('Cannot set future on FutureProviderNotifier');
  }

  @override
  String toString() {
    return debugLabel ?? 'FutureProviderNotifier<$T>';
  }
}
