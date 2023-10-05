// ignore: implementation_imports
import 'package:meta/meta.dart';
// ignore: implementation_imports
import 'package:refena/src/tools/graph_input_model.dart';

enum InspectorClientMessageType {
  /// The client sends to the server general metadata about the client
  /// like the map of actions.
  /// The server will use this information to build the inspector.
  hello,

  /// The client sends to the server new events.
  event,

  /// The client sends to the server an updated graph
  graph,
}

enum InspectorServerMessageType {
  /// The server sends to the client an action.
  /// The client will execute the action.
  action,
}

@internal
class GraphNodeDto {
  final int id;
  // ignore: invalid_use_of_internal_member
  final InputNodeType type;
  final String debugLabel;
  final List<int> parents;
  final List<int> children;

  GraphNodeDto({
    required this.id,
    required this.type,
    required this.debugLabel,
    required this.parents,
    required this.children,
  });

  factory GraphNodeDto.fromJson(Map<String, dynamic> json) {
    return GraphNodeDto(
      id: json['id'],
      // ignore: invalid_use_of_internal_member
      type: InputNodeType.values[json['type']],
      debugLabel: json['debugLabel'],
      parents: json['parents'].cast<int>(),
      children: json['children'].cast<int>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'debugLabel': debugLabel,
      'parents': parents,
      'children': children,
    };
  }
}
