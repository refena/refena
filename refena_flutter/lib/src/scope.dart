// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:refena/refena.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/base_provider.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/watchable.dart';

/// A wrapper widget around [RefenaContainer].
class RefenaScope extends StatefulWidget implements RefenaContainer {
  RefenaScope._({
    super.key,
    required RefenaContainer container,
    required this.implicitContainer,
    required this.ownsContainer,
    required bool defaultRef,
    required this.child,
  })  : _container = container,
        _defaultRef = defaultRef;

  /// Creates a [RefenaScope].
  /// It will create an implicit [RefenaContainer] that will be disposed
  /// when the [RefenaScope] is disposed.
  ///
  /// The [platformHint] gives the container a hint about the platform.
  /// This abstraction is used by the inspector that does not depend on
  /// Flutter.
  ///
  /// The [overrides] are used to override providers with a different value.
  /// The [initialProviders] are used to initialize providers right away.
  /// Otherwise, the providers are initialized lazily when they are accessed.
  /// The [defaultNotifyStrategy] defines when widgets and providers
  /// are notified to rebuild.
  /// The [observers] are used to observe events.
  /// The [child] is the widget tree that is wrapped by the [RefenaScope].
  RefenaScope({
    Key? key,
    PlatformHint? platformHint,
    List<ProviderOverride> overrides = const [],
    List<BaseProvider> initialProviders = const [],
    NotifyStrategy defaultNotifyStrategy = NotifyStrategy.identity,
    List<RefenaObserver> observers = const [],
    bool defaultRef = true,
    required Widget child,
  }) : this._(
          key: key,
          container: RefenaContainer(
            platformHint: platformHint ?? RefenaScope.getPlatformHint(),
            overrides: overrides,
            initialProviders: initialProviders,
            defaultNotifyStrategy: defaultNotifyStrategy,
            observers: observers,
            initImmediately: false,
          ),
          implicitContainer: true,
          ownsContainer: true,
          defaultRef: defaultRef,
          child: child,
        );

  /// Creates a [RefenaScope] that uses an existing [RefenaContainer].
  /// By default, the [RefenaScope] will dispose the [RefenaContainer]
  /// when the [RefenaScope] itself is disposed.
  /// To prevent this, set [ownsContainer] to false.
  factory RefenaScope.withContainer({
    Key? key,
    required RefenaContainer container,
    PlatformHint? platformHint,
    bool ownsContainer = true,
    bool defaultRef = true,
    required Widget child,
  }) {
    return RefenaScope._(
      key: key,
      container: container
        ..platformHint = platformHint ??
            (container.platformHint == PlatformHint.unknown
                ? RefenaScope.getPlatformHint()
                : container.platformHint),
      implicitContainer: false,
      ownsContainer: ownsContainer,
      defaultRef: defaultRef,
      child: child,
    );
  }

  /// If you are unable to access the [ref] for whatever reason,
  /// there is a pragmatic solution for that.
  /// This is considered bad practice and should only be used as a last resort.
  ///
  /// Usage:
  /// RefenaScope.defaultRef.read(myProvider);
  static late Ref defaultRef;

  /// Returns the [PlatformHint] for the current platform.
  /// This type is used to represent the platform type without depending
  /// on Flutter or dart:io.
  static PlatformHint getPlatformHint() {
    return PlatformHintProvider.instance.getPlatformHint();
  }

  /// The [RefenaContainer] that is used by this [RefenaScope].
  final RefenaContainer _container;

  /// Whether this [RefenaScope] created its own [RefenaContainer].
  final bool implicitContainer;

  /// Has ownership of the [RefenaContainer].
  /// This is used to dispose the [RefenaContainer] when the widget is disposed.
  final bool ownsContainer;

  /// The child widget
  final Widget child;

  final bool _defaultRef;

  /// Initializes the [RefenaContainer].
  @override
  void init() {
    if (implicitContainer) {
      throw UnsupportedError('init() is managed by RefenaScope');
    }
    _container.init();
  }

  /// The platform hint.
  @override
  PlatformHint get platformHint => _container.platformHint;

  /// Updates the platform hint.
  @override
  set platformHint(PlatformHint value) => _container.platformHint = value;

  /// The provided observer (e.g. for logging)
  @override
  RefenaObserver? get observer => _container.observer;

  /// The default notify strategy
  @override
  NotifyStrategy get defaultNotifyStrategy => _container.defaultNotifyStrategy;

  /// Whether the container has been disposed.
  @override
  bool get disposed => _container.disposed;

  /// Awaiting this future will ensure that all overrides are initialized.
  /// Calling it multiple times is safe.
  @override
  Future<void> ensureOverrides() {
    return _container.ensureOverrides();
  }

