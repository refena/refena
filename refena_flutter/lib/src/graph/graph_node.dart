part of 'graph_page.dart';

// ignore_for_file: invalid_use_of_internal_member

const horizontalPadding = 10;
const verticalPadding = 5;

class _Node {
  final Object key;
  final String label;
  final Set<_Node> parents;
  final Set<_Node> children;

  /// A temporary flag to mark nodes as visited.
  bool visited = false;

  _Node({
    required this.key,
    required this.label,
    required this.parents,
    required this.children,
  });

  @override
  String toString() {
    return label;
  }
}

/// A node assigned to a layer in the graph.
/// 0 is the leftmost layer (i.e. no parents).
/// This is an intermediate node instance.
class _LayeredNode {
  final _Node node;
  int layer;

  _LayeredNode({
    required this.node,
    required this.layer,
  });

  @override
  String toString() {
    return node.toString();
  }
}

enum _Section {
  /// Any node that does not fit into the other sections.
  services,

  /// Nodes that are [ViewProviderNotifier]s and have exactly one child of
  /// type [ElementRebuildable].
  viewModels,

  /// Nodes that are widgets
  widgets,
}

/// A node assigned to a position in the graph.
/// This is the final node position.
class _PositionedNode {
  final _Node node;
  final List<_PositionedNode> parents = []; // set later
  final List<_PositionedNode> children = []; // set later
  final _Section section;
  final int layer;
  Offset position;
  int indexY;
  final double labelWidth;
  final double labelHeight;

  _PositionedNode({
    required this.node,
    required this.section,
    required this.layer,
    required this.position,
    required this.indexY,
    required this.labelWidth,
    required this.labelHeight,
  });

  @override
  String toString() {
    return node.toString();
  }
}

class _Graph {
  final List<_PositionedNode> nodes;
  final double width;
  final double height;

  _Graph({
    required this.nodes,
    required this.width,
    required this.height,
  });
}

/// Builds the graph.
_Graph _buildGraphFromNodes(List<_Node> nodes) {
  final widgets = nodes
      .where((node) => node.key is ElementRebuildable)
      .toList(growable: false);

  final viewModels = nodes.where((node) {
    return node.key is ViewProviderNotifier &&
        node.children.length == 1 &&
        node.children.first.key is ElementRebuildable;
  }).toSet();

  final services = nodes
      .where((node) => node.key is BaseNotifier && !viewModels.contains(node))
      .toSet();

  final layeredServiceNodes = _buildLayers(services);

  const layerSpacing = 100.0;
  const nodeSpacing = 100.0;
  final textPainter = TextPainter(textDirection: TextDirection.ltr);

  final positionedNodes = <_PositionedNode>[];
  final nodeCountPerLayer = <int>[];
  int layer = 0;
  double x = 0;
  int y = 0;
  double maxWidth = 0; // the maximum width of the labels in the current layer
  for (final service in layeredServiceNodes) {
    if (service.layer > layer) {
      layer = service.layer;
      x += maxWidth + horizontalPadding * 2 + layerSpacing;
      maxWidth = 0;
      nodeCountPerLayer.add(y);
      y = 0;
    }

    textPainter.text = TextSpan(
      text: service.node.label,
    );
    textPainter.layout();

    maxWidth = max(maxWidth, textPainter.width);

    positionedNodes.add(_PositionedNode(
      node: service.node,
      section: _Section.services,
      layer: layer,
      position: Offset(x, y * nodeSpacing),
      indexY: y,
      labelWidth: textPainter.width,
      labelHeight: textPainter.height,
    ));

    y++;
  }

  if (maxWidth != 0) {
    layer++;
    x += maxWidth + horizontalPadding * 2 + layerSpacing;
    maxWidth = 0;
    nodeCountPerLayer.add(y);
    y = 0;
  }
  for (final viewModel in viewModels) {
    textPainter.text = TextSpan(
      text: viewModel.label,
    );
    textPainter.layout();

    maxWidth = max(maxWidth, textPainter.width);

    positionedNodes.add(_PositionedNode(
      node: viewModel,
      section: _Section.viewModels,
      layer: layer,
      position: Offset(x, y * nodeSpacing),
      indexY: y,
      labelWidth: textPainter.width,
      labelHeight: textPainter.height,
    ));

    y++;
  }

  if (maxWidth != 0) {
    layer++;
    x += maxWidth + horizontalPadding * 2 + layerSpacing;
    maxWidth = 0;
    nodeCountPerLayer.add(y);
    y = 0;
  }
  for (final widget in widgets) {
    textPainter.text = TextSpan(
      text: widget.label,
    );
    textPainter.layout();

    maxWidth = max(maxWidth, textPainter.width);

    positionedNodes.add(_PositionedNode(
      node: widget,
      section: _Section.widgets,
      layer: layer,
      position: Offset(x, y * nodeSpacing),
      indexY: y,
      labelWidth: textPainter.width,
      labelHeight: textPainter.height,
    ));

    y++;
  }
  nodeCountPerLayer.add(y);

  // Set children and parents
  for (final node in positionedNodes) {
    for (final parent in node.node.parents) {
      node.parents.add(positionedNodes.firstWhere((n) => n.node == parent));
    }
    for (final child in node.node.children) {
      final childIndex = positionedNodes.indexWhere((n) => n.node == child);
      if (childIndex != -1) {
        node.children.add(positionedNodes[childIndex]);
        continue;
      }
    }
  }

  // Optimize graph
  _optimizeGraph(
    nodes: positionedNodes,
    nodeCountPerLayer: nodeCountPerLayer,
    nodeSpacing: nodeSpacing,
  );

  return _Graph(
    nodes: positionedNodes,
    width: x + horizontalPadding * 2 + maxWidth,
    height: positionedNodes
            .reduce((value, element) =>
                value.position.dy > element.position.dy ? value : element)
            .position
            .dy +
        nodeSpacing,
  );
}

