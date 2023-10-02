// ignore_for_file: invalid_use_of_internal_member

import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';

part 'graph_node.dart';

part 'graph_painter.dart';

const _viewerPadding = EdgeInsets.only(
  top: 160,
  left: 100,
  right: 100,
  bottom: 100,
);

class RefenaGraphPage extends StatefulWidget {
  final bool showWidgets;

  const RefenaGraphPage({
    this.showWidgets = false,
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
  late double _scale;

  @override
  void initState() {
    super.initState();

    ensureRef((ref) {
      _buildGraph();
      setState(() => _initialized = true);
    });
  }

  void _buildGraph() {
    ref.container.cleanupListeners();
    final notifiers = ref.container.getActiveNotifiers();

    final inputNodes = <_Node>[];
    final nodeMap = <BaseNotifier, _Node>{};
    final widgetMap = <ElementRebuildable, _Node>{};
    for (final notifier in notifiers) {
      final node = _Node(
        key: notifier,
        label: switch (notifier) {
          ViewProviderNotifier() => 'V | ${notifier.debugLabel}',
          ReduxNotifier() => 'R | ${notifier.debugLabel}',
          ImmutableNotifier() => 'P | ${notifier.debugLabel}',
          FutureProviderNotifier() ||
          FutureFamilyProviderNotifier() =>
            'F | ${notifier.debugLabel}',
          _ => 'N | ${notifier.debugLabel}',
        },
        parents: {},
        children: {},
      );
      nodeMap[notifier] = node;
      inputNodes.add(node);

      // add widget nodes
      if (_showWidgets) {
        for (final listener in notifier.getListeners()) {
          if (listener is! ElementRebuildable ||
              widgetMap.containsKey(listener)) {
            continue;
          }
          final widget = _Node(
            key: listener,
            label: 'W | ${listener.debugLabel}',
            parents: {},
            children: {},
          );
          widgetMap[listener] = widget;
          inputNodes.add(widget);
        }
      }
    }

    // add edges
    for (final notifier in notifiers) {
      final node = nodeMap[notifier]!;
      for (final parent in notifier.dependencies) {
        final parentNode = nodeMap[parent]!;
        node.parents.add(parentNode);
      }

      for (final child in notifier.dependents) {
        final childNode = nodeMap[child]!;
        node.children.add(childNode);
      }

      // add widget edges
      if (_showWidgets) {
        for (final listener in notifier.getListeners()) {
          if (listener is! ElementRebuildable) {
            continue;
          }
          final dependentNode = widgetMap[listener]!;
          dependentNode.parents.add(node);
          node.children.add(dependentNode);
        }
      }
    }

    _graph = _buildGraphFromNodes(inputNodes);

    // Widget constraints
    final parentSize = MediaQuery.sizeOf(context);

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
        title: const Text('Refena Graph'),
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
                  setState(() {
                    _showWidgets = !_showWidgets;
                    _initialized = false;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _buildGraph();
                    setState(() => _initialized = true);
                  });
                  break;
              }
            },
            child: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: !_initialized
          ? Container()
          : Builder(
              builder: (context) {
                final screenSize = MediaQuery.sizeOf(context);
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
