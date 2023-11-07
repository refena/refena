import 'package:meta/meta.dart';
import 'package:refena/refena.dart';

// ignore: implementation_imports
import 'package:refena/src/notifier/base_notifier.dart';
// ignore: implementation_imports
import 'package:refena/src/tools/graph_input_model.dart';
// ignore: implementation_imports
import 'package:refena/src/util/id_provider.dart';
import 'package:refena_inspector_client/src/protocol.dart';

// ignore_for_file: invalid_use_of_internal_member

final _idProvider = IdProvider();

@internal
class GraphBuilder {
  /// Builds the graph from the state of the app in DTO format.
  static List<GraphNodeDto> buildDto(Ref ref) {
    ref.container.cleanupListeners();
    final notifiers = ref.container.getActiveNotifiers();

    // To ensure deterministic results
    _idProvider.reset();

    final inputNodes = <GraphNodeDto>[];
    final nodeMap = <BaseNotifier, GraphNodeDto>{};
    final widgetMap = <Rebuildable, GraphNodeDto>{};
    for (final notifier in notifiers) {
      final node = GraphNodeDto(
        id: _idProvider.getNextId(),
        type: switch (notifier) {
          ViewProviderNotifier() => InputNodeType.view,
          ViewFamilyProviderNotifier() => InputNodeType.view,
          ReduxNotifier() => InputNodeType.redux,
          ImmutableNotifier() => InputNodeType.immutable,
          FutureProviderNotifier() => InputNodeType.future,
          FutureFamilyProviderNotifier() => InputNodeType.future,
          _ => InputNodeType.notifier,
        },
        debugLabel: notifier.debugLabel,
        parents: [],
        children: [],
      );
      nodeMap[notifier] = node;
      inputNodes.add(node);

      // add widget nodes
      for (final listener in notifier.getListeners()) {
        if (!listener.isWidget || widgetMap.containsKey(listener)) {
          continue;
        }
        final widget = GraphNodeDto(
          id: _idProvider.getNextId(),
          type: InputNodeType.widget,
          debugLabel: listener.debugLabel,
          parents: [],
          children: [],
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
        node.parents.add(parentNode.id);
      }

      for (final child in notifier.dependents) {
        final childNode = nodeMap[child];
        if (childNode == null) {
          // might happen if built during initialization phase
          // of a provider
          continue;
        }
        node.children.add(childNode.id);
      }

      // add widget edges
      for (final listener in notifier.getListeners()) {
        if (!listener.isWidget) {
          continue;
        }
        final dependentNode = widgetMap[listener]!;
        dependentNode.parents.add(node.id);
        node.children.add(dependentNode.id);
      }
    }

    return inputNodes;
  }
}
