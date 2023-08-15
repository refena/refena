import 'package:meta/meta.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/notifier/types/pure_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';
import 'package:riverpie/src/util/batched_stream_controller.dart';
import 'package:riverpie/src/widget/scope.dart';

@internal
class ViewProviderNotifier<T> extends PureNotifier<T> implements Rebuildable {
  late final WatchableRef watchableRef;
  final T Function(WatchableRef) builder;

  final _rebuildController = BatchedStreamController();

  ViewProviderNotifier(this.builder, {String? debugLabel})
      : super(debugLabel: debugLabel);

  @override
  T init() {
    _rebuildController.stream.listen((_) {
      // rebuild notifier state
      state = builder(watchableRef);
    });
    return builder(watchableRef);
  }

  @internal
  @override
  void setup(RiverpieScope scope, RiverpieObserver? observer) {
    watchableRef = WatchableRef.fromRebuildable(
      ref: scope,
      rebuildable: this,
    );
    super.setup(scope, observer);
  }

  @override
  void rebuild() {
    _rebuildController.schedule();
  }

  @override
  bool get disposed => false;

  @override
  String get debugLabel => super.debugLabel ?? runtimeType.toString();
}
