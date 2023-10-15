import 'package:refena/refena.dart';

extension AsyncValueRecord2Join<T1, T2> on (AsyncValue<T1>, AsyncValue<T2>) {
  /// Joins two [AsyncValue] into one.
  ///
  /// The resulting [AsyncValue] will be:
  /// - [AsyncValue.data] if both are [AsyncValue.data].
  /// - [AsyncValue.error] if one of them is [AsyncValue.error].
  /// - [AsyncValue.loading] if one of them is [AsyncValue.loading].
  AsyncValue<R> join<R>(R Function((T1, T2) data) mapper) {
    if ($1 is AsyncData && $2 is AsyncData) {
      return AsyncValue<R>.data(mapper((
        ($1 as AsyncData<T1>).data,
        ($2 as AsyncData<T2>).data,
      )));
    }

    final data = $1.data != null && $2.data != null
        ? mapper(($1.data!, $2.data!))
        : null;

    if ($1 is AsyncError || $2 is AsyncError) {
      final asyncError = $1 is AsyncError ? $1 as AsyncError : $2 as AsyncError;
      final error = asyncError.error;
      final stackTrace = asyncError.stackTrace;

      return AsyncValue<R>.error(
        error,
        stackTrace,
        data,
      );
    }

    return AsyncValue<R>.loading(data);
  }
}

extension AsyncValueRecord3Join<T1, T2, T3> on (
  AsyncValue<T1>,
  AsyncValue<T2>,
  AsyncValue<T3>
) {
  /// Joins three [AsyncValue] into one.
  ///
  /// The resulting [AsyncValue] will be:
  /// - [AsyncValue.data] if all are [AsyncValue.data].
  /// - [AsyncValue.error] if one of them is [AsyncValue.error].
  /// - [AsyncValue.loading] if one of them is [AsyncValue.loading].
  AsyncValue<R> join<R>(R Function((T1, T2, T3) data) mapper) {
    if ($1 is AsyncData && $2 is AsyncData && $3 is AsyncData) {
      return AsyncValue<R>.data(mapper((
        ($1 as AsyncData<T1>).data,
        ($2 as AsyncData<T2>).data,
        ($3 as AsyncData<T3>).data,
      )));
    }

    final data = $1.data != null && $2.data != null && $3.data != null
        ? mapper(($1.data!, $2.data!, $3.data!))
        : null;

    if ($1 is AsyncError || $2 is AsyncError || $3 is AsyncError) {
      final asyncError = $1 is AsyncError
          ? $1 as AsyncError
          : $2 is AsyncError
              ? $2 as AsyncError
              : $3 as AsyncError;
      final error = asyncError.error;
      final stackTrace = asyncError.stackTrace;

      return AsyncValue<R>.error(
        error,
        stackTrace,
        data,
      );
    }

    return AsyncValue<R>.loading(data);
  }
}

extension AsyncValueRecord4Join<T1, T2, T3, T4> on (
  AsyncValue<T1>,
  AsyncValue<T2>,
  AsyncValue<T3>,
  AsyncValue<T4>
) {
  /// Joins four [AsyncValue] into one.
  ///
  /// The resulting [AsyncValue] will be:
  /// - [AsyncValue.data] if all are [AsyncValue.data].
  /// - [AsyncValue.error] if one of them is [AsyncValue.error].
  /// - [AsyncValue.loading] if one of them is [AsyncValue.loading].
  AsyncValue<R> join<R>(R Function((T1, T2, T3, T4) data) mapper) {
    if ($1 is AsyncData &&
        $2 is AsyncData &&
        $3 is AsyncData &&
        $4 is AsyncData) {
      return AsyncValue<R>.data(mapper((
        ($1 as AsyncData<T1>).data,
        ($2 as AsyncData<T2>).data,
        ($3 as AsyncData<T3>).data,
        ($4 as AsyncData<T4>).data,
      )));
    }

    final data =
        $1.data != null && $2.data != null && $3.data != null && $4.data != null
            ? mapper(($1.data!, $2.data!, $3.data!, $4.data!))
            : null;

    if ($1 is AsyncError ||
        $2 is AsyncError ||
        $3 is AsyncError ||
        $4 is AsyncError) {
      final asyncError = $1 is AsyncError
          ? $1 as AsyncError
          : $2 is AsyncError
              ? $2 as AsyncError
              : $3 is AsyncError
                  ? $3 as AsyncError
                  : $4 as AsyncError;
      final error = asyncError.error;
      final stackTrace = asyncError.stackTrace;

      return AsyncValue<R>.error(
        error,
        stackTrace,
        data,
      );
    }

    return AsyncValue<R>.loading(data);
  }
}

extension AsyncValueRecord5Join<T1, T2, T3, T4, T5> on (
  AsyncValue<T1>,
  AsyncValue<T2>,
  AsyncValue<T3>,
  AsyncValue<T4>,
  AsyncValue<T5>,
) {
  /// Joins five [AsyncValue] into one.
  ///
  /// The resulting [AsyncValue] will be:
  /// - [AsyncValue.data] if all are [AsyncValue.data].
  /// - [AsyncValue.error] if one of them is [AsyncValue.error].
  /// - [AsyncValue.loading] if one of them is [AsyncValue.loading].
  AsyncValue<R> join<R>(R Function((T1, T2, T3, T4, T5) data) mapper) {
    if ($1 is AsyncData &&
        $2 is AsyncData &&
        $3 is AsyncData &&
        $4 is AsyncData &&
        $5 is AsyncData) {
      return AsyncValue<R>.data(mapper((
        ($1 as AsyncData<T1>).data,
        ($2 as AsyncData<T2>).data,
        ($3 as AsyncData<T3>).data,
        ($4 as AsyncData<T4>).data,
        ($5 as AsyncData<T5>).data,
      )));
    }

    final data = $1.data != null &&
            $2.data != null &&
            $3.data != null &&
            $4.data != null &&
            $5.data != null
        ? mapper(($1.data!, $2.data!, $3.data!, $4.data!, $5.data!))
        : null;

    if ($1 is AsyncError ||
        $2 is AsyncError ||
        $3 is AsyncError ||
        $4 is AsyncError ||
        $5 is AsyncError) {
      final asyncError = $1 is AsyncError
          ? $1 as AsyncError
          : $2 is AsyncError
              ? $2 as AsyncError
              : $3 is AsyncError
                  ? $3 as AsyncError
                  : $4 is AsyncError
                      ? $4 as AsyncError
                      : $5 as AsyncError;
      final error = asyncError.error;
      final stackTrace = asyncError.stackTrace;

      return AsyncValue<R>.error(
        error,
        stackTrace,
        data,
      );
    }

    return AsyncValue<R>.loading(data);
  }
}
