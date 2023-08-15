import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';

/// A "provider state" holds the value of a provider.
/// The state may hold the value directly or indirectly via notifier.
/// But in any case, the state should expose the current value [T].
@internal
abstract class BaseProviderState<T> {
  T getValue();
}

@internal
class ProviderState<T> extends BaseProviderState<T> {
  final T _value;

  ProviderState(this._value);

  @override
  T getValue() => _value;
}

@internal
class NotifierProviderState<N extends BaseNotifier<T>, T>
    extends BaseProviderState<T> {
  final N _notifier;

  NotifierProviderState(this._notifier);

  @override
  T getValue() => _notifier.state; // ignore: invalid_use_of_protected_member

  N getNotifier() => _notifier;
}
