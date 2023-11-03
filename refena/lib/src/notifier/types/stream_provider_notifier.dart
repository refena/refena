import 'dart:async';

import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';

/// The corresponding notifier of a [StreamProvider].
final class StreamProviderNotifier<T> extends BaseSyncNotifier<AsyncValue<T>> {
  final Stream<T> _stream;
  late StreamSubscription<T> _subscription;

  StreamProviderNotifier(this._stream, {super.debugLabel});

  @override
  AsyncValue<T> init() {
    _subscription = _stream.listen((value) {
      state = AsyncValue<T>.data(value);
    }, onError: (error, stackTrace) {
      state = AsyncValue<T>.error(error, stackTrace);
    });
    return AsyncValue<T>.loading();
  }

  /// Waits for the next value of the stream.
  Future<T> get next => _stream.first;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
