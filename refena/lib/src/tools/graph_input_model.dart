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
  final String debugLabel;
  final Set<InputNode> parents = {}; // set later
  final Set<InputNode> children = {}; // set later

  /// A temporary flag to mark nodes as visited.
  bool visited = false;

  InputNode({
    required this.type,
    required this.debugLabel,
  }) : label = switch (type) {
          InputNodeType.view => 'V | $debugLabel',
          InputNodeType.redux => 'R | $debugLabel',
          InputNodeType.immutable => 'P | $debugLabel',
          InputNodeType.future => 'F | $debugLabel',
          InputNodeType.widget => 'W | $debugLabel',
          InputNodeType.notifier => 'N | $debugLabel',
        };

  @override
  String toString() =>
      '$debugLabel(parents: ${parents.length}, children: ${children.length})';
}

extension InputListExt on List<InputNode> {
  /// Returns a list of nodes without the widget nodes.
  /// It also removes the respective edges (children).
  List<InputNode> withoutWidgets() {
    return where((node) => node.type != InputNodeType.widget).map((n) {
      n.children.removeWhere((child) => child.type == InputNodeType.widget);
      return n;
    }).toList();
  }
}
