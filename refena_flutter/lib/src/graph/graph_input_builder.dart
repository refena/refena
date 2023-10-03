part of 'graph_page.dart';

// ignore_for_file: invalid_use_of_internal_member

/// Builds the input graph from the state of the app.
List<InputNode> _buildInputGraphFromState(Ref ref, void Function() refresher) {
  ref.container.cleanupListeners();
  final notifiers = ref.container.getActiveNotifiers();

  final inputNodes = <InputNode>[];
  final nodeMap = <BaseNotifier, InputNode>{};
  final widgetMap = <ElementRebuildable, InputNode>{};
  for (final notifier in notifiers) {
    final node = InputNode(
      type: switch (notifier) {
        ViewProviderNotifier() => InputNodeType.view,
        ReduxNotifier() => InputNodeType.redux,
        ImmutableNotifier() => InputNodeType.immutable,
        FutureProviderNotifier() => InputNodeType.future,
        FutureFamilyProviderNotifier() => InputNodeType.future,
        _ => InputNodeType.notifier,
      },
      debugLabel: notifier.debugLabel,
    );
    nodeMap[notifier] = node;
    inputNodes.add(node);

    // add widget nodes
    for (final listener in notifier.getListeners()) {
      if (listener is! ElementRebuildable || widgetMap.containsKey(listener)) {
        continue;
      }
      final widget = InputNode(
        type: InputNodeType.widget,
        debugLabel: listener.debugLabel,
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
