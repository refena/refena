import 'dart:async';

import 'package:refena/src/util/batched_stream_controller.dart';
import 'package:test/test.dart';

import '../../util/skip_microtasks.dart';

void main() {
  StreamSubscription<List<int>>? subscription;

  tearDown(() {
    subscription?.cancel();
  });

  test('Should schedule single null event', () async {
    final controller = BatchedStreamController<int>();
    final events = <List<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(null);

    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [[]]);
  });

  test('Should merge multiple null events', () async {
    final controller = BatchedStreamController<int>();
    final events = <List<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(null);
    controller.schedule(null);
    controller.schedule(null);

    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [[]]);
  });

  test('Should schedule one event', () async {
    final controller = BatchedStreamController<int>();
    final events = <List<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(1);

    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [
      [1],
    ]);
  });

  test('Should schedule multiple events', () async {
    final controller = BatchedStreamController<int>();
    final events = <List<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(1);
    controller.schedule(2);
    controller.schedule(3);

    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [
      [1, 2, 3],
    ]);
  });

  test('Should clear after next micro task', () async {
    final controller = BatchedStreamController<int>();
    final events = <List<int>>[];
    subscription = controller.stream.listen(events.add);

    controller.schedule(1);
    controller.schedule(2);
    controller.schedule(3);

    expect(events, isEmpty);

    await skipAllMicrotasks();

    expect(events, [
      [1, 2, 3],
    ]);

    controller.schedule(4);
    controller.schedule(5);
    controller.schedule(6);

    expect(events, [
      [1, 2, 3],
    ]);

    await skipAllMicrotasks();

    expect(events, [
      [1, 2, 3],
      [4, 5, 6],
    ]);
  });
}
