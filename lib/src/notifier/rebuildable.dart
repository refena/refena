import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:riverpie/src/widget/consumer.dart';

/// Something that can be rebuilt.
@internal
abstract class Rebuildable {
  /// Trigger a rebuild (in the next frame).
  void rebuild();

  /// Whether this [Rebuildable] is disposed and should be removed.
  bool get disposed;

  /// A debug label for this [Rebuildable].
  String get debugLabel;
}

/// A [Rebuildable] that rebuilds a [State].
@internal
class StateRebuildable extends Rebuildable {
  final State state;

  StateRebuildable(this.state);

  @override
  void rebuild() {
    // ignore: invalid_use_of_protected_member
    state.setState(() {});
  }

  @override
  bool get disposed => !state.mounted;

  @override
  String get debugLabel {
    final widget = state.widget;
    if (widget is ExpensiveConsumer) {
      return widget.debugLabel;
    }
    return widget.runtimeType.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StateRebuildable && identical(state, other.state);

  @override
  int get hashCode => state.hashCode;
}
