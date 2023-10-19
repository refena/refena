import 'package:example/refena.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refena_riverpod_extension/refena_riverpod_extension.dart';

final riverpodCounter = StateProvider((ref) => 0);

final riverpodNotifierProvider = NotifierProvider<RiverpodNotifier, int>(() {
  return RiverpodNotifier();
});

class RiverpodNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void dispatch() {
    ref.refena.redux(refenaReduxCounter).dispatch(IncrementAction());
  }
}
