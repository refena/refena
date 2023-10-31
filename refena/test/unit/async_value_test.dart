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

  group('maybeWhen', () {
    test('Should return the correct value for data', () {
      expect(
        AsyncValue.data(1).maybeWhen(
          data: (data) => 'data-$data',
          orElse: () => 'orElse',
        ),
        'data-1',
      );
    });

    test('Should return the correct value for loading', () {
      expect(
        AsyncValue<bool>.loading().maybeWhen(
          loading: () => 'loading',
          orElse: () => 'orElse',
        ),
        'loading',
      );
    });

    test('Should return the correct value for error', () {
      expect(
        AsyncValue<String>.error('test error', StackTrace.empty).maybeWhen(
          error: (error, stackTrace) => 'error-$error',
          orElse: () => 'orElse',
        ),
        'error-test error',
      );
    });

    test('Should use orElse when loading', () {
      expect(
        AsyncValue<int>.loading().maybeWhen(
          data: (data) => 'data-$data',
          orElse: () => 'orElse',
        ),
        'orElse',
      );
    });

    test('Should use orElse when error', () {
      expect(
        AsyncValue<int>.error('error', StackTrace.empty).maybeWhen(
          data: (data) => 'data-$data',
          orElse: () => 'orElse',
        ),
        'orElse',
      );
    });

    test('Should skip loading when data is provided', () {
      expect(
        AsyncValue<int>.loading(2).maybeWhen(
          data: (data) => 'data-$data',
          orElse: () => 'orElse',
        ),
        'data-2',
      );
    });

    test('Should use error when data is provided', () {
      expect(
        AsyncValue<int>.error('error', StackTrace.empty, 3).maybeWhen(
          data: (data) => 'data-$data',
          orElse: () => 'orElse',
        ),
        'orElse',
      );
    });

    test('Should skip error when data is provided and with skip flag', () {
      expect(
        AsyncValue<int>.error('error', StackTrace.empty, 3).maybeWhen(
          data: (data) => 'data-$data',
          orElse: () => 'orElse',
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
      ).join((a0, a1) {
        expect(a0, isA<int>());
        expect(a1, isA<String>());
        return '$a0:$a1';
      });

      expect(joined, AsyncValue.data('1:a'));
    });

    test('Should join 3 AsyncValue', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.data('a'),
        AsyncValue.data(true),
      ).join((a0, a1, a2) {
        expect(a0, isA<int>());
        expect(a1, isA<String>());
        expect(a2, isA<bool>());
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
      ).join((a0, a1, a2, a3) {
        expect(a0, isA<int>());
        expect(a1, isA<String>());
        expect(a2, isA<bool>());
        expect(a3, isA<double>());
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
      ).join((a0, a1, a2, a3, a4) {
        expect(a0, isA<int>());
        expect(a1, isA<String>());
        expect(a2, isA<bool>());
        expect(a3, isA<double>());
        expect(a4, isA<int>());
        return '$a0:$a1:$a2:$a3:$a4';
      });

      expect(joined, AsyncValue.data('1:a:true:2.0:3'));
    });

    test('Should join 2 AsyncValue while one is loading', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.loading('a'),
      ).join((a0, a1) {
        return '$a0:$a1';
      });

      expect(joined, AsyncValue.loading('1:a'));
    });

    test('Should join 2 AsyncValue while one is error', () {
      final joined = (
        AsyncValue.data(1),
        AsyncValue.error('e', StackTrace.empty, 'a'),
      ).join((a0, a1) {
        return '$a0:$a1';
      });

      expect(joined, AsyncValue.error('e', StackTrace.empty, '1:a'));
    });

    test('Should join 2 AsyncValue while one is error and one is loading', () {
      final joined = (
        AsyncValue.loading(1),
        AsyncValue.error('e', StackTrace.empty, 'a'),
      ).join((a0, a1) {
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
          ).join((a0, a1) {
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
      final a2 = true;
      final combinations = [true, false];

      for (final withA0 in combinations) {
        for (final withA1 in combinations) {
          for (final withA2 in combinations) {
            final joined = (
              AsyncValue<int>.loading(withA0 ? a0 : null),
              AsyncValue<String>.loading(withA1 ? a1 : null),
              AsyncValue<bool>.loading(withA2 ? a2 : null),
            ).join((a0, a1, a2) {
              return '$a0:$a1:$a2';
            });

            expect(
              joined,
              withA0 && withA1 && withA2
                  ? AsyncValue<String>.loading('$a0:$a1:$a2')
                  : AsyncValue<String>.loading(null),
            );
          }
        }
      }
    });
  });
}
