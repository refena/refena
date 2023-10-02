import 'package:meta/meta.dart';
import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/types/notifier.dart';
import 'package:refena/src/provider/types/future_family_provider.dart';

/// The corresponding notifier for a [FutureFamilyProvider].
final class FutureFamilyProviderNotifier<T, P>
    extends Notifier<Map<P, AsyncValue<T>>> {
  final FutureBuilder<T, P> _future;

  FutureFamilyProviderNotifier(this._future, {super.debugLabel});

  @override
  Map<P, AsyncValue<T>> init() => {};

  /// Sets the future for the given parameter.
  @internal
  void startFuture(P param) async {
    if (state.containsKey(param)) {
      // already started
      return;
    }

    state = {
      ...state,
      param: AsyncValue<T>.loading(),
    };
    try {
      final value = await _future(ref, param);
      state = {
        ...state,
        param: AsyncValue<T>.withData(value),
      };
    } catch (error, stackTrace) {
      state = {
        ...state,
        param: AsyncValue<T>.withError(error, stackTrace),
      };
    }
  }
}
