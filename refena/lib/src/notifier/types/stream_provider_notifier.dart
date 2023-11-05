import 'dart:async';

import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/base_notifier.dart';

/// The corresponding notifier of a [StreamProvider].
final class StreamProviderNotifier<T> extends BaseSyncNotifier<AsyncValue<T>> {
  final Stream<T> _stream;
  final String Function(AsyncValue<T> state)? _describeState;
  late StreamSubscription<T> _subscription;

  StreamProviderNotifier(
    this._stream, {
    String Function(AsyncValue<T> state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

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

  @override
  String describeState(AsyncValue<T> state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }
}
