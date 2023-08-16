import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/riverpie.dart';
import 'package:riverpie_flutter/src/scope.dart';

/// Returns the nearest [RiverpieScope].
@internal
RiverpieContainer getScope(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<RiverpieScope>();
  if (scope == null) {
    throw Exception('Wrap your app with RiverpieScope');
  }
  return scope;
}
