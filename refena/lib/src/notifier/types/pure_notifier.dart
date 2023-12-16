import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/notifier/types/notifier.dart';
import 'package:refena/src/ref.dart';

/// A [Notifier] but without [Ref] making this notifier self-contained.
///
/// It is used in combination with dependency injection,
/// where you provide the dependencies via constructor.
abstract class PureNotifier<T> extends BaseSyncNotifier<T> {
  PureNotifier({String? debugLabel}) : super(debugLabel: debugLabel);
}
