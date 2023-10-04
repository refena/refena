// ignore_for_file: invalid_use_of_internal_member

// ignore: implementation_imports, depend_on_referenced_packages
import 'package:refena/src/tools/graph_input_model.dart';
import 'package:refena_flutter/refena_flutter.dart';
// ignore: implementation_imports
import 'package:refena_inspector_client/src/protocol.dart';

class GraphState {
  final List<InputNode> nodes;

  GraphState({
    required this.nodes,
  });

  GraphState copyWith({
    List<InputNode>? nodes,
  }) {
    return GraphState(
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  String toString() {
    return 'GraphState(nodes: $nodes)';
  }
}

final graphProvider = ReduxProvider<GraphService, GraphState>((ref) {
  return GraphService();
});

class GraphService extends ReduxNotifier<GraphState> {
  @override
  GraphState init() => GraphState(nodes: []);
}

class SetGraphAction extends ReduxAction<GraphService, GraphState> {
  final List<dynamic> nodes;

  SetGraphAction({
    required this.nodes,
  });

  @override
  GraphState reduce() {
    final nodesDto = nodes.map((e) => GraphNodeDto.fromJson(e)).toList();
    final result = <int, InputNode>{}; // id -> node
    for (final dto in nodesDto) {
      result[dto.id] = InputNode(
        type: dto.type,
        label: dto.debugLabel,
      );
    }

    // Assign edges
    for (final dto in nodesDto) {
      final inputNode = result[dto.id]!;
      for (final parentId in dto.parents) {
        final parentNode = result[parentId]!;
        inputNode.parents.add(parentNode);
      }
      for (final childId in dto.children) {
        final childNode = result[childId]!;
        inputNode.children.add(childNode);
      }
    }

    return state.copyWith(nodes: result.values.toList());
  }
}
