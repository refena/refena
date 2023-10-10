// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:refena_flutter/src/graph/graph_node.dart';
import 'package:refena_flutter/src/graph/graph_paint_constants.dart';

class GraphPainterHitTest extends CustomPainter {
  /// The graph data to be painted.
  final Graph _graph;

  final TransformationController _controller;

  final EdgeInsets _graphPadding;

  final void Function(PositionedNode node) _onNodeSelected;

  GraphPainterHitTest({
    required Graph graph,
    required TransformationController transformationController,
    required EdgeInsets graphPadding,
    required void Function(PositionedNode node) onNodeSelected,
  })  : _graph = graph,
        _controller = transformationController,
        _graphPadding = graphPadding,
        _onNodeSelected = onNodeSelected;

  @override
  bool? hitTest(Offset position) {
    var local = _controller.toScene(position);
    local = Offset(
      local.dx - _graphPadding.left,
      local.dy - _graphPadding.top,
    );

    // detect collision with any graph node
    PositionedNode? selectedNode;
    for (final node in _graph.nodes) {
      final rect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy + node.draggedY,
        node.labelWidth +
            GraphPaintConstants.typeCellWidth +
            GraphPaintConstants.typeRightPadding +
            GraphPaintConstants.endPadding,
        node.labelHeight + GraphPaintConstants.verticalPadding * 2,
      );
      if (rect.contains(local)) {
        selectedNode = node;
        break;
      }
    }

    if (selectedNode != null) {
      _onNodeSelected(selectedNode);
      return true;
    } else {
      return false;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // do not paint anything
  }

  @override
  bool shouldRepaint(GraphPainterHitTest oldDelegate) {
    return false;
  }
}