  /// Overrides a provider with a new value.
  /// This allows for overrides happening after the container was created.
  @override
  FutureOr<void> set(ProviderOverride override) {
    return _container.set(override);
  }

  /// Returns the actual value of a [Provider].
  @override
  R read<N extends BaseNotifier<T>, T, R>(BaseWatchable<N, T, R> watchable) {
    return _container.read(watchable);
  }

  /// Similar to [Ref.read], but instead of returning the state right away,
  /// it returns a [StateAccessor] to get the **latest** state later.
  ///
  /// This is useful if you need to use the latest state of a provider,
  /// but you can't use [Ref.watch] when building a notifier.
  @override
  StateAccessor<R> accessor<R>(
    BaseWatchable<BaseNotifier, dynamic, R> provider,
  ) {
    return _container.accessor(provider);
  }

  /// Returns the notifier of a [NotifierProvider].
  @override
  N notifier<N extends BaseNotifier<T>, T>(NotifyableProvider<N, T> provider) {
    return _container.notifier(provider);
  }

  /// Returns the notifier of a [NotifierProvider].
  /// This method is used internally without
  /// any [NotifyableProvider] constraints.
  @override
  N anyNotifier<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    return _container.anyNotifier(provider);
  }

  @override
  Dispatcher<N, T> redux<N extends ReduxNotifier<T>, T>(
    ReduxProvider<N, T> provider,
  ) {
    return Dispatcher(
      notifier: _container.anyNotifier(provider),
      debugOrigin: debugOwnerLabel,
      debugOriginRef: this,
    );
  }

  @override
  Stream<NotifierEvent<T>> stream<N extends BaseNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    return _container.stream(provider);
  }

  @override
  Future<T> future<N extends GetFutureNotifier<T>, T>(
    BaseProvider<N, AsyncValue<T>> provider,
  ) {
    return _container.future(provider);
  }

  @override
  void rebuild<N extends RebuildableNotifier<T>, T>(
    BaseProvider<N, T> provider,
  ) {
    _container.rebuild(provider);
  }

  @override
  void dispose<N extends BaseNotifier<T>, T>(BaseProvider<N, T> provider) {
    _container.dispose(provider);
  }

  @override
  void disposeFamilyParam<N extends FamilyNotifier<dynamic, P>, P>(
    BaseProvider<N, dynamic> provider,
    P param,
  ) {
    _container.disposeFamilyParam<N, P>(provider, param);
  }

  @override
  void message(String message) {
    _container.message(message);
  }

  @override
  RefenaContainer get container => _container;

  @override
  bool exists(BaseProvider provider) => _container.exists(provider);

  @override
  List<BaseProvider> getActiveProviders() => _container.getActiveProviders();

  @override
  List<BaseNotifier> getActiveNotifiers() => _container.getActiveNotifiers();

  @override
  void cleanupListeners() => _container.cleanupListeners();

  @override
  void disposeContainer() => _container.disposeContainer();

  @override
  String get debugOwnerLabel => 'RefenaScope';

  @override
  String get debugLabel => debugOwnerLabel;

  @override
  State<RefenaScope> createState() => _RefenaScopeState();
}

class _RefenaScopeState extends State<RefenaScope> {
  late RefenaContainer _container;

  @override
  void initState() {
    super.initState();

    _container = widget._container;
    if (widget.implicitContainer) {
      _container.init();
    }

    if (widget._defaultRef) {
      RefenaScope.defaultRef = _container;
    }
  }

  @override
  void dispose() {
    if (widget.ownsContainer) {
      _container.disposeContainer();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefenaInheritedWidget(
      container: _container,
      child: widget.child,
    );
  }
}

@internal
class RefenaInheritedWidget extends InheritedWidget {
  final RefenaContainer container;

  RefenaInheritedWidget({
    super.key,
    required this.container,
    required super.child,
  });

  @override
  bool updateShouldNotify(RefenaInheritedWidget oldWidget) {
    return false;
  }
}

@internal
class PlatformHintProvider {
  /// Not final for testing
  static PlatformHintProvider instance = PlatformHintProvider();

  /// Returns the [PlatformHint] for the current platform.
  PlatformHint getPlatformHint() {
    if (kIsWeb) {
      return PlatformHint.web;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => PlatformHint.android,
      TargetPlatform.iOS => PlatformHint.iOS,
      TargetPlatform.windows => PlatformHint.windows,
      TargetPlatform.macOS => PlatformHint.macOS,
      TargetPlatform.linux => PlatformHint.linux,
      _ => PlatformHint.unknown,
    };
  }
}
