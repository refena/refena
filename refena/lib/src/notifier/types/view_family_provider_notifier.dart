import 'package:meta/meta.dart';
import 'package:refena/refena.dart';
import 'package:refena/src/notifier/family_notifier.dart';

/// The corresponding notifier of a [ViewFamilyProvider].
final class ViewFamilyProviderNotifier<T, P> extends Notifier<Map<P, T>>
    implements FamilyNotifier<Map<P, T>, P> {
  final ViewFamilyBuilder<T, P> _builder;
  final Map<P, ViewProvider<T>> _providers = {};
  final String Function(T state)? _describeState;

  ViewFamilyProviderNotifier(
    this._builder, {
    String Function(T state)? describeState,
    super.debugLabel,
  }) : _describeState = describeState;

  @override
  Map<P, T> init() => {};

  @override
  bool isParamInitialized(P param) {
    return state.containsKey(param);
  }

  @override
  void initParam(P param) {
    final provider = ViewProvider<T>(
      (ref) => _builder(ref, param),
      debugLabel: '$debugLabel($param)',
    );
    _providers[param] = provider;
    ref.stream(provider).map((event) => event.next).listen((value) {
      state = {
        ...state,
        param: value,
      };
    });
    state = {
      ...state,
      param: ref.read(provider),
    };
  }

  @override
  void disposeParam(P param) {
    final provider = _providers.remove(param);
    if (provider == null) {
      return;
    }
    ref.dispose(provider);
    state.remove(param);
  }

  @override
  void dispose() {
    for (final provider in _providers.values) {
      ref.dispose(provider);
    }
    _providers.clear();
    state.clear();
  }

  @visibleForTesting
  List<ViewProvider<T>> getTempProviders() {
    return _providers.values.toList();
  }

  @override
  String describeState(Map<P, T> state) {
    if (_describeState != null) {
      return _describeMapState(state, _describeState!);
    } else {
      return _describeMapState(state, (value) => value.toString());
    }
  }
}

String _describeMapState<T, P>(
  Map<P, T> state,
  String Function(T state) describe,
) {
  return state.entries.map((e) => '${e.key}: ${describe(e.value)}').join(', ');
}
