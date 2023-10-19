import 'package:refena_flutter/refena_flutter.dart';

final refenaCounter = StateProvider((ref) => 0);

final refenaReduxCounter = ReduxProvider<RefenaReduxNotifier, int>((ref) {
  return RefenaReduxNotifier();
});

class RefenaReduxNotifier extends ReduxNotifier<int> {
  @override
  int init() => 0;
}

class IncrementAction extends ReduxAction<RefenaReduxNotifier, int> {
  @override
  int reduce() => state + 1;
}
