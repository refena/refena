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
  }) {
    return switch (this) {
      AsyncData curr => data(curr.data),
      AsyncError curr => error(curr.error, curr.stackTrace),
      AsyncLoading _ => loading(),
    };
  }

  /// Syntactic sugar for [AsyncSnapshot].
  ///
  /// final futureState = ref.watch(futureProvider);
  /// futureState.maybeWhen(
  ///   data: (data) => Text(data),
  ///   orElse: () => const CircularProgressIndicator(),
  /// );
  R maybeWhen<R>({
    R Function(T data)? data,
    R Function(Object error, StackTrace stackTrace)? error,
    R Function()? loading,
    required R Function() orElse,
  }) {
    return switch (this) {
      AsyncData curr => data != null ? data(curr.data) : orElse(),
      AsyncError curr =>
        error != null ? error(curr.error, curr.stackTrace) : orElse(),
      AsyncLoading _ => loading != null ? loading() : orElse(),
    };
  }

  /// Constructs an [AsyncValue].
  const factory AsyncValue.withData(T data) = AsyncData<T>._;

  /// Constructs an [AsyncError].
  const factory AsyncValue.withError(Object error, StackTrace stackTrace) =
      AsyncError<T>._;

  /// Constructs an [AsyncLoading].
  const factory AsyncValue.loading() = AsyncLoading<T>._;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AsyncValue<T> &&
            runtimeType == other.runtimeType &&
            data == other.data &&
            error == other.error &&
            stackTrace == other.stackTrace;
  }

  @override
  int get hashCode => data.hashCode ^ error.hashCode ^ stackTrace.hashCode;
}

/// The data of an [AsyncValue].
final class AsyncData<T> extends AsyncValue<T> {
  @override
  final T data;

  const AsyncData._(this.data);
}

/// The error of an [AsyncValue].
final class AsyncError<T> extends AsyncValue<T> {
  @override
  final Object error;

  @override
  final StackTrace stackTrace;

  const AsyncError._(this.error, this.stackTrace);
}

/// The loading state of an [AsyncValue].
final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading._();
}
