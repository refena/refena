// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

// ignore: implementation_imports
import 'package:refena/src/proxy_ref.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_riverpod_extension/src/riverpod_proxy.dart';

/// Provides [Ref.riverpod] and [Ref.refena] for descendants.
/// This widget should be used at the root of the app right below
/// [ProviderScope] and [RefenaScope].
///
/// Example:
/// ProviderScope(
///   child: RefenaScope(
///     child: RefenaRiverpodExtensionScope(
///       child: MyApp(),
///     ),
///   ),
/// ),
class RefenaRiverpodExtensionScope extends riverpod.ConsumerWidget {
  final Widget child;

  const RefenaRiverpodExtensionScope({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final refenaRef = context.ref.container;
    final riverpodRef = refenaRef.read(_riverpodProvider)._ref;
    if (riverpodRef == null) {
      ref.read(_refenaProvider).setRef(ProxyRef(
            refenaRef,
            _bridgeName,
            LabeledReference.custom(_bridgeName),
          ));
      refenaRef.read(_riverpodProvider).setRef(RiverpodProxy(
            refenaRef: refenaRef,
            riverpodRef:
                ref.read(_dummyRiverpodNotifierProvider.notifier).getRef(),
          ));
    }
    return child;
  }
}

const _bridgeName = 'RiverpodBridge';

final _riverpodProvider = Provider<_RiverpodContainer>((ref) {
  return _RiverpodContainer();
}, debugLabel: _bridgeName);

class _RiverpodContainer {
  RiverpodProxy? _ref;

  // Non-Reactive for better performance.
  void setRef(RiverpodProxy ref) {
    _ref = ref;
  }
}

final _refenaProvider = riverpod.Provider<_RefenaContainer>((ref) {
  return _RefenaContainer();
});

class _RefenaContainer {
  Ref? _ref;

  // We don't want to update the state to avoid riverpod exceptions.
  // This is okay as the _refenaProvider is never watched.
  void setRef(ProxyRef ref) {
    _ref = ref;
  }
}

extension RefenaToRiverpodExt on Ref {
  /// Provides access to the Riverpod state.
  RiverpodProxy get riverpod {
    return _getRiverpodProxy(this);
  }
}

extension RefenaToRiverpodWatchableExt on WatchableRef {
  /// Since [WatchableRef] is dependent on the [Rebuildable],
  /// we cannot store it in a single provider but we need to
  /// store it in an [Expando] instead.
  static final _proxyCollection = Expando<RiverpodRebuildableProxy>();

  /// Provides access to the Riverpod state.
  /// Since you have a [WatchableRef], you can use [ref.watch] to
  /// rebuild the widget when the Riverpod provider changes.
  RiverpodRebuildableProxy get riverpod {
    return _proxyCollection[this] ??= RiverpodRebuildableProxy(
      refenaRef: container,
      riverpodRef: _getRiverpodProxy(this).riverpodRef,
      rebuildable: (this as WatchableRefImpl).rebuildable,
    );
  }
}

extension RiverpodToRefenaExt on riverpod.Ref {
  /// Provides access to the Refena state.
  /// Currently, there is no [ref.watch] equivalent, but you can
  /// use [ref.stream] to listen to the state changes.
  Ref get refena {
    final ref = read(_refenaProvider)._ref;
    if (ref == null) {
      throw StateError('Wrap your widget with a RefenaRiverpodExtensionScope');
    }
    return ref;
  }
}

RiverpodProxy _getRiverpodProxy(Ref ref) {
  final proxy = ref.read(_riverpodProvider)._ref;
  if (proxy == null) {
    throw StateError('Wrap your widget with a RefenaRiverpodExtensionScope');
  }
  return proxy;
}

final _dummyRiverpodNotifierProvider =
    riverpod.NotifierProvider<_DummyRiverpodNotifier, int>(() {
  return _DummyRiverpodNotifier();
});

class _DummyRiverpodNotifier extends riverpod.Notifier<int> {
  @override
  int build() => 0;

  riverpod.Ref getRef() {
    return ref;
  }
}
