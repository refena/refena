// ignore_for_file: invalid_use_of_internal_member

import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:refena/src/tools/graph_input_model.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';

part 'graph_input_builder.dart';

part 'graph_node.dart';

part 'graph_painter.dart';

const _viewerPadding = EdgeInsets.only(
  top: 160,
  left: 100,
  right: 100,
  bottom: 100,
);

typedef InputGraphBuilder = List<InputNode> Function(
  Ref ref,
  void Function() refresher,
);

class RefenaGraphPage extends StatefulWidget {
  final String title;
  final bool showWidgets;
  final InputGraphBuilder inputGraphBuilder;

  const RefenaGraphPage({
    this.title = 'Refena Graph',
    this.showWidgets = false,
    this.inputGraphBuilder = _buildInputGraphFromState,
    super.key,
  });

  @override
  State<RefenaGraphPage> createState() => _RefenaGraphPageState();
}

class _RefenaGraphPageState extends State<RefenaGraphPage> with Refena {
  late _Graph _graph;
  bool _initialized = false;

  late bool _showWidgets = widget.showWidgets;
  final _controller = TransformationController();
  late Size _availableSize;
  late double _scale;

  @override
  void initState() {
    super.initState();

    ensureRef((ref) {
      _buildGraph();
      setState(() => _initialized = true);
    });
  }

  void _refresh(bool showWidgets, {required bool reset}) {
    setState(() {
      _showWidgets = showWidgets;
      if (reset) {
        _initialized = false;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildGraph();
      setState(() => _initialized = true);
    });
  }

  void _buildGraph() {
    var inputNodes = widget.inputGraphBuilder(
      ref,
      () => _refresh(_showWidgets, reset: false),
    );
    if (!_showWidgets) {
      inputNodes = inputNodes.withoutWidgets();
    }

    _graph = _buildGraphFromNodes(inputNodes);

    // Widget constraints
    final parentSize = _availableSize;

    final graphWidth = _graph.width + _viewerPadding.horizontal;
    final graphHeight = _graph.height + _viewerPadding.vertical;

    final widthFactor = parentSize.width / graphWidth;
    final heightFactor = parentSize.height / graphHeight;

    _scale = min(widthFactor, heightFactor);

    final w = ((graphWidth / 2) * _scale) - parentSize.width / 2;
    final h = ((graphHeight / 2) * _scale) - parentSize.height / 2;

    // Set the initial transform and center the canvas
    final initialTransform =
        Transform.translate(offset: Offset(-w, -h)).transform;
    _controller.value = initialTransform.clone()..scale(_scale);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.widgets),
                    trailing: _showWidgets
                        ? const Icon(Icons.check)
                        : const SizedBox.shrink(),
                    title: SizedBox(
                      width: 70,
                      child: Text('Widgets', softWrap: false),
                    ),
                  ),
                  value: 'widgets',
                ),
              ];
            },
            onSelected: (value) async {
              switch (value) {
                case 'widgets':
                  _refresh(!_showWidgets, reset: true);
                  break;
              }
            },
            child: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _availableSize = constraints.biggest;
          if (!_initialized) {
            return Container();
          }

          final screenSize = constraints.biggest;
          final inverseScale = 1 / _scale;
          final width = (screenSize.width - 50) * inverseScale;
          final height = (screenSize.height - 50) * inverseScale;
          return InteractiveViewer(
            constrained: false,
            transformationController: _controller,
            boundaryMargin: EdgeInsets.symmetric(
              horizontal: width,
              vertical: height,
            ),
            // does not matter, adjust boundaryMargin
            minScale: 0.0001,
            maxScale: 2,
            child: Padding(
              padding: _viewerPadding,
              child: SizedBox(
                width: _graph.width,
                height: _graph.height,
                child: Center(
                  child: CustomPaint(
                    size: Size(width, height),
                    painter: _GraphPainter(_graph),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension InputListExt on List<InputNode> {
  /// Returns a list of nodes without the widget nodes.
  /// It also removes the respective edges (children).
  List<InputNode> withoutWidgets() {
    final newNodes = <InputNode, InputNode>{};
    for (final node in this) {
      if (node.type == InputNodeType.widget) {
        continue;
      }
      newNodes[node] = InputNode(
        type: node.type,
        debugLabel: node.debugLabel,
      );
    }

    // Assign edges
    for (final entry in newNodes.entries) {
      final oldNode = entry.key;
      final newNode = entry.value;

      for (final parent in oldNode.parents) {
        final newNodeParent = newNodes[parent];
        if (newNodeParent == null) {
          continue;
        }
        newNode.parents.add(newNodeParent);
      }

      for (final child in oldNode.children) {
        final newNodeChild = newNodes[child];
        if (newNodeChild == null) {
          continue;
        }
        newNode.children.add(newNodeChild);
      }
    }

    return newNodes.values.toList();
  }
}
