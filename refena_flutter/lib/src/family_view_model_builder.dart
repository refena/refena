// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/base_provider.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/watchable.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Similar to [ViewModelBuilder], but designed for family providers.
///
/// When this widget is disposed, only the parameter will be disposed instead
/// of the whole family (which is what [ViewModelBuilder] does).
class FamilyViewModelBuilder<
    P extends BaseProvider<N, Map<F, T>>,
    P2 extends BaseProvider<N2, T>,
    N extends FamilyNotifier<T, F, P2>,
    N2 extends BaseNotifier<T>,
    T,
    F,
    R,
    B> extends StatefulWidget {
  /// The provider to use.
  /// The [builder] will be called whenever this provider changes.
  final FamilySelectedWatchable<P, P2, N, N2, T, F, R, B> provider;

  /// This function is called **BEFORE** the widget is built for the first time.
  /// It should not return a [Future].
  final void Function(BuildContext context, Ref ref)? initBuild;

  /// This function is called **AFTER** the widget is built for the first time.
  /// It can return a [Future].
  /// In this case, the widget will show the [placeholder] if provided.
  final FutureOr<void> Function(BuildContext context, Ref ref)? init;

  /// This function is called when the widget is removed from the tree.
  final void Function(Ref ref)? dispose;

  /// Whether to dispose the provider when the widget is removed from the tree.
  final bool disposeProvider;

  /// The widget to show while the provider is initializing.
  final Widget Function(BuildContext context)? placeholder;

  /// The widget to show if the initialization fails.
  final Widget Function(
    BuildContext context,
    Object error,
    StackTrace stackTrace,
  )? error;

  /// A debug label for better logging.
  final String debugLabel;

  /// The builder to build the widget tree.
  final Widget Function(BuildContext context, R vm) builder;

  FamilyViewModelBuilder({
    super.key,
    required this.provider,
    this.initBuild,
    this.init,
    this.dispose,
    bool? disposeProvider,
    this.placeholder,
    this.error,
    String? debugLabel,
    Widget? debugParent,
    required this.builder,
  })  : disposeProvider = disposeProvider ?? true,
        debugLabel = debugLabel ??
            debugParent?.runtimeType.toString() ??
            'ViewModelBuilder<$T>';

  @override
  State<FamilyViewModelBuilder<P, P2, N, N2, T, F, R, B>> createState() =>
      _FamilyViewModelBuilderState<P, P2, N, N2, T, F, R, B>();
}

class _FamilyViewModelBuilderState<
        P extends BaseProvider<N, Map<F, T>>,
        P2 extends BaseProvider<N2, T>,
        N extends FamilyNotifier<T, F, P2>,
        N2 extends BaseNotifier<T>,
        T,
        F,
        R,
        B> extends State<FamilyViewModelBuilder<P, P2, N, N2, T, F, R, B>>
    with Refena {
  bool _initialized = false;
  (Object, StackTrace)? _error; // use record for null-safety

  @override
  void initState() {
    super.initState();

    if (widget.init == null) {
      _initialized = true;
      return;
    }

    ensureRef((ref) async {
      try {
        final result = widget.init!(context, ref);
        if (result is Future) {
          await result;
        }
        if (mounted) {
          setState(() {
            _initialized = true;
          });
        }
      } catch (error, stackTrace) {
        if (mounted) {
          setState(() {
            _error = (error, stackTrace);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    if (widget.dispose != null) {
      widget.dispose!(ref);
    }
    if (widget.disposeProvider) {
      ref.disposeFamilyParam(widget.provider.provider, widget.provider.param);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.initBuild != null) {
      initialBuild((ref) => widget.initBuild!(context, ref));
    }

    final error = _error;
    if (error != null && widget.error != null) {
      return widget.error!(context, error.$1, error.$2);
    }
    if (!_initialized && widget.placeholder != null) {
      return widget.placeholder!(context);
    }

    return widget.builder(
      context,
      ref.watch(widget.provider),
    );
  }
}
