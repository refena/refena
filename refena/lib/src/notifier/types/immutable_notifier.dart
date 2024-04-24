import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';

/// A notifier that is immutable.
/// The state of the notifier is provided in the constructor.
final class ImmutableNotifier<T> extends BaseSyncNotifier<T> {
  final T _value;
  final String Function(T state)? _describeState;

  ImmutableNotifier(
    this._value, {
    String Function(T state)? describeState,
  }) : _describeState = describeState;

  @override
  T init() => _value;

  @override
  @internal
  set state(T value) {
    throw UnsupportedError('ImmutableNotifier is immutable');
  }

  @override
  String describeState(T state) {
    if (_describeState == null) {
      return super.describeState(state);
    }
    return _describeState!(state);
  }
}
