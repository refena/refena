import 'package:refena/src/async_value.dart';
import 'package:refena/src/notifier/family_notifier.dart';
import 'package:refena/src/notifier/types/notifier.dart';
import 'package:refena/src/provider/types/future_family_provider.dart';
import 'package:refena/src/reference.dart';

/// The corresponding notifier of a [FutureFamilyProvider].
final class FutureFamilyProviderNotifier<T, P>
    extends Notifier<Map<P, AsyncValue<T>>>
    implements FamilyNotifier<Map<P, AsyncValue<T>>, P> {
  final FutureBuilder<T, P> _future;
  final String Function(AsyncValue<T> state)? _describeState;

  FutureFamilyProviderNotifier(this._future,
      {String Function(AsyncValue<T> state)? describeState, super.debugLabel})
      : _describeState = describeState;

  @override
  Map<P, AsyncValue<T>> init() => {};

  @override
  bool isParamInitialized(P param) {
    return state.containsKey(param);
  }

  /// Sets the future for the given parameter.
  @override
  void initParam(P param) async {
    state = {
      ...state,
      param: AsyncValue<T>.loading(),
    };
    try {
      final value = await _future(ref, param);
      if (!state.containsKey(param)) {
        // disposed before the future completed
        return;
      }
      state = {
        ...state,
        param: AsyncValue<T>.data(value),
      };
    } catch (error, stackTrace) {
      if (!state.containsKey(param)) {
        // disposed before the future completed
        return;
      }
      state = {
        ...state,
        param: AsyncValue<T>.error(error, stackTrace),
      };
    }
  }

  @override
  void disposeParam(P param, LabeledReference? debugOrigin) {
    state.remove(param);
  }

  @override
  void dispose() {
    state.clear();
  }

  @override
  String describeState(Map<P, AsyncValue<T>> state) {
    if (_describeState != null) {
      return _describeMapState(state, _describeState!);
    } else {
      return _describeMapState(state, (value) => value.toString());
    }
  }
}

String _describeMapState<T, P>(
  Map<P, AsyncValue<T>> state,
  String Function(AsyncValue<T> state) describe,
) {
  return state.entries.map((e) => '${e.key}: ${describe(e.value)}').join(', ');
}
