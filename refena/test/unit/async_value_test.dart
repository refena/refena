import 'package:refena/refena.dart';
import 'package:test/test.dart';

void main() {
  group('toString', () {
    test(AsyncData, () {
      expect(AsyncValue.data(1).toString(), 'AsyncData<int>(1)');
      expect(AsyncValue.data('a').toString(), 'AsyncData<String>(a)');
    });

    test(AsyncError, () {
      expect(
        AsyncValue<String>.error('test error', StackTrace.empty).toString(),
        'AsyncError<String>(test error)',
      );
    });

    test(AsyncLoading, () {
      expect(AsyncValue<bool>.loading().toString(), 'AsyncLoading<bool>');
    });
  });

  group('when', () {
    test('Should return the correct value for data', () {
      expect(
        AsyncValue.data(1).when(
          data: (data) => 'data-$data',
          loading: () => 'loading',
          error: (error, stackTrace) => 'error-$error',
        ),
        'data-1',
      );
    });

    test('Should return the correct value for loading', () {
      expect(
        AsyncValue<bool>.loading().when(
          data: (data) => 'data-$data',
          loading: () => 'loading',
          error: (error, stackTrace) => 'error-$error',
        ),
        'loading',
      );
    });

    test('Should return the correct value for error', () {
      expect(
        AsyncValue<String>.error('test error', StackTrace.empty).when(
          data: (data) => 'data-$data',
          loading: () => 'loading',
          error: (error, stackTrace) => 'error-$error',
        ),
        'error-test error',
      );
    });

    test('Should skip loading when data is provided', () {
      expect(
        AsyncValue<int>.loading(2).when(
          data: (data) => 'data-$data',
          loading: () => 'loading',
          error: (error, stackTrace) => 'error-$error',
        ),
        'data-2',
      );
    });

    test('Should use error when data is provided', () {
      expect(
        AsyncValue<int>.error('error', StackTrace.empty, 3).when(
          data: (data) => 'data-$data',
          loading: () => 'loading',
          error: (error, stackTrace) => 'error-$error',
        ),
        'error-error',
      );
    });

    test('Should skip error when data is provided and with skip flag', () {
      expect(
        AsyncValue<int>.error('error', StackTrace.empty, 3).when(
          data: (data) => 'data-$data',
          loading: () => 'loading',
          error: (error, stackTrace) => 'error-$error',
          skipError: true,
        ),
        'data-3',
      );
    });
  });
}
