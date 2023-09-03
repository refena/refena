StackTrace extendStackTrace(StackTrace stackTrace) {
  return StackTrace.fromString(
    '$stackTrace===== extended by Riverpie ===========================\n${StackTrace.current}',
  );
}
