import 'package:flutter/material.dart';
import 'package:riverpie/src/notifier/notifier.dart';
import 'package:riverpie/src/provider/provider.dart';
import 'package:riverpie/src/provider/state.dart';
import 'package:riverpie/src/ref.dart';

/// A [FutureProvider] is a custom implementation of a [NotifierProvider]
/// that allows you to watch a [Future].
///
/// The advantage over using a [FutureBuilder] is that the
/// value is cached and only the first call to the [Future] is executed.
///
/// Usage:
/// final myProvider = FutureProvider((ref) async {
///   return await fetchApi();
/// }
///
/// Example use cases:
/// - fetch static data from an API (that does not change)
/// - fetch device information (that does not change)
class FutureProvider<T>
    extends NotifierProvider<_FutureNotifier<T>, AsyncSnapshot<T>> {
  FutureProvider(Future<T> Function(Ref ref) builder, {super.debugLabel})
      : super((ref) => _FutureNotifier<T>(builder(ref)));

  ProviderOverride overrideWithFuture(Future<T> value) {
    return ProviderOverride<AsyncSnapshot<T>>(
      this,
      NotifierProviderState<_FutureNotifier<T>, AsyncSnapshot<T>>(
        _FutureNotifier<T>(value),
      ),
    );
  }
}

class _FutureNotifier<T> extends PureNotifier<AsyncSnapshot<T>> {
  final Future<T> _future;

  _FutureNotifier(this._future, {String? debugLabel})
      : super(debugLabel: debugLabel) {
    state = const AsyncSnapshot.waiting();
    _future.then((value) {
      state = AsyncSnapshot.withData(ConnectionState.done, value);
    }).catchError((error) {
      state = AsyncSnapshot.withError(ConnectionState.done, error);
    });
  }

  @override
  AsyncSnapshot<T> init() {
    // We already initialized the state in the constructor.
    return state;
  }
}

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
    required R Function(Object? error, StackTrace? stackTrace) error,
  }) {
    switch (connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
      case ConnectionState.active:
        return loading();
      case ConnectionState.done:
        if (hasError) {
          return error(this.error, stackTrace);
        } else {
          return data(this.data as T);
        }
    }
  }
}
