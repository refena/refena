import 'package:flutter/material.dart';
import 'package:refena/refena.dart';
import 'package:refena_flutter/src/extension.dart';

/// A [Consumer] can be used anywhere in the widget tree.
/// This is useful if you want to use a provider within a [StatelessWidget].
///
/// Add a [debugLabel] or [debugParent] for better logging.
class Consumer extends StatelessWidget {
  final String debugLabel;
  final Widget Function(
    BuildContext context,
    WatchableRef ref,
  ) builder;

  Consumer({
    super.key,
    String? debugLabel,
    Widget? debugParent,
    required this.builder,
  }) : debugLabel =
            debugLabel ?? debugParent?.runtimeType.toString() ?? 'Consumer';

  @override
  Widget build(BuildContext context) {
    return builder(context, context.ref);
  }
}

/// Similar to [Consumer] but with a [child]
/// that is not rebuilt when the provider changes.
/// This is useful if the [child] is expensive to build.
///
/// Add a [debugLabel] or [debugParent] for better logging.
class ExpensiveConsumer extends StatelessWidget {
  final String debugLabel;
  final Widget? child;
  final Widget Function(
    BuildContext context,
    WatchableRef ref,
    Widget? child,
  ) builder;

  ExpensiveConsumer({
    super.key,
    String? debugLabel,
    Widget? debugParent,
    this.child,
    required this.builder,
  }) : debugLabel = debugLabel ??
            debugParent?.runtimeType.toString() ??
            'ExpensiveConsumer';

  @override
  Widget build(BuildContext context) {
    return builder(context, context.ref, child);
  }
}
