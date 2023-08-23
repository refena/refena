import 'package:meta/meta.dart';
import 'package:riverpie/src/container.dart';
import 'package:riverpie/src/notifier/rebuildable.dart';
import 'package:riverpie/src/notifier/types/pure_notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';
import 'package:riverpie/src/util/batched_stream_controller.dart';

final class ViewProviderNotifier<T> extends PureNotifier<T>
    implements Rebuildable {
  ViewProviderNotifier(this.builder, {super.debugLabel});

  late final WatchableRef watchableRef;
  final T Function(WatchableRef) builder;
  final _rebuildController = BatchedStreamController();

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
  void internalSetup(RiverpieContainer container, RiverpieObserver? observer) {
    watchableRef = WatchableRef(
      ref: container,
      rebuildable: this,
    );
    super.internalSetup(container, observer);
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
