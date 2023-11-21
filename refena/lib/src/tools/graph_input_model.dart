import 'package:meta/meta.dart';
import 'package:refena/src/provider/base_provider.dart';
import 'package:refena/src/provider/types/future_family_provider.dart';
import 'package:refena/src/provider/types/future_provider.dart';
import 'package:refena/src/provider/types/provider.dart';
import 'package:refena/src/provider/types/redux_provider.dart';
import 'package:refena/src/provider/types/view_family_provider.dart';
import 'package:refena/src/provider/types/view_provider.dart';

@internal
enum InputNodeType {
  view,
  redux,
  immutable,
  future,
  widget,
  notifier,
}

/// A node used as input to the graph builder.
/// This is an intermediate node instance.
@internal
class InputNode {
  final InputNodeType type;
  final String label;
  final Set<InputNode> parents = {}; // set later
  final Set<InputNode> children = {}; // set later

  /// A temporary flag to mark nodes as visited.
  bool visited = false;

  InputNode({
    required this.type,
    required this.label,
  });

  @override
  String toString() =>
      '$label(parents: ${parents.length}, children: ${children.length})';
}

@internal
extension BaseProviderExt on BaseProvider {
  InputNodeType toInputNodeType() {
    return switch (this) {
      ViewProvider() => InputNodeType.view,
      ViewFamilyProvider() => InputNodeType.view,
      ReduxProvider() => InputNodeType.redux,
      Provider() => InputNodeType.immutable,
      FutureProvider() => InputNodeType.future,
      FutureFamilyProvider() => InputNodeType.future,
      _ => InputNodeType.notifier,
    };
  }
}
