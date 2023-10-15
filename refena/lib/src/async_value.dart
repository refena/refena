sealed class AsyncValue<T> {
  const AsyncValue();

  /// The data of an [AsyncValue].
  /// Is always [T] if the state is [AsyncData].
  T? get data => null;

  /// The error of an [AsyncValue].
  /// Is not null if the state is [AsyncError].
  Object? get error => null;

  /// The stack trace of an [AsyncValue].
  /// Is not null if the state is [AsyncError].
  StackTrace? get stackTrace => null;

  /// Whether the state is [AsyncData].
  bool get hasData => this is AsyncData<T>;

  /// Whether the state is [AsyncError].
  bool get hasError => this is AsyncError<T>;

  /// Whether the state is [AsyncLoading].
  bool get isLoading => this is AsyncLoading<T>;

  /// Syntactic sugar for [AsyncValue].
  ///
  /// Usage:
  /// final futureProvider = FutureProvider((ref) async {
  ///   final response = await ref.read(apiProvider).get();
  ///   return response.data;
  /// });
  ///
  /// // ...
  ///
  /// final futureState = ref.watch(futureProvider);
  ///
  /// futureState.when(
  ///   data: (data) => Text(data),
  ///   loading: () => const CircularProgressIndicator(),
  ///   error: (error, stackTrace) => Text(error.toString()),
  /// );
  R when<R>({
    required R Function(T data) data,
    required R Function() loading,
    required R Function(Object error, StackTrace stackTrace) error,
    bool skipLoading = true,
    bool skipError = false,
  }) {
    return switch (this) {
      AsyncData<T> curr => data(curr.data),
      AsyncLoading<T> curr => switch (curr.data) {
          T t when skipLoading => data(t),
          _ => loading()
        },
      AsyncError<T> curr => switch (curr.data) {
          T t when skipError => data(t),
          _ => error(curr.error, curr.stackTrace),
        },
    };
  }

  /// Syntactic sugar for [AsyncValue].
  ///
  /// final futureState = ref.watch(futureProvider);
  /// futureState.maybeWhen(
  ///   data: (data) => Text(data),
  ///   orElse: () => const CircularProgressIndicator(),
  /// );
  R maybeWhen<R>({
    R Function(T data)? data,
    R Function()? loading,
    R Function(Object error, StackTrace stackTrace)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      AsyncData<T> curr => data != null ? data(curr.data) : orElse(),
      AsyncLoading<T> _ => loading != null ? loading() : orElse(),
      AsyncError<T> curr =>
        error != null ? error(curr.error, curr.stackTrace) : orElse(),
    };
  }

  /// Constructs an [AsyncValue].
  const factory AsyncValue.withData(T data) = AsyncData<T>._;

  /// Constructs an [AsyncLoading].
  const factory AsyncValue.loading([T? prev]) = AsyncLoading<T>._;

  /// Constructs an [AsyncError].
  const factory AsyncValue.withError(
    Object error,
    StackTrace stackTrace, [
    T? prev,
  ]) = AsyncError<T>._;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AsyncValue<T> &&
            runtimeType == other.runtimeType &&
            data == other.data &&
            error == other.error;
  }

  @override
  int get hashCode => data.hashCode ^ error.hashCode;
}

/// The data of an [AsyncValue].
final class AsyncData<T> extends AsyncValue<T> {
  @override
  final T data;

  const AsyncData._(this.data);

  @override
  String toString() {
    return 'AsyncData<$T>($data)';
  }
}

/// The loading state of an [AsyncValue].
final class AsyncLoading<T> extends AsyncValue<T> {
  /// Represents the previous data before loading.
  @override
  final T? data;

  const AsyncLoading._([this.data]);

  @override
  String toString() {
    return 'AsyncLoading<$T>';
  }
}

/// The error of an [AsyncValue].
final class AsyncError<T> extends AsyncValue<T> {
  @override
  final Object error;

  @override
  final StackTrace stackTrace;

  @override
  final T? data;

  const AsyncError._(this.error, this.stackTrace, [this.data]);

  @override
  String toString() {
    return 'AsyncError<$T>($error)';
  }
}
