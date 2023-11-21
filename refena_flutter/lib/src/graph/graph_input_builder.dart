part of 'graph_page.dart';

// ignore_for_file: invalid_use_of_internal_member

/// A configuration for the graph page.
abstract class GraphInputBuilder {
  const GraphInputBuilder();

  /// If not null, then [build] will be called on every new stream event.
  Stream? get refreshStream;

  /// Builds the input graph either from the state of the app or
  /// from a state fetched from the client.
  List<InputNode> build(Ref ref);
}

/// Builds the graph from the state
class _StateGraphInputBuilder extends GraphInputBuilder {
  const _StateGraphInputBuilder();

  @override
  Stream? get refreshStream => null;

  @override
  List<InputNode> build(Ref ref) {
    ref.container.cleanupListeners();
    final notifiers = ref.container
        .getActiveNotifiers()
        .where((n) => n.provider!.debugVisibleInGraph)
        .toList();

    final inputNodes = <InputNode>[];
    final nodeMap = <BaseNotifier, InputNode>{};
    final widgetMap = <ElementRebuildable, InputNode>{};
    for (final notifier in notifiers) {
      final node = InputNode(
        type: notifier.provider!.toInputNodeType(),
        label: notifier.debugLabel,
      );
      nodeMap[notifier] = node;
      inputNodes.add(node);

      // add widget nodes
      for (final listener in notifier.getListeners()) {
        if (listener is! ElementRebuildable ||
            widgetMap.containsKey(listener)) {
          continue;
        }
        final widget = InputNode(
          type: InputNodeType.widget,
          label: listener.debugLabel,
        );
        widgetMap[listener] = widget;
        inputNodes.add(widget);
      }
    }

    // add edges
    for (final notifier in notifiers) {
      final node = nodeMap[notifier]!;
      for (final parent in notifier.dependencies) {
        final parentNode = nodeMap[parent];
        if (parentNode == null) {
          // might happen if built during initialization phase
          // of a provider
          continue;
        }
        node.parents.add(parentNode);
      }

      for (final child in notifier.dependents) {
        final childNode = nodeMap[child]!;
        node.children.add(childNode);
      }

      // add widget edges
      for (final listener in notifier.getListeners()) {
        if (listener is! ElementRebuildable) {
          continue;
        }
        final dependentNode = widgetMap[listener];
        if (dependentNode == null) {
          // might happen if built during initialization phase
          // of a provider
          continue;
        }
        dependentNode.parents.add(node);
        node.children.add(dependentNode);
      }
    }

    return inputNodes;
  }
}
