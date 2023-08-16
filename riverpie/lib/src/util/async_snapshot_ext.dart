import 'package:flutter/material.dart';

extension AsyncSnapshotExt<T> on AsyncSnapshot<T> {
  /// Syntactic sugar for [AsyncSnapshot].
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
    switch (connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
      case ConnectionState.active:
        return loading();
      case ConnectionState.done:
        if (hasError) {
          return error(this.error!, stackTrace!);
        } else {
          return data(this.data as T);
        }
    }
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
    switch (connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
      case ConnectionState.active:
        return loading != null ? loading() : orElse();
      case ConnectionState.done:
        if (hasError) {
          return error != null ? error(this.error!, stackTrace!) : orElse();
        } else {
          return data != null ? data(this.data as T) : orElse();
        }
    }
  }
}
