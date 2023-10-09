part of 'graph_page.dart';

// ignore_for_file: invalid_use_of_internal_member

class _GraphPainter extends CustomPainter {
  /// The graph data to be painted.
  final _Graph _graph;

  /// The brightness of the app's overall theme.
  final Brightness _brightness;

  /// The animation value of the header.
  final double _headerAnimation;

  _GraphPainter({
    required _Graph graph,
    required Brightness brightness,
    required double headerAnimation,
  })  : _graph = graph,
        _brightness = brightness,
        _headerAnimation = headerAnimation;

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

    // Number of layers of the services section
    final serviceLayerNodes =
        _graph.nodes.where((n) => n.section == _Section.services).toList();
    final serviceLayerCount = serviceLayerNodes.isEmpty
        ? 0
        : 1 + serviceLayerNodes.map((n) => n.layer).reduce(max);

    final serviceLabel =
        serviceLayerCount <= 1 ? 'Services' : 'Services & Controllers';
    const viewModelsLabel = 'View Models';
    const widgetsLabel = 'Widgets';

    _Section? section;

    for (final node in _graph.nodes) {
      // Draw section header
      if (section != node.section) {
        section = node.section;
        final label = switch (section) {
          _Section.services => serviceLabel,
          _Section.viewModels => viewModelsLabel,
          _Section.widgets => widgetsLabel,
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
        final path = Path();
        path.moveTo(
          child.position.dx,
          child.position.dy + child.labelHeight / 2 + _verticalPadding,
        );

        final middleX = (child.position.dx +
                node.position.dx +
                _typeCellWidth +
                _typeRightPadding +
                node.labelWidth +
                _endPadding) /
            2;

        final controlPoint1 = Offset(
          middleX - (middleX - child.position.dx) / 3,
          // Adjust this to change the control point's horizontal position relative to the child
          child.position.dy + child.labelHeight / 2 + _verticalPadding,
        );

        final controlPoint2 = Offset(
          middleX +
              (node.position.dx +
                      _typeCellWidth +
                      _typeRightPadding +
                      node.labelWidth +
                      _endPadding -
                      middleX) /
                  3,
          // Adjust this to change the control point's horizontal position relative to the parent
          node.position.dy + node.labelHeight / 2 + _verticalPadding,
        );

        final endPoint = Offset(
          node.position.dx +
              _typeCellWidth +
              _typeRightPadding +
              node.labelWidth +
              _endPadding,
          node.position.dy + node.labelHeight / 2 + _verticalPadding,
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
      final totalHeight = node.labelHeight + _verticalPadding * 2;
      paintNode.color = nodeColor;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            node.position.dx + _typeCellWidth,
            node.position.dy,
            _typeRightPadding + node.labelWidth + _endPadding,
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
            _typeCellWidth,
            node.labelHeight + _verticalPadding * 2,
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
              (_typeCellWidth - textPainter.width - leftPadding) / 2,
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
          node.position.dx + _typeCellWidth + _typeRightPadding,
          node.position.dy + (totalHeight - textPainter.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) {
    return oldDelegate._graph != _graph ||
        oldDelegate._headerAnimation != _headerAnimation;
  }
}
