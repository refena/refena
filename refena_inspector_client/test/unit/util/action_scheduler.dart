import 'package:refena_inspector_client/src/util/action_scheduler.dart';
import 'package:test/test.dart';

void main() {
  test('Should run single action instantly', () {
    int called = 0;
    final scheduler = ActionScheduler(
      minDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 500),
      action: () => called++,
    );

    scheduler.scheduleAction();

    expect(called, 1);
  });

  test('Should not run any actions before maxDelay', () async {
    int called = 0;
    ActionScheduler(
      minDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 500),
      action: () => called++,
    );

    expect(called, 0);

    await _sleepAsync(100);

    expect(called, 0);

    await _sleepAsync(500);

    expect(called, 1);
  });

  test('Should schedule action if called multiple times', () async {
    int called = 0;
    final scheduler = ActionScheduler(
      minDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 500),
      action: () => called++,
    );

    scheduler.scheduleAction();
    scheduler.scheduleAction();

    expect(called, 1);
    await _sleepAsync(50);
    expect(called, 1);
    await _sleepAsync(100);
    expect(called, 2);
  });

  test('Should skip scheduling another action in the same millisecond',
      () async {
    int called = 0;
    final scheduler = ActionScheduler(
      minDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 500),
      action: () => called++,
    );

    scheduler.scheduleAction();
    scheduler.scheduleAction();
    scheduler.scheduleAction(); // This one should be skipped

    expect(called, 1);
    await _sleepAsync(50);
    expect(called, 1);
    await _sleepAsync(100);
    expect(called, 2);
    await _sleepAsync(100);
    expect(called, 2);
  });

  test(
    'Should skip scheduled action if another action has been scheduled in the meantime',
    () async {
      int called = 0;
      final scheduler = ActionScheduler(
        minDelay: const Duration(milliseconds: 100),
        maxDelay: const Duration(milliseconds: 500),
        action: () => called++,
      );

      scheduler.scheduleAction();
      expect(called, 1);
      scheduler.scheduleAction(); // Scheduled but not executed
      await _sleepAsync(50);
      scheduler.scheduleAction(); // Scheduled and later executed
      expect(called, 1);

      await _sleepAsync(75);
      expect(called, 1); // 2nd call skipped because superseded by 3rd call
      await _sleepAsync(200);
      expect(called, 2);
    },
  );

  test('Should run action during waiting for scheduled action', () async {
    int called = 0;
    final scheduler = ActionScheduler(
      minDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 500),
      action: () => called++,
    );

    scheduler.scheduleAction();
    expect(called, 1);
    scheduler.scheduleAction(); // Scheduled but not executed
    await _sleepAsync(50);
    scheduler.scheduleAction(); // Scheduled and later executed
    expect(called, 1);

    await _sleepAsync(75);
    expect(called, 1); // 2nd call skipped because superseded by 3rd call
    scheduler.scheduleAction();
    expect(called, 2); // 4th call executed immediately
    await _sleepAsync(200);
    expect(called, 2); // 3rd call skipped because superseded by 4th call
  });

  test('Should execute action if idle for maxDelay', () async {
    int called = 0;
    final scheduler = ActionScheduler(
      minDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 500),
      action: () => called++,
    );

    scheduler.scheduleAction();
    expect(called, 1);
    await _sleepAsync(650);
    expect(called, 2);
  });

  test('Should drop scheduled actions after reset', () async {
    int called = 0;
    final scheduler = ActionScheduler(
      minDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 500),
      action: () => called++,
    );

    scheduler.scheduleAction();
    scheduler.scheduleAction();
    scheduler.scheduleAction();
    expect(called, 1);

    scheduler.reset();
    await _sleepAsync(400);
    expect(called, 1);
  });

  test('Should run the first action right after reset', () async {
    int called = 0;
    final scheduler = ActionScheduler(
      minDelay: const Duration(milliseconds: 100),
      maxDelay: const Duration(milliseconds: 500),
      action: () => called++,
    );

    scheduler.scheduleAction();
    scheduler.scheduleAction();
    scheduler.scheduleAction();
    expect(called, 1);

    scheduler.reset();
    expect(called, 1);

    scheduler.scheduleAction();
    expect(called, 2);

    await _sleepAsync(400);
    expect(called, 2);
  });
}

Future<void> _sleepAsync(int millis) {
  return Future.delayed(Duration(milliseconds: millis));
}
