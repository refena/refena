import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_inspector/service/tracing_service.dart';

enum _OrderBy {
  label,
  total,
  error,
  avgTime,
  latest,
}

class ReduxPage extends StatefulWidget {
  const ReduxPage({super.key});

  @override
  State<ReduxPage> createState() => _ReduxPageState();
}

class _ReduxPageState extends State<ReduxPage> with Refena {
  late Timer _timer;
  _OrderBy _orderBy = _OrderBy.latest;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (ref.read(eventTracingProvider).runningActions.isNotEmpty) {
        // update the timer next to the running actions
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _setOrderBy(_OrderBy orderBy) {
    setState(() {
      _orderBy = orderBy;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tracingState = context.watch(eventTracingProvider);
    final runningActionsCount = tracingState.runningActions.length;
    final currentMillis =
        DateTime.now().millisecondsSinceEpoch - tracingState.clientDelay;

    final entries = tracingState.historicalActions.entries.toList();
    entries.sort((a, b) {
      switch (_orderBy) {
        case _OrderBy.label:
          return a.key.compareTo(b.key);
        case _OrderBy.total:
          return (b.value.successCount + b.value.errorCount)
              .compareTo(a.value.successCount + a.value.errorCount);
        case _OrderBy.error:
          return b.value.errorCount.compareTo(a.value.errorCount);
        case _OrderBy.avgTime:
          return b.value.avgTime.compareTo(a.value.avgTime);
        case _OrderBy.latest:
          return b.value.latestTime.compareTo(a.value.latestTime);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft, // also force on macOS
          child: const Text('Redux'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Text(
              'Running${runningActionsCount != 0 ? ' ($runningActionsCount)' : ''}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          SizedBox(
            height: 100,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: ListView(
                  children: [
                    for (final entry in tracingState.runningActions.entries)
                      Text(
                          '${entry.value.data['Action Group']}.${entry.value.label} (${((currentMillis - entry.value.millisSinceEpoch) ~/ 1000).formatDuration()})'),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Visibility(
                visible: tracingState.historicalActions.isNotEmpty,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset Statistics'),
                        content: const Text(
                          'Are you sure you want to reset the statistics?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );

                    if (result == true) {
                      ref
                          .redux(eventTracingProvider)
                          .dispatch(ClearHistoricalActionsAction());
                    }
                  },
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(1),
              1: FixedColumnWidth(100),
              2: FixedColumnWidth(100),
              3: FixedColumnWidth(120),
              4: FixedColumnWidth(100),
            },
            children: [
              TableRow(
                children: [
                  _Header(
                    title: 'Action',
                    alignment: MainAxisAlignment.start,
                    orderBy: _orderBy == _OrderBy.label,
                    onTap: () => _setOrderBy(_OrderBy.label),
                  ),
                  _Header(
                    title: 'Total',
                    alignment: MainAxisAlignment.end,
                    orderBy: _orderBy == _OrderBy.total,
                    onTap: () => _setOrderBy(_OrderBy.total),
                  ),
                  _Header(
                    title: 'Error',
                    alignment: MainAxisAlignment.end,
                    orderBy: _orderBy == _OrderBy.error,
                    onTap: () => _setOrderBy(_OrderBy.error),
                  ),
                  _Header(
                    title: 'Avg Time',
                    alignment: MainAxisAlignment.end,
                    orderBy: _orderBy == _OrderBy.avgTime,
                    onTap: () => _setOrderBy(_OrderBy.avgTime),
                  ),
                  _Header(
                    title: 'Latest',
                    alignment: MainAxisAlignment.end,
                    orderBy: _orderBy == _OrderBy.latest,
                    onTap: () => _setOrderBy(_OrderBy.latest),
                  ),
                ],
              ),
              ...entries.map((entry) {
                final action = entry.key;
                final actionInfo = entry.value;
                return TableRow(
                  children: [
                    Text(action),
                    Text(
                      '${actionInfo.successCount + actionInfo.errorCount}',
                      textAlign: TextAlign.end,
                    ),
                    Text(
                      '${actionInfo.errorCount}',
                      style: TextStyle(
                        color: actionInfo.errorCount != 0 ? Colors.red : null,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    Text('${actionInfo.avgTime} ms', textAlign: TextAlign.end),
                    Text(
                      DateFormat.Hm().format(
                        DateTime.fromMillisecondsSinceEpoch(
                          actionInfo.latestTime,
                        ),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          if (tracingState.historicalActions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: const Center(
                child: Text('No actions have been dispatched yet.'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final MainAxisAlignment alignment;
  final bool orderBy;
  final void Function() onTap;

  const _Header({
    required this.title,
    required this.alignment,
    required this.orderBy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          if (orderBy)
            Icon(
              Icons.arrow_drop_down,
              size: 20,
            ),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

extension on int {
  String formatDuration() {
    final minutes = this ~/ 60;
    final seconds = this % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
