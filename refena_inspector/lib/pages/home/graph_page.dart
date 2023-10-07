// ignore_for_file: invalid_use_of_internal_member

import 'dart:async';

import 'package:flutter/material.dart';
// ignore: implementation_imports
import 'package:refena/src/tools/graph_input_model.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/service/graph_service.dart';

class GraphPage extends StatelessWidget {
  const GraphPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefenaGraphPage(
      title: 'Dependency Graph',
      showWidgets: true,
      inputGraphBuilder: _StateGraphInputBuilder(context.ref),
      padding: const EdgeInsets.only(
        top: 110,
        left: 50,
        right: 50,
        bottom: 50,
      ),
    );
  }
}

class _StateGraphInputBuilder extends GraphInputBuilder {
  final Stream _stream;
  final Ref _ref;

  _StateGraphInputBuilder(this._ref) : _stream = _ref.stream(graphProvider);

  @override
  Stream? get refreshStream => _stream;

  @override
  List<InputNode> build(Ref ref) {
    return _ref.read(graphProvider).nodes;
  }
}
