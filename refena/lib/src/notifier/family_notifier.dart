import 'package:meta/meta.dart';
import 'package:refena/src/notifier/base_notifier.dart';

@internal
abstract interface class FamilyNotifier<T, P> extends BaseNotifier<T> {
  @internal
  bool isParamInitialized(P param);

  @internal
  void initParam(P param);

  @internal
  void disposeParam(P param);
}
