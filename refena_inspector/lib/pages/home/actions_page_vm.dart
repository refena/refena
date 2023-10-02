import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/service/action_service.dart';
import 'package:refena_inspector/service/server_service.dart';

class ActionsPageVm {
  final Map<String, dynamic> actions;
  final void Function(String actionId, Map<String, dynamic> params) sendAction;

  const ActionsPageVm({
    required this.actions,
    required this.sendAction,
  });
}

final actionsPageVmProvider = ViewProvider((ref) {
  final serverState = ref.watch(actionProvider);
  return ActionsPageVm(
    actions: serverState.actions,
    sendAction: (actionId, params) => ref
        .redux(serverProvider)
        .dispatch(SendActionAction(actionId: actionId, params: params)),
  );
});
