import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';

/// A notifier that is immutable.
/// The state of the notifier is provided in the constructor.
class ImmutableNotifier<T> extends BaseSyncNotifier<T> {
  final T _value;

  ImmutableNotifier(
    this._value, {
    super.debugLabel,
  });

  @override
  T init() => _value;

  @override
  @internal
  set state(T value) {
    throw UnsupportedError('ImmutableNotifier is immutable');
  }
}
