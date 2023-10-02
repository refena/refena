StackTrace extendStackTrace(StackTrace stackTrace) {
  if (stackTrace.toString().contains('package:refena')) {
    // This stacktrace seem to already contain the root cause
    // as refena does not introduce any new stack frames.
    return stackTrace;
  }

  // This stacktrace does not contain the root cause.
  // We add the current stacktrace to the end of the stacktrace.
  // This can be reproduced with the dio (v5) package.
  return StackTrace.fromString(
    '$stackTrace===== extended by Refena ===========================\n${StackTrace.current}',
  );
}
