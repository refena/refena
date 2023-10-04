part of 'graph_page.dart';

// ignore_for_file: invalid_use_of_internal_member

const typeCellWidth = 25.0;
const typeRightPadding = 5;
const endPadding = 5;
const verticalPadding = 5;

/// A node assigned to a layer in the graph.
/// 0 is the leftmost layer (i.e. no parents).
/// This is an intermediate node instance.
class _LayeredNode {
  final InputNode node;
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
  final InputNode node;
  final List<_PositionedNode> parents = []; // set later
  final List<_PositionedNode> children = []; // set later
  final _Section section;
  final int layer;
  Offset position;

  /// The index of the node in the layer.
  /// Only used for internal calculations.
  /// Might have different resolutions (1 = 1/2 node spacing).
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
_Graph _buildGraphFromNodes(List<InputNode> nodes) {
  final widgets = nodes
      .where((node) => node.type == InputNodeType.widget)
      .toList(growable: false);

  final viewModels = nodes.where((node) {
    return node.type == InputNodeType.view &&
        node.children.length == 1 &&
        node.children.first.type == InputNodeType.widget;
  }).toSet();

  final services = nodes
      .where((node) =>
          node.type != InputNodeType.widget && !viewModels.contains(node))
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
  const constantWidth =
      typeCellWidth + typeRightPadding + endPadding + layerSpacing;
  for (final service in layeredServiceNodes) {
    if (service.layer > layer) {
      layer = service.layer;
      x += maxWidth + constantWidth;
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
    x += maxWidth + constantWidth;
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
    x += maxWidth + constantWidth;
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
    width: x + constantWidth,
    height: positionedNodes.isEmpty
        ? 0
        : positionedNodes
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

  // These nodes have been positioned, only consider them for optimization
  // The layer with the most nodes is already positioned
  final positionedNodes =
      nodes.where((n) => n.layer == layerOrder.first).toSet();

  // We double the number of nodes per layer for better UI
  final maxNodesPerLayer = positionedNodes.length * 2;
  final halfNodeSpacing = nodeSpacing / 2;

  for (final layerIndex in layerOrder.skip(1)) {
    final layerNodes = nodes.where((n) => n.layer == layerIndex).toList();
    final List<bool> takenY = List.filled(maxNodesPerLayer, false);
    final List<int> leftOver = [];
    for (int i = 0; i < layerNodes.length; i++) {
      final node = layerNodes[i];
      final parents = node.parents.where((p) => positionedNodes.contains(p));
      final children = node.children.where((c) => positionedNodes.contains(c));

      // avg y position of parents and children that reference this node
      final avgY = switch (parents.length + children.length) {
        0 => maxY / 2,
        _ => (parents.fold(0.0, (p, c) => p + c.indexY) +
                children.fold(0.0, (p, c) => p + c.indexY)) /
            (parents.length + children.length),
      };

      final indexY = (avgY * 2).round();

      if (takenY[indexY]) {
        leftOver.add(i);
        continue;
      }

      takenY[indexY] = true;
      node.indexY = indexY;
      node.position = Offset(
        node.position.dx,
        indexY * halfNodeSpacing,
      );
    }

    // Left over nodes will take the first available position
    for (final i in leftOver) {
      final node = layerNodes[i];
      final freeIndex = takenY.indexWhere((b) => !b);
      takenY[freeIndex] = true;
      node.indexY = freeIndex;
      node.position = Offset(
        node.position.dx,
        freeIndex * halfNodeSpacing,
      );
    }

    positionedNodes.addAll(layerNodes);
  }
}

List<_LayeredNode> _buildLayers(Set<InputNode> nodes) {
  for (final node in nodes) {
    node.visited = false;
  }

  final sortedNodes = [
    ...nodes.where((node) => node.children.every((c) => !nodes.contains(c))),
  ];

  final queue = Queue<InputNode>.from(sortedNodes);
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
