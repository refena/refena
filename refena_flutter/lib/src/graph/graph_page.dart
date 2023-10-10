// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:refena/src/tools/graph_input_model.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';
import 'package:refena_flutter/src/graph/graph_node.dart';
import 'package:refena_flutter/src/graph/graph_page_controller.dart';
import 'package:refena_flutter/src/graph/graph_painter.dart';
import 'package:refena_flutter/src/graph/graph_painter_hit_test.dart';
import 'package:refena_flutter/src/graph/live_button.dart';

part 'graph_input_builder.dart';

class RefenaGraphPage extends StatelessWidget {
  final String title;
  final bool showWidgets;
  final GraphInputBuilder inputGraphBuilder;
  final EdgeInsets padding;

  const RefenaGraphPage({
    this.title = 'Refena Graph',
    this.showWidgets = false,
    this.inputGraphBuilder = const _StateGraphInputBuilder(),
    this.padding = const EdgeInsets.only(
      top: 160,
      left: 100,
      right: 100,
      bottom: 100,
    ),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RefenaScope(
      defaultRef: false,
      child: _RefenaGraphPage(
        outerRef: context.ref,
        title: title,
        showWidgets: showWidgets,
        inputGraphBuilder: inputGraphBuilder,
        padding: padding,
      ),
    );
  }
}

class _RefenaGraphPage extends StatefulWidget {
  final Ref outerRef;
  final String title;
  final bool showWidgets;
  final GraphInputBuilder inputGraphBuilder;
  final EdgeInsets padding;

  const _RefenaGraphPage({
    required this.outerRef,
    required this.title,
    required this.showWidgets,
    required this.inputGraphBuilder,
    required this.padding,
  });

  @override
  State<_RefenaGraphPage> createState() => _RefenaGraphPageState();
}

class _RefenaGraphPageState extends State<_RefenaGraphPage>
    with SingleTickerProviderStateMixin, Refena {
  late Graph _graph;
  bool _initialized = false;

  late bool _showWidgets = widget.showWidgets;
  final _controller = TransformationController();
  late AnimationController _animationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _zoomAnimation;
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

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.7, 1),
    );
    _zoomAnimation = Tween<double>(
      begin: min(widget.padding.horizontal, widget.padding.vertical),
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0, 0.8, curve: Curves.easeOutCubic),
    ));
    _animationController.addListener(() {
      _rescaleGraph(animation: _zoomAnimation.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _subscription?.cancel();
    _animationController.dispose();
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
    var inputNodes = widget.inputGraphBuilder.build(widget.outerRef);
    if (!_showWidgets) {
      inputNodes = inputNodes.withoutWidgets();
    }

    _graph = buildGraphFromNodes(inputNodes);

    if (resetZoom) {
      _rescaleGraph(animation: _zoomAnimation.value);
    }
  }

  void _rescaleGraph({double animation = 0}) {
    if (!_initialized) {
      return;
    }

    // Widget constraints
    final parentSize = _availableSize;

    final graphWidth = _graph.width + widget.padding.horizontal - animation;
    final graphHeight = _graph.height + widget.padding.vertical - animation;

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
    final brightness = Theme.of(context).brightness;
    final state = ref.watch(graphPageProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_subscription != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: LiveButton(
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
                    leading: const Icon(Icons.refresh),
                    title: Text('Reset'),
                  ),
                  value: 'reset',
                ),
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
                case 'reset':
                  _refresh(_showWidgets, resetZoom: true);
                  break;
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

          if (!_customZoom && !_animationController.isAnimating) {
            _rescaleGraph();
          }

          final screenSize = constraints.biggest;
          final inverseScale = 1 / _scale;
          final virtualWidth = screenSize.width * inverseScale;
          final virtualHeight = screenSize.height * inverseScale;
          return Stack(
            children: [
              InteractiveViewer(
                constrained: false,
                transformationController: _controller,
                boundaryMargin: EdgeInsets.symmetric(
                  horizontal: virtualWidth,
                  vertical: virtualHeight,
                ),
                // does not matter, adjust boundaryMargin
                minScale: 0.0001,
                maxScale: 2,
                onInteractionUpdate: (_) => _customZoom = true,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, _) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: widget.padding.top - _zoomAnimation.value / 2,
                        left: widget.padding.left - _zoomAnimation.value / 2,
                        right: widget.padding.right - _zoomAnimation.value / 2,
                        bottom:
                            widget.padding.bottom - _zoomAnimation.value / 2,
                      ),
                      child: SizedBox(
                        width: _graph.width,
                        height: _graph.height,
                        child: Center(
                          child: CustomPaint(
                            size: Size(virtualWidth, virtualHeight),
                            painter: GraphPainter(
                              graph: _graph,
                              brightness: brightness,
                              headerAnimation: _headerAnimation.value,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onPanStart: (details) {
                    state.selectedNode?.selected = true;
                    setState(() {});
                  },
                  onPanUpdate: (details) {
                    final scale = _controller.value[0];
                    final inverseScale = 1 / scale;
                    state.selectedNode?.draggedY +=
                        (details.delta.dy * inverseScale);
                    setState(() {});
                  },
                  onPanEnd: (details) async {
                    state.selectedNode?.selected = false;
                    setState(() {});
                  },
                  child: CustomPaint(
                    painter: GraphPainterHitTest(
                      graph: _graph,
                      transformationController: _controller,
                      graphPadding: widget.padding,
                      onNodeSelected: (node) {
                        if (state.selectedNode?.selected == true) {
                          return;
                        }

                        if (state.selectedNode != node) {
                          ref.notifier(graphPageProvider).selectNode(node);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
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
        label: node.label,
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
