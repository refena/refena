Never rethrowWithNewStackTrace(Object error, StackTrace stackTrace) {
  Error.throwWithStackTrace(
    error,
    StackTrace.fromString(
      '$stackTrace===== asynchronous gap ===========================\n${StackTrace.current}',
    ),
  );
}