/// Minimizes edge crossings.
void _optimizeGraph({
  required List<_PositionedNode> nodes,
  required List<int> nodeCountPerLayer,
  required double nodeSpacing,
}) {
  // Layer order from most nodes to least nodes
  final layerOrder = List.generate(nodeCountPerLayer.length, (i) => i);
  layerOrder
      .sort((a, b) => nodeCountPerLayer[b].compareTo(nodeCountPerLayer[a]));

  final maxY = nodeCountPerLayer.reduce(max);

  final positionedNodes =
      nodes.where((n) => n.layer == layerOrder.first).toSet();
  for (final layerIndex in layerOrder.skip(1)) {
    final layerNodes = nodes.where((n) => n.layer == layerIndex).toList();
    final avgY = Map.fromEntries(layerNodes.map((n) {
      // avg y position of parents and children that reference this node
      final parents = n.parents.where((p) => positionedNodes.contains(p));
      final children = n.children.where((c) => positionedNodes.contains(c));
      final avgY = switch (parents.length + children.length) {
        0 => maxY / 2,
        _ => (parents.fold(0.0, (p, c) => p + c.indexY) +
                children.fold(0.0, (p, c) => p + c.indexY)) /
            (parents.length + children.length),
      };
      return MapEntry(n, avgY);
    }));

    if (layerNodes.any((n) => n.node.label == 'PersistenceService')) {
      print('AVG: $avgY');
    }

    // sort by avg y position
    layerNodes.sort((a, b) => avgY[a]!.compareTo(avgY[b]!));

    // assign new y positions
    final yPadding = ((maxY - layerNodes.length) / 2) * nodeSpacing;
    for (var i = 0; i < layerNodes.length; i++) {
      layerNodes[i].indexY = i;
      layerNodes[i].position = Offset(
        layerNodes[i].position.dx,
        i * nodeSpacing + yPadding,
      );
    }

    positionedNodes.addAll(layerNodes);
  }
}

List<_LayeredNode> _buildLayers(Set<_Node> nodes) {
  for (final node in nodes) {
    node.visited = false;
  }

  final sortedNodes = [
    ...nodes.where((node) => node.children.every((c) => !nodes.contains(c))),
  ];

  final queue = Queue<_Node>.from(sortedNodes);
  while (queue.isNotEmpty) {
    final node = queue.removeFirst();

    for (final child in node.parents) {
      if (child.visited) {
        // child is already in the queue, we don't need to add it again
        // but we move it to the end of the sorted list to ensure that
        // it is processed after its parents
        sortedNodes.remove(child);
        sortedNodes.add(child);
        queue.add(child);
      } else {
        // child is new, we add it to the queue and the sorted list
        child.visited = true;
        sortedNodes.add(child);
        queue.add(child);
      }
    }
  }

  final layerNodes = <_LayeredNode>[];
  int layer = 0;
  for (final node in sortedNodes) {
    if (layerNodes
        .any((n) => n.layer == layer && n.node.parents.contains(node))) {
      layer++;
    }

    layerNodes.add(_LayeredNode(
      node: node,
      layer: layer,
    ));
  }

  // invert layer numbers
  final maxLayer = layer;
  for (final node in layerNodes) {
    node.layer = maxLayer - node.layer;
  }

  // sort by layer
  layerNodes.sort((a, b) => a.layer.compareTo(b.layer));

  return layerNodes;
}
