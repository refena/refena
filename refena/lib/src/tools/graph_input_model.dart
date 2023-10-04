import 'package:meta/meta.dart';

@internal
enum InputNodeType {
  view,
  redux,
  immutable,
  future,
  widget,
  notifier,
}

/// A node used as input to the graph builder.
/// This is an intermediate node instance.
@internal
class InputNode {
  final InputNodeType type;
  final String label;
  final Set<InputNode> parents = {}; // set later
  final Set<InputNode> children = {}; // set later

  /// A temporary flag to mark nodes as visited.
  bool visited = false;

  InputNode({
    required this.type,
    required this.label,
  });

  @override
  String toString() =>
      '$label(parents: ${parents.length}, children: ${children.length})';
}
