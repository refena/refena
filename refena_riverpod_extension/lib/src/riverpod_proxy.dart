// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

// ignore: implementation_imports
import 'package:refena/src/notifier/rebuildable.dart';

// ignore: implementation_imports
import 'package:refena/src/observer/observer.dart';
import 'package:refena_flutter/refena_flutter.dart' as refena;

class RiverpodProxy {
  final refena.Ref refenaRef;
  final riverpod.Ref riverpodRef;

  RiverpodProxy({
    required this.refenaRef,
    required this.riverpodRef,
  });

  /// Reads the value of a Riverpod provider.
  T read<T>(riverpod.ProviderListenable<T> provider) =>
      riverpodRef.read<T>(provider);
}

class RiverpodRebuildableProxy extends RiverpodProxy {
  final Rebuildable rebuildable;
  final Set<riverpod.ProviderListenable> _listening = {};

  RiverpodRebuildableProxy({
    required this.rebuildable,
    required super.refenaRef,
    required super.riverpodRef,
  });

  /// Reads the value of a Riverpod provider and
  /// rebuilds the [rebuildable] when the value changes.
  T watch<T>(riverpod.ProviderListenable<T> provider) {
    if (_listening.contains(provider)) {
      return riverpodRef.read<T>(provider);
    }

    _listening.add(provider);

    final observer = refenaRef.container.observer;
    final fakeNotifier = observer != null ? _RiverpodFakeNotifier<T>() : null;

    riverpod.ProviderSubscription<T>? subscription;
    subscription = riverpodRef.container.listen(
      provider,
      (previous, next) {
        if (rebuildable.disposed) {
          rebuildable.onDisposeWidget();
          subscription?.close();
          return;
        }

        refena.ChangeEvent<T>? changeEvent;
        if (observer != null && previous is T) {
          changeEvent = refena.ChangeEvent<T>(
            notifier: fakeNotifier!,
            action: null,
            prev: previous,
            next: next,
            rebuild: [rebuildable],
          );
          observer.dispatchEvent(changeEvent);
        }

        rebuildable.rebuild(
          changeEvent,
          null,
        );
      },
      fireImmediately: false,
    );

    return subscription.read();
  }
}

class _RiverpodFakeNotifier<T> extends refena.Notifier<T> {
  @override
  T init() => throw UnimplementedError();
}
