part of 'graph_page.dart';

// ignore_for_file: invalid_use_of_internal_member

class _GraphPainter extends CustomPainter {
  /// The graph data to be painted.
  final _Graph _graph;

  /// The brightness of the app's overall theme.
  final Brightness _brightness;

  _GraphPainter(this._graph, this._brightness);

  @override
  void paint(Canvas canvas, Size size) {
    final paintNode = Paint()..color = Colors.blue;
    final paintEdge = Paint()
      ..color = _brightness == Brightness.light ? Colors.black : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    _Section? section;

    for (final node in _graph.nodes) {
      // Draw section header
      if (section != node.section) {
        section = node.section;
        textPainter.text = TextSpan(
          text: switch (section) {
            _Section.services => 'Services',
            _Section.viewModels => 'View Models',
            _Section.widgets => 'Widgets',
          },
          style: const TextStyle(fontSize: 24, color: Colors.grey, height: 1),
        );
        textPainter.layout();

        textPainter.paint(
          canvas,
          Offset(
            node.position.dx,
            -50,
          ),
        );
      }

      // Draw edges
      for (final child in node.children) {
        final path = Path();
        path.moveTo(
          child.position.dx,
          child.position.dy + child.labelHeight / 2 + verticalPadding,
        );

        final middleX = (child.position.dx +
                node.position.dx +
                typeCellWidth +
                typeRightPadding +
                node.labelWidth +
                endPadding) /
            2;

        final controlPoint1 = Offset(
          middleX - (middleX - child.position.dx) / 3,
          // Adjust this to change the control point's horizontal position relative to the child
          child.position.dy + child.labelHeight / 2 + verticalPadding,
        );

        final controlPoint2 = Offset(
          middleX +
              (node.position.dx +
                      typeCellWidth +
                      typeRightPadding +
                      node.labelWidth +
                      endPadding -
                      middleX) /
                  3,
          // Adjust this to change the control point's horizontal position relative to the parent
          node.position.dy + node.labelHeight / 2 + verticalPadding,
        );

        final endPoint = Offset(
          node.position.dx +
              typeCellWidth +
              typeRightPadding +
              node.labelWidth +
              endPadding,
          node.position.dy + node.labelHeight / 2 + verticalPadding,
        );

        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          endPoint.dx,
          endPoint.dy,
        );

        canvas.drawPath(path, paintEdge);
      }

      // Draw node

      final nodeColor = switch (node.node.type) {
        InputNodeType.view => Colors.green,
        InputNodeType.redux => Colors.red.shade700,
        InputNodeType.immutable || InputNodeType.future => Colors.blue.shade800,
        InputNodeType.widget => Colors.purple,
        InputNodeType.notifier => Colors.orange.shade700,
      };
      final totalHeight = node.labelHeight + verticalPadding * 2;
      paintNode.color = nodeColor;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            node.position.dx + typeCellWidth,
            node.position.dy,
            typeRightPadding + node.labelWidth + endPadding,
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
            node.position.dy,
            typeCellWidth,
            node.labelHeight + verticalPadding * 2,
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
              (typeCellWidth - textPainter.width - leftPadding) / 2,
          node.position.dy + (totalHeight - textPainter.height) / 2,
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
          node.position.dx + typeCellWidth + typeRightPadding,
          node.position.dy + (totalHeight - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
