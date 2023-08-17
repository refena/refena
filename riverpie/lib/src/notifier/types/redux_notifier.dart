import 'package:riverpie/src/notifier/base_notifier.dart';

/// A notifier where the state can be updated by emitting events.
/// Events are emitted by calling [emit].
/// They are handled by the notifier with [reduce].
///
/// You do not have access to [ref] in this notifier, so you need to pass
/// the required dependencies via constructor.
abstract class ReduxNotifier<T, E extends Object>
    extends BaseReduxNotifier<T, E> {
  ReduxNotifier({String? debugLabel}) : super(debugLabel: debugLabel);
}
