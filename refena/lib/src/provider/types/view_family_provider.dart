import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/override.dart';
import 'package:refena/src/provider/watchable.dart';
import 'package:refena/src/ref.dart';

typedef ViewFamilyBuilder<T, P> = T Function(WatchableRef ref, P param);

/// Similar to [ViewProvider] but with a parameter.
/// It is essentially a syntax sugar for ViewProvider<Map<P, T>>.
class ViewFamilyProvider<T, P>
    extends BaseProvider<ViewFamilyProviderNotifier<T, P>, Map<P, T>> {
  final ViewFamilyBuilder<T, P> _builder;
  final String Function(T state)? _describeState;

  ViewFamilyProvider(
    this._builder, {
    super.onChanged,
    String Function(T state)? describeState,
    String? debugLabel,
  })  : _describeState = describeState,
        super(debugLabel: debugLabel ?? 'ViewFamilyProvider<$T, $P>');

  @override
  ViewFamilyProviderNotifier<T, P> createState(Ref ref) {
    return ViewFamilyProviderNotifier<T, P>(
      _builder,
      describeState: _describeState,
      debugLabel: customDebugLabel ?? runtimeType.toString(),
    );
  }

  /// Overrides with a predefined value.
  ///
  /// {@category Initialization}
  ProviderOverride<ViewFamilyProviderNotifier<T, P>, Map<P, T>>
      overrideWithBuilder(
    ViewFamilyBuilder<T, P> builder,
  ) {
    return ProviderOverride(
      provider: this,
      createState: (_) => ViewFamilyProviderNotifier(
        builder,
        describeState: _describeState,
        debugLabel: customDebugLabel ?? runtimeType.toString(),
      ),
    );
  }

  /// Provide accessor for one parameter.
  FamilySelectedWatchable<Map<P, T>, P, T> call(P param) {
    return FamilySelectedWatchable(this, param, (map) => map[param]!);
  }
}
