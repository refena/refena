import 'package:riverpie/src/notifier/base_notifier.dart';

/// A [Notifier] but without [ref] making this notifier self-contained.
///
/// Can be used in combination with dependency injection,
/// where you provide the dependencies via constructor.
abstract class PureNotifier<T> extends BaseSyncNotifier<T> {
  PureNotifier({String? debugLabel}) : super(debugLabel: debugLabel);
}
