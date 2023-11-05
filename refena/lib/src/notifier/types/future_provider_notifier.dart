import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/types/async_notifier.dart';

/// The corresponding notifier of a [FutureProvider].
final class FutureProviderNotifier<T> extends AsyncNotifier<T> {
  final Future<T> _future;
  final String Function(AsyncValue<T> state)? _describeState;

  FutureProviderNotifier(
    this._future, {
    String Function(AsyncValue<T> state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

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
  String describeState(AsyncValue<T> state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }
}
