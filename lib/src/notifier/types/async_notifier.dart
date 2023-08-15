import 'package:flutter/material.dart';
import 'package:riverpie/src/notifier/base_notifier.dart';

abstract class AsyncNotifier<T> extends BaseAsyncNotifier<T> {
  AsyncSnapshot<T>? _prev;

  AsyncNotifier({super.debugLabel});

  /// The state of this notifier before the latest [future] was set.
  AsyncSnapshot<T>? get prev => _prev;

  /// Whether the previous state should be saved.
  /// Override this, if you don't want to save the previous state.
  bool get savePrev => true;

  @override
  @protected
  set future(Future<T> value) {
    if (savePrev) {
      _prev = state;
    }
    super.future = value;
  }
}
