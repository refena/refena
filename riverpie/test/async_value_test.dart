import 'package:riverpie/riverpie.dart';
import 'package:test/test.dart';

void main() {
  group('toString', () {
    test(AsyncData, () {
      expect(AsyncValue.withData(1).toString(), 'AsyncData<int>(1)');
      expect(AsyncValue.withData('a').toString(), 'AsyncData<String>(a)');
    });

    test(AsyncError, () {
      expect(
        AsyncValue<String>.withError('test error', StackTrace.empty).toString(),
        'AsyncError<String>(test error)',
      );
    });

    test(AsyncLoading, () {
      expect(AsyncValue<bool>.loading().toString(), 'AsyncLoading<bool>');
    });
  });
}
