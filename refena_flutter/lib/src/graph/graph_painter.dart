// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:refena/src/tools/graph_input_model.dart';
import 'package:refena_flutter/src/graph/graph_node.dart';
import 'package:refena_flutter/src/graph/graph_paint_constants.dart';

class GraphPainter extends CustomPainter {
  /// The graph data to be painted.
  final Graph _graph;

  /// The brightness of the app's overall theme.
  final Brightness _brightness;

  /// The animation value of the header.
  final double _headerAnimation;

  GraphPainter({
    required Graph graph,
    required Brightness brightness,
    required double headerAnimation,
  })  : _graph = graph,
        _brightness = brightness,
        _headerAnimation = headerAnimation;

  @override
  bool? hitTest(Offset position) {
    // improve performance by not checking hit test
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintNode = Paint()..color = Colors.blue;
    final paintEdge = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Number of layers of the services section
    final serviceLayerNodes =
        _graph.nodes.where((n) => n.section == Section.services).toList();
    final serviceLayerCount = serviceLayerNodes.isEmpty
        ? 0
        : 1 + serviceLayerNodes.map((n) => n.layer).reduce(max);

    final serviceLabel =
        serviceLayerCount <= 1 ? 'Services' : 'Services & Controllers';
    const viewModelsLabel = 'View Models';
    const widgetsLabel = 'Widgets';

    Section? section;

    for (final node in _graph.nodes) {
      final nodeY = node.position.dy + node.draggedY;

      // Draw section header
      if (section != node.section) {
        section = node.section;
        final label = switch (section) {
          Section.services => serviceLabel,
          Section.viewModels => viewModelsLabel,
          Section.widgets => widgetsLabel,
        };
        textPainter.text = TextSpan(
          text: label.substring(
            0,
            max(0, (_headerAnimation * label.length).ceil()),
          ),
          style: const TextStyle(fontSize: 24, color: Colors.grey, height: 1.2),
        );
        textPainter.layout();

        textPainter.paint(
          canvas,
          Offset(
            node.position.dx,
            -textPainter.height - 20,
          ),
        );
      }

      // Draw edges
      for (final child in node.children) {
        final childY = child.position.dy + child.draggedY;

        final path = Path();
        path.moveTo(
          child.position.dx,
          childY + child.labelHeight / 2 + GraphPaintConstants.verticalPadding,
        );

        final middleX = (child.position.dx +
                node.position.dx +
                GraphPaintConstants.typeCellWidth +
                GraphPaintConstants.typeRightPadding +
                node.labelWidth +
                GraphPaintConstants.endPadding) /
            2;

        final controlPoint1 = Offset(
          middleX - (middleX - child.position.dx) / 3,
          // Adjust this to change the control point's horizontal position relative to the child
          childY + child.labelHeight / 2 + GraphPaintConstants.verticalPadding,
        );

        final controlPoint2 = Offset(
          middleX +
              (node.position.dx +
                      GraphPaintConstants.typeCellWidth +
                      GraphPaintConstants.typeRightPadding +
                      node.labelWidth +
                      GraphPaintConstants.endPadding -
                      middleX) /
                  3,
          // Adjust this to change the control point's horizontal position relative to the parent
          nodeY + node.labelHeight / 2 + GraphPaintConstants.verticalPadding,
        );

        final endPoint = Offset(
          node.position.dx +
              GraphPaintConstants.typeCellWidth +
              GraphPaintConstants.typeRightPadding +
              node.labelWidth +
              GraphPaintConstants.endPadding,
          nodeY + node.labelHeight / 2 + GraphPaintConstants.verticalPadding,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          endPoint.dx,
          endPoint.dy,
        );

        paintEdge.color = switch (node.selected || child.selected) {
          true => Colors.red,
          false =>
            _brightness == Brightness.light ? Colors.black : Colors.white,
        };
        canvas.drawPath(path, paintEdge);
      }

      // Draw node

      if (node.selected ||
          node.parents.any((p) => p.selected) ||
          node.children.any((c) => c.selected)) {
        // draw red border
        paintNode.color = Colors.red;

        const borderWidth = 2.0;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              node.position.dx - borderWidth,
              nodeY - borderWidth,
              GraphPaintConstants.typeCellWidth +
                  GraphPaintConstants.typeRightPadding +
                  node.labelWidth +
                  GraphPaintConstants.endPadding +
                  borderWidth * 2,
              node.labelHeight +
                  GraphPaintConstants.verticalPadding * 2 +
                  borderWidth * 2,
            ),
            const Radius.circular(12),
          ),
          paintNode,
        );
      }

      final nodeColor = switch (node.node.type) {
        InputNodeType.view => Colors.green,
        InputNodeType.redux => Colors.red.shade700,
        InputNodeType.immutable || InputNodeType.future => Colors.blue.shade800,
        InputNodeType.widget => Colors.purple,
        InputNodeType.notifier => Colors.orange.shade700,
      };
      final totalHeight =
          node.labelHeight + GraphPaintConstants.verticalPadding * 2;
      paintNode.color = nodeColor;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            node.position.dx + GraphPaintConstants.typeCellWidth,
            nodeY,
            GraphPaintConstants.typeRightPadding +
                node.labelWidth +
                GraphPaintConstants.endPadding,
            totalHeight,
          ),
          topRight: const Radius.circular(10),
          bottomRight: const Radius.circular(10),
        ),
        paintNode,
      );

      paintNode.color = switch (node.node.type) {
        InputNodeType.view => Colors.green.shade200,
        InputNodeType.redux => Colors.red.shade200,
        InputNodeType.immutable || InputNodeType.future => Colors.blue.shade200,
        InputNodeType.widget => Colors.purple.shade200,
        InputNodeType.notifier => Colors.orange.shade200,
      };
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            node.position.dx,
            nodeY,
            GraphPaintConstants.typeCellWidth,
            node.labelHeight + GraphPaintConstants.verticalPadding * 2,
          ),
          topLeft: const Radius.circular(10),
          bottomLeft: const Radius.circular(10),
        ),
        paintNode,
      );

      textPainter.text = TextSpan(
        text: switch (node.node.type) {
          InputNodeType.view => 'V',
          InputNodeType.redux => 'R',
          InputNodeType.immutable => 'P',
          InputNodeType.future => 'F',
          InputNodeType.widget => 'W',
          InputNodeType.notifier => 'N',
        },
        style: TextStyle(
          color: nodeColor,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      );
      textPainter.layout();
      const leftPadding = 2;
      textPainter.paint(
        canvas,
        Offset(
          node.position.dx +
              leftPadding +
              (GraphPaintConstants.typeCellWidth -
                      textPainter.width -
                      leftPadding) /
                  2,
          nodeY + (totalHeight - textPainter.height) / 2,
        ),
      );

      textPainter.text = TextSpan(
        text: node.node.label,
        style: const TextStyle(color: Colors.white, height: 1),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          node.position.dx +
              GraphPaintConstants.typeCellWidth +
              GraphPaintConstants.typeRightPadding,
          nodeY + (totalHeight - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(GraphPainter oldDelegate) {
    return oldDelegate._graph != _graph ||
        oldDelegate._headerAnimation != _headerAnimation;
  }
}
