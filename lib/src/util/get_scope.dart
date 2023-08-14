import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/widget/scope.dart';

/// Returns the nearest [RiverpieScope].
@internal
RiverpieScope getScope(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<RiverpieScope>();
  if (scope == null) {
    throw Exception('Wrap your app with RiverpieScope');
  }
  return scope;
}
