import 'package:refena/refena.dart';
import 'package:refena_flutter/src/graph/graph_node.dart';

class GraphPageState {
  /// The node that has been selected.
  /// This node can be dragged around.
  final PositionedNode? selectedNode;

  const GraphPageState({
    required this.selectedNode,
  });

  GraphPageState copyWith({
    PositionedNode? selectedNode,
  }) {
    return GraphPageState(
      selectedNode: selectedNode ?? this.selectedNode,
    );
  }
}

final graphPageProvider =
    NotifierProvider<GraphPageController, GraphPageState>((ref) {
  return GraphPageController();
});

class GraphPageController extends PureNotifier<GraphPageState> {
  @override
  GraphPageState init() => const GraphPageState(
        selectedNode: null,
      );

  void selectNode(PositionedNode? node) {
    state = state.copyWith(
      selectedNode: node,
    );
  }
}
