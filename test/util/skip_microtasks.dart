/// Await this future to skip all microtasks.
Future<void> skipAllMicrotasks() => Future.delayed(Duration.zero);
