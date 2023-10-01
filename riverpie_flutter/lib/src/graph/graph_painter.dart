part of 'graph_page.dart';

class _GraphPainter extends CustomPainter {
  final _Graph _graph;

  _GraphPainter(this._graph);

  @override
  void paint(Canvas canvas, Size size) {
    final paintNode = Paint()..color = Colors.blue;
    final paintEdge = Paint()
      ..color = Colors.black
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
                node.labelWidth +
                horizontalPadding * 2) /
            2;

        final controlPoint1 = Offset(
          middleX - (middleX - child.position.dx) / 3,
          // Adjust this to change the control point's horizontal position relative to the child
          child.position.dy + child.labelHeight / 2 + verticalPadding,
        );

        final controlPoint2 = Offset(
          middleX +
              (node.position.dx +
                      node.labelWidth +
                      horizontalPadding * 2 -
                      middleX) /
                  3,
          // Adjust this to change the control point's horizontal position relative to the parent
          node.position.dy + node.labelHeight / 2 + verticalPadding,
        );

        final endPoint = Offset(
          node.position.dx + node.labelWidth + horizontalPadding * 2,
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
      textPainter.text = TextSpan(
        text: node.node.label,
        style: const TextStyle(color: Colors.white, height: 1),
      );
      textPainter.layout();

      paintNode.color = switch (node.section) {
        _Section.services => switch (node.node.key) {
            ViewProviderNotifier() => Colors.green,
            ImmutableNotifier() ||
            FutureProviderNotifier() ||
            FutureFamilyProviderNotifier() =>
              Colors.blue.shade800,
            ReduxNotifier() => Colors.red.shade700,
            _ => Colors.orange.shade700,
          },
        _Section.viewModels => Colors.green,
        _Section.widgets => Colors.purple,
      };
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              node.position.dx + node.labelWidth / 2 + horizontalPadding,
              node.position.dy + textPainter.height / 2 + verticalPadding,
            ),
            width: node.labelWidth + horizontalPadding * 2,
            height: textPainter.height + verticalPadding * 2,
          ),
          Radius.circular(10),
        ),
        paintNode,
      );

      textPainter.paint(
        canvas,
        Offset(
          node.position.dx + horizontalPadding,
          node.position.dy + verticalPadding,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
