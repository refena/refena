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

  group('map', () {
    test('Should map data type', () {
      expect(
        AsyncValue.data(1).map((data) => 's$data'),
        AsyncValue.data('s1'),
      );
    });

    test('Should map loading state', () {
      expect(
        AsyncValue<int>.loading().map((data) => 's$data'),
        AsyncValue<String>.loading(),
      );
    });

    test('Should map loading state with data', () {
      expect(
        AsyncValue<int>.loading(2).map((data) => 's$data'),
        AsyncValue<String>.loading('s2'),
      );
    });

    test('Should map error state', () {
      expect(
        AsyncValue<int>.error('error', StackTrace.empty)
            .map((data) => 's$data'),
        AsyncValue<String>.error('error', StackTrace.empty),
      );
    });

    test('Should map error state with data', () {
      expect(
        AsyncValue<int>.error('error', StackTrace.empty, 3)
            .map((data) => 's$data'),
        AsyncValue<String>.error('error', StackTrace.empty, 's3'),
      );
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

  group('join', () {
    test('Should join 2 AsyncValue', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.data('a'),
      ).join((data) {
        final int a0 = data.$1;
        final String a1 = data.$2;
        return '$a0:$a1';
      });

      expect(joined, AsyncValue.data('1:a'));
    });

    test('Should join 3 AsyncValue', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.data('a'),
        AsyncValue.data(true),
      ).join((data) {
        final int a0 = data.$1;
        final String a1 = data.$2;
        final bool a2 = data.$3;
        return '$a0:$a1:$a2';
      });

      expect(joined, AsyncValue.data('1:a:true'));
    });

    test('Should join 4 AsyncValue', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.data('a'),
        AsyncValue.data(true),
        AsyncValue.data(2.0),
      ).join((data) {
        final int a0 = data.$1;
        final String a1 = data.$2;
        final bool a2 = data.$3;
        final double a3 = data.$4;
        return '$a0:$a1:$a2:$a3';
      });

      expect(joined, AsyncValue.data('1:a:true:2.0'));
    });

    test('Should join 5 AsyncValue', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.data('a'),
        AsyncValue.data(true),
        AsyncValue.data(2.0),
        AsyncValue.data(3),
      ).join((data) {
        final int a0 = data.$1;
        final String a1 = data.$2;
        final bool a2 = data.$3;
        final double a3 = data.$4;
        final int a4 = data.$5;
        return '$a0:$a1:$a2:$a3:$a4';
      });

      expect(joined, AsyncValue.data('1:a:true:2.0:3'));
    });

    test('Should join 2 AsyncValue while one is loading', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.loading('a'),
      ).join((data) {
        final int a0 = data.$1;
        final String a1 = data.$2;
        return '$a0:$a1';
      });

      expect(joined, AsyncValue.loading('1:a'));
    });

    test('Should join 2 AsyncValue while one is error', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.error('e', StackTrace.empty, 'a'),
      ).join((data) {
        final int a0 = data.$1;
        final String a1 = data.$2;
        return '$a0:$a1';
      });

      expect(joined, AsyncValue.error('e', StackTrace.empty, '1:a'));
    });

    test('Should join 2 AsyncValue while one is error and one is loading', () {
      final joined = (
        AsyncValue.loading(1),
        AsyncValue.error('e', StackTrace.empty, 'a'),
      ).join((data) {
        final int a0 = data.$1;
        final String a1 = data.$2;
        return '$a0:$a1';
      });

      expect(joined, AsyncValue.error('e', StackTrace.empty, '1:a'));
    });

    test('Should join 2 AsyncValue with all loading data combinations', () {
      final a0 = 1;
      final a1 = 'a';
      final combinations = [true, false];

      for (final withA0 in combinations) {
        for (final withA1 in combinations) {
          final joined = (
            AsyncValue<int>.loading(withA0 ? a0 : null),
            AsyncValue<String>.loading(withA1 ? a1 : null),
          ).join((data) {
            final int a0 = data.$1;
            final String a1 = data.$2;
            return '$a0:$a1';
          });

          expect(
            joined,
            withA0 && withA1
                ? AsyncValue<String>.loading('$a0:$a1')
                : AsyncValue<String>.loading(null),
          );
        }
      }
    });

    test('Should join 3 AsyncValue with all loading data combinations', () {
      final a0 = 1;
      final a1 = 'a';
      final a3 = true;
      final combinations = [true, false];

      for (final withA0 in combinations) {
        for (final withA1 in combinations) {
          for (final withA3 in combinations) {
            final joined = (
              AsyncValue<int>.loading(withA0 ? a0 : null),
              AsyncValue<String>.loading(withA1 ? a1 : null),
              AsyncValue<bool>.loading(withA3 ? a3 : null),
            ).join((data) {
              final int a0 = data.$1;
              final String a1 = data.$2;
              final bool a3 = data.$3;
              return '$a0:$a1:$a3';
            });

            expect(
              joined,
              withA0 && withA1 && withA3
                  ? AsyncValue<String>.loading('$a0:$a1:$a3')
                  : AsyncValue<String>.loading(null),
            );
          }
        }
      }
    });
  });
}
