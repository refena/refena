import 'package:flutter/material.dart';
import 'package:riverpie/src/mixin.dart';
import 'package:riverpie/src/ref.dart';

/// A [Consumer] can be used anywhere in the widget tree.
/// This is useful if you want to use a provider within a [StatelessWidget].
///
/// You can pass a [child] that should not be rebuilt when the provider changes.
/// This is useful if the [child] is expensive to build.
class Consumer extends StatefulWidget {
  final Widget? child;
  final Widget Function(
    BuildContext context,
    WatchableRef ref,
    Widget? child,
  ) builder;

  const Consumer({
    super.key,
    this.child,
    required this.builder,
  });

  @override
  State<Consumer> createState() => _ConsumerState();
}

class _ConsumerState extends State<Consumer> with Riverpie {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, ref, widget.child);
  }
}
