import 'dart:async';

import 'package:meta/meta.dart';
import 'package:riverpie/src/listener.dart';
import 'package:riverpie/src/notifier.dart';
import 'package:riverpie/src/observer/observer.dart';
import 'package:riverpie/src/ref.dart';

@internal
class ViewProviderNotifier<T> extends PureNotifier<T> {
  late final WatchableRef watchableRef;
  final T Function(WatchableRef) builder;

  final _rebuildController = StreamController<void>();
  final _subscriptions = <BaseNotifier, StreamSubscription>{};

  ViewProviderNotifier(this.builder);

  @override
  T init() {
    _rebuildController.stream.listen((_) {
      // cancel all subscriptions
      _subscriptions.forEach((_, subscription) {
        subscription.cancel();
      });
      _subscriptions.clear();

      // rebuild notifier state
      state = builder(watchableRef);
    });
    return builder(watchableRef);
  }

  @internal
  @override
  void preInit(Ref ref, RiverpieObserver? observer) {
    watchableRef = ProviderWatchableRef(
      ref: ref,
      notifier: this,
    );
    super.preInit(ref, observer);
  }

  void rebuildOnNotifierChange<N extends BaseNotifier<T2>, T2>(
    N notifier,
    ListenerConfig<T2> config,
  ) {
    if (_subscriptions.containsKey(notifier)) {
      return;
    }

    _subscriptions[notifier] = notifier.getStream().listen((event) {
      if (config.selector != null &&
          !config.selector!(event.prev, event.next)) {
        return;
      }

      if (config.callback != null) {
        config.callback!(event.prev, event.next);
      }

      // rebuild notifier state
      _rebuildController.add(null);
    });
  }
}
