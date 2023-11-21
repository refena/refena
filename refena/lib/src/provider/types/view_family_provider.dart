import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/types/view_provider.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/ref.dart';

typedef ViewFamilyBuilder<T, P> = T Function(WatchableRef ref, P param);

/// Similar to [ViewProvider] but with a parameter.
/// It is essentially a syntax sugar for ViewProvider<Map<P, T>>.
class ViewFamilyProvider<T, P>
    extends BaseProvider<FamilyNotifier<T, P, ViewProvider<T>>, Map<P, T>> {
  final ViewFamilyBuilder<T, P> _builder;
  final String Function(T state)? _describeState;

  ViewFamilyProvider(
    this._builder, {
    super.onChanged,
    String Function(T state)? describeState,
    String? debugLabel,
    super.debugVisibleInGraph = true,
  })  : _describeState = describeState,
        super(debugLabel: debugLabel ?? 'ViewFamilyProvider<$T, $P>');

  @override
  FamilyNotifier<T, P, ViewProvider<T>> createState(Ref ref) {
    return _buildFamilyNotifier(this, _builder, _describeState);
  }

  /// Overrides with a predefined value.
  ///
  /// {@category Initialization}
  ProviderOverride<FamilyNotifier<T, P, ViewProvider<T>>, Map<P, T>>
      overrideWithBuilder(
    ViewFamilyBuilder<T, P> builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (_) => _buildFamilyNotifier(this, builder, _describeState),
    );
  }

  /// Provide accessor for one parameter.
  FamilySelectedWatchable<
      ViewFamilyProvider<T, P>,
      ViewProvider<T>,
      FamilyNotifier<T, P, ViewProvider<T>>,
      ViewProviderNotifier<T>,
      T,
      P,
      T,
      T> call(P param) {
    return FamilySelectedWatchable(this, param, (map) => map[param]!);
  }
}

FamilyNotifier<T, P, ViewProvider<T>> _buildFamilyNotifier<T, P>(
  ViewFamilyProvider<T, P> provider,
  ViewFamilyBuilder<T, P> builder,
  String Function(T state)? describeState,
) {
  return FamilyNotifier<T, P, ViewProvider<T>>(
    (param) => ViewProvider<T>(
      (ref) => builder(ref, param),
      debugLabel: '${provider.debugLabel}($param)',
    ),
    describeState: describeState,
    debugLabel: provider.debugLabel,
  );
}
