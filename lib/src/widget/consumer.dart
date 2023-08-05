import 'package:flutter/material.dart';
import 'package:riverpie/src/mixin.dart';
import 'package:riverpie/src/ref.dart';

/// A [Consumer] can be used anywhere in the widget tree.
/// This is useful if you want to use a provider within a [StatelessWidget].
class Consumer extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    WatchableRef ref,
  ) builder;

  const Consumer({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ExpensiveConsumer(
      builder: (context, ref, _) {
        return builder(context, ref);
      },
    );
  }
}

/// Similar to [Consumer] but with a [child]
/// that is not rebuilt when the provider changes.
/// This is useful if the [child] is expensive to build.
class ExpensiveConsumer extends StatefulWidget {
  final Widget? child;
  final Widget Function(
    BuildContext context,
    WatchableRef ref,
    Widget? child,
  ) builder;

  const ExpensiveConsumer({
    super.key,
    this.child,
    required this.builder,
  });

  @override
  State<ExpensiveConsumer> createState() => _ExpensiveConsumerState();
}

class _ExpensiveConsumerState extends State<ExpensiveConsumer> with Riverpie {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, ref, widget.child);
  }
}
