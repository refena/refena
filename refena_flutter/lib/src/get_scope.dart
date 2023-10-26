import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:refena/refena.dart';
import 'package:refena_flutter/src/scope.dart';

/// Returns the nearest [RefenaScope].
@internal
RefenaContainer getScope(BuildContext context) {
  final scope =
      context.dependOnInheritedWidgetOfExactType<RefenaInheritedWidget>();
  if (scope == null) {
    throw StateError('Wrap your app with RefenaScope');
  }
  return scope.container;
}
