import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/src/util/batched_set_controller.dart';

import 'skip_microtasks.dart';

void main() {
  StreamSubscription<Set<int>>? subscription;

  tearDown(() {
    subscription?.cancel();
  });

  test('Should schedule one event', () async {
    final controller = BatchedSetController<int>();
    final events = <Set<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(1);

    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [
      {1},
    ]);
  });

  test('Should schedule multiple events', () async {
    final controller = BatchedSetController<int>();
    final events = <Set<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(1);
    controller.schedule(2);
    controller.schedule(3);

    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [
      {1, 2, 3},
    ]);
  });

  test('Should return false on duplicate item', () async {
    final controller = BatchedSetController<int>();
    final events = <Set<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(1);
    final initialResult = controller.schedule(2);
    final duplicateResult = controller.schedule(2);
    controller.schedule(3);

    expect(initialResult, true);
    expect(duplicateResult, false);
    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [
      {1, 2, 3},
    ]);
  });

  test('Should clear after next micro task', () async {
    final controller = BatchedSetController<int>();
    final events = <Set<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(1);
    controller.schedule(2);
    controller.schedule(3);

    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [
      {1, 2, 3},
    ]);

    controller.schedule(4);
    controller.schedule(5);
    controller.schedule(6);

    expect(events, [
      {1, 2, 3},
    ]);

    await skipAllMicrotasks();

    expect(events, [
      {1, 2, 3},
      {4, 5, 6},
    ]);
  });
}
