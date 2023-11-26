import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/scope.dart';

void main() {
  test('context.read with family providers should compile', () {
    final context = MockBuildContext();
    final familyProvider = ViewProvider.family<int, int>((ref, id) => 0);
    context.read(familyProvider(0));

    expect(true, true);
  });

  test('context.watch with family providers should compile', () {
    final context = MockBuildContext();
    final familyProvider = ViewProvider.family<int, int>((ref, id) => 0);
    context.watch(familyProvider(0));

    expect(true, true);
  });
}

class MockBuildContext implements Element {
  final RefenaContainer _container = RefenaContainer();

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) {
    return RefenaInheritedWidget(
      container: _container,
      child: Container(),
    ) as T;
  }

  @override
  Widget get widget => Container();

  @override
  bool get debugDoingBuild => true;

  @override
  bool get mounted => true;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.debug}) => '';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
