// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/watchable.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// A widget that uses exactly one provider to build the widget tree.
/// On widget dispose, the provider will be disposed as well.
///
/// Family providers should use [FamilyViewModelBuilder] instead.
///
/// To avoid disposing the provider, set [disposeProvider] to false.
class ViewModelBuilder<T, R> extends StatefulWidget {
  /// The provider to use.
  /// The [builder] will be called whenever this provider changes.
  final Watchable<BaseNotifier<T>, T, R> provider;

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

  ViewModelBuilder({
    super.key,
    required this.provider,
    this.initBuild,
    this.init,
    this.dispose,
    this.disposeProvider = true,
    this.placeholder,
    this.error,
    String? debugLabel,
    Widget? debugParent,
    required this.builder,
  }) : debugLabel = debugLabel ??
            debugParent?.runtimeType.toString() ??
            'ViewModelBuilder<$T>';

  @override
  State<ViewModelBuilder<T, R>> createState() => _ViewModelBuilderState<T, R>();

  /// Returns the family version of this widget.
  /// See [FamilyViewModelBuilder] for more information.
  static FamilyViewModelBuilder<T, P, R> family<T, P, R>({
    Key? key,
    required FamilySelectedWatchable<T, P, R> provider,
    void Function(BuildContext context, Ref ref)? initBuild,
    FutureOr<void> Function(BuildContext context, Ref ref)? init,
    void Function(Ref ref)? dispose,
    bool? disposeProvider,
    Widget Function(BuildContext context)? placeholder,
    Widget Function(
      BuildContext context,
      Object error,
      StackTrace stackTrace,
    )? error,
    String? debugLabel,
    Widget? debugParent,
    required Widget Function(BuildContext context, R vm) builder,
  }) {
    return FamilyViewModelBuilder<T, P, R>(
      key: key,
      provider: provider,
      initBuild: initBuild,
      init: init,
      dispose: dispose,
      disposeProvider: disposeProvider,
      placeholder: placeholder,
      error: error,
      debugLabel: debugLabel,
      debugParent: debugParent,
      builder: builder,
    );
  }
}

class _ViewModelBuilderState<T, R> extends State<ViewModelBuilder<T, R>>
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
      ref.dispose(widget.provider.provider);
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
