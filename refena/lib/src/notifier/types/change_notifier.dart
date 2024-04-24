import 'package:meta/meta.dart';
import 'package:refena/src/notifier/types/notifier.dart';
import 'package:refena/src/ref.dart';

/// A notifier that can trigger [notifyListeners] to trigger rebuilds.
/// It has access to [Ref] for fast development.
abstract class ChangeNotifier extends Notifier<void> {
  ChangeNotifier();

  /// Override [postInit] to run code after the notifier is initialized.
  @override
  @internal
  void init() {}

  /// Call this method whenever the state changes.
  /// This will notify all listeners.
  @protected
  void notifyListeners() {
    super.state = null;
  }

  @override
  @internal
  bool updateShouldNotify(void prev, void next) {
    return true;
  }

  @override
  @internal
  set state(void value) {
    throw UnsupportedError('Not allowed to set state directly');
  }
}
