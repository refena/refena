// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/provider/watchable.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Similar to [ViewModelBuilder], but designed for family providers
/// so that you can provide a parameter.
///
/// When this widget is disposed, only the parameter will be disposed instead
/// of the whole family (which is what [ViewModelBuilder] does).
class ViewModelParamBuilder<T, P, R> extends StatefulWidget {
  /// The provider to use.
  /// The [builder] will be called whenever this provider changes.
  final FamilySelectedWatchable<T, P, R> provider;

  /// This function is called **AFTER** the widget is built for the first time.
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

  ViewModelParamBuilder({
    super.key,
    required this.provider,
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
  State<ViewModelParamBuilder<T, P, R>> createState() =>
      _ViewModelParamBuilderState<T, P, R>();
}

class _ViewModelParamBuilderState<T, P, R>
    extends State<ViewModelParamBuilder<T, P, R>> with Refena {
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
