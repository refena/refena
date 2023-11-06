import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';

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

class MockBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
