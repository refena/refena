import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/pages/home/actions_page_vm.dart';
import 'package:refena_inspector/service/action_service.dart';
import 'package:refena_inspector_client/refena_inspector_client.dart';

const _depthPadding = 30.0;

class ActionsPage extends StatelessWidget {
  const ActionsPage({super.key});

  double _depthToPadding(int depth) => switch (depth) {
        0 => 0,
        1 => 0,
        _ => (depth - 1) * _depthPadding,
      };

  List<Widget> _buildActions(
    ActionsPageVm vm,
    BuildContext context,
    Map<String, dynamic> actions,
    int depth,
  ) {
    final widgets = <Widget>[];
    final paddingLeft = _depthToPadding(depth);

    for (final entry in actions.entries) {
      if (entry.value is ActionEntry) {
        final actionEntry = entry.value as ActionEntry;
        widgets.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: paddingLeft, bottom: 20),
              child: FilledButton(
                onPressed: () {
                  if (actionEntry.params.isEmpty) {
                    // send directly
                    vm.sendAction(actionEntry.actionId, {});
                  } else {
                    // open dialog for parameter input
                    showDialog(
                      context: context,
                      builder: (context) {
                        return _ActionDialog(
                          action: actionEntry,
                          onSend: (params) {
                            vm.sendAction(actionEntry.actionId, params);
                          },
                        );
                      },
                    );
                  }
                },
                child: Text(actionEntry.name),
              ),
            ),
          ),
        );
      } else if (entry.value is Map<String, dynamic>) {
        final actionMap = entry.value as Map<String, dynamic>;
        final nextDepth = depth + 1;
        final headerPaddingLeft = _depthToPadding(nextDepth);
        widgets.add(Padding(
          padding: EdgeInsets.only(left: headerPaddingLeft, bottom: 10),
          child: Text(
            entry.key,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ));
        widgets.addAll(_buildActions(vm, context, actionMap, nextDepth));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.ref.watch(actionsPageVmProvider);
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text('Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          ..._buildActions(vm, context, vm.actions, 0),
        ],
      ),
    );
  }
}

const _fieldRequired = 'This field is required';

/// A dialog that shows the parameters of an action and allows the user
/// to input them.
class _ActionDialog extends StatefulWidget {
  final ActionEntry action;
  final void Function(Map<String, dynamic> params) onSend;

  const _ActionDialog({
    required this.action,
    required this.onSend,
  });

  @override
  State<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<_ActionDialog> {
  final _formKey = GlobalKey<FormState>();
  final params = <String, dynamic>{};

  @override
  void initState() {
    super.initState();

    for (final paramEntry in widget.action.params.entries) {
      params[paramEntry.key] = paramEntry.value.defaultValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.action.name),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final paramEntry in widget.action.params.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: switch (paramEntry.value.type) {
                  ParamType.string => TextFormField(
                      initialValue: paramEntry.value.defaultValue?.toString(),
                      decoration: InputDecoration(
                        labelText: paramEntry.key,
                      ),
                      onChanged: (value) {
                        params[paramEntry.key] = value;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (paramEntry.value.required &&
                            (value == null || value.isEmpty)) {
                          return _fieldRequired;
                        }
                        return null;
                      },
                    ),
                  ParamType.int => TextFormField(
                      initialValue: paramEntry.value.defaultValue?.toString(),
                      decoration: InputDecoration(
                        labelText: paramEntry.key,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        params[paramEntry.key] = int.tryParse(value);
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          if (paramEntry.value.required) {
                            return _fieldRequired;
                          } else {
                            return null;
                          }
                        }
                        if (int.tryParse(value) == null) {
                          return 'Invalid integer';
                        }
                        return null;
                      },
                    ),
                  ParamType.double => TextFormField(
                      initialValue: paramEntry.value.defaultValue?.toString(),
                      decoration: InputDecoration(
                        labelText: paramEntry.key,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        params[paramEntry.key] = double.tryParse(value);
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          if (paramEntry.value.required) {
                            return _fieldRequired;
                          } else {
                            return null;
                          }
                        }
                        if (double.tryParse(value) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ParamType.bool => DropdownButtonFormField<bool?>(
                      value: paramEntry.value.defaultValue == null
                          ? null
                          : paramEntry.value.defaultValue == true,
                      decoration: InputDecoration(
                        labelText: paramEntry.key,
                      ),
                      onChanged: (value) {
                        params[paramEntry.key] = value;
                      },
                      items: const [
                        DropdownMenuItem(
                          value: null,
                          child: Text('null'),
                        ),
                        DropdownMenuItem(
                          value: true,
                          child: Text('true'),
                        ),
                        DropdownMenuItem(
                          value: false,
                          child: Text('false'),
                        ),
                      ],
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (paramEntry.value.required && value == null) {
                          return _fieldRequired;
                        }
                        return null;
                      },
                    ),
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop();
            widget.onSend(params);
          },
          icon: const Icon(Icons.bolt),
          label: const Text('Send'),
        ),
      ],
    );
  }
}
