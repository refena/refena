// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
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

class RefenaGraphPage extends StatefulWidget {
  final String title;
  final bool showWidgets;
  final GraphInputBuilder inputGraphBuilder;

  const RefenaGraphPage({
    this.title = 'Refena Graph',
    this.showWidgets = false,
    this.inputGraphBuilder = const _StateGraphInputBuilder(),
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

  /// If true, then the user has manually zoomed in or out.
  /// The zoom will not be reset when the graph is refreshed.
  bool _customZoom = false;

  StreamSubscription? _subscription;

  /// If true, then the graph is not refreshed, even if a new stream event
  /// is received.
  bool _livePaused = false;

  @override
  void initState() {
    super.initState();

    ensureRef((ref) {
      _buildGraph(resetZoom: true);
      setState(() => _initialized = true);
      final stream = widget.inputGraphBuilder.refreshStream;
      if (stream != null) {
        _subscription = stream.listen((_) {
          if (_livePaused) {
            return;
          }
          _refreshFromStream();
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _refreshFromStream() {
    _refresh(_showWidgets, resetZoom: _customZoom ? false : true);
  }

  void _refresh(bool showWidgets, {required bool resetZoom}) {
    setState(() {
      _showWidgets = showWidgets;
      if (resetZoom) {
        _initialized = false;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildGraph(resetZoom: resetZoom);
      setState(() {
        if (resetZoom) {
          _customZoom = false;
        }
        _initialized = true;
      });
    });
  }

  void _buildGraph({required bool resetZoom}) {
    var inputNodes = widget.inputGraphBuilder.build(ref);
    if (!_showWidgets) {
      inputNodes = inputNodes.withoutWidgets();
    }

    _graph = _buildGraphFromNodes(inputNodes);

    if (resetZoom) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_subscription != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _LiveButton(
                live: !_livePaused,
                onTap: () {
                  final oldPaused = _livePaused;
                  setState(() => _livePaused = !_livePaused);
                  if (oldPaused) {
                    _refreshFromStream();
                  }
                },
              ),
            ),
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
                  _refresh(!_showWidgets, resetZoom: true);
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
            onInteractionUpdate: (_) => _customZoom = true,
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

class _LiveButton extends StatelessWidget {
  final bool live;
  final void Function() onTap;

  const _LiveButton({
    required this.live,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor:
            live ? Colors.red : Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: onTap,
      child: Row(
        children: [
          if (live)
            // red dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            )
          else
            const Icon(Icons.pause),
          const SizedBox(width: 10),
          Text(live ? 'Live' : 'Paused'),
        ],
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
