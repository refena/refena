import 'dart:async';

import 'package:flutter/material.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/service/graph_service.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> with Refena {
  late StreamSubscription<NotifierEvent<GraphState>> _subscription;
  void Function()? _refresher;

  @override
  void initState() {
    super.initState();

    ensureRef((ref) {
      _subscription = ref.stream(graphProvider).listen((_) {
        _refresher?.call();
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefenaGraphPage(
      title: 'Dependency Graph',
      showWidgets: true,
      inputGraphBuilder: (ref, refresher) {
        _refresher = refresher;
        return ref.read(graphProvider).nodes;
      },
    );
  }
}
