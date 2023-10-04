// ignore_for_file: invalid_use_of_internal_member

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refena/refena.dart';

// ignore: implementation_imports
import 'package:refena/src/observer/error_parser.dart';

// ignore: implementation_imports
import 'package:refena/src/tools/tracing_input_model.dart';

import 'package:refena_flutter/src/graph/graph_page.dart';
import 'package:refena_flutter/src/mixin.dart';

part 'tracing_error_dialog.dart';

part 'tracing_event_details_page.dart';

part 'tracing_input_builder.dart';

part 'tracing_legend.dart';

part 'tracing_model.dart';

part 'tracing_model_builder.dart';

part 'tracing_util.dart';

part 'tracing_widgets.dart';

class RefenaTracingPage extends StatefulWidget {
  /// Time in milliseconds to consider an event as slow.
  /// The execution time will be highlighted in the UI.
  final int slowExecutionThreshold;

  /// A function to parse an error to a map.
  /// See [ErrorParser] for more details.
  final ErrorParser? errorParser;

  /// If the given function returns `true`, then the event
  /// won't be displayed.
  final bool Function(RefenaEvent event)? exclude;

  /// If the given function returns `true`, then the event
  /// will be displayed.
  final bool Function(RefenaEvent event)? include;

  /// Display a time column by default.
  /// This can still be toggled in the UI.
  final bool showTime;

  /// Initial filter query.
  final String? query;

  /// The title of the page.
  final String title;

  /// The builder to build the input model.
  final TracingInputBuilder inputBuilder;

  const RefenaTracingPage({
    super.key,
    this.slowExecutionThreshold = 500,
    this.errorParser,
    this.exclude,
    this.include,
    this.showTime = false,
    this.query,
    this.title = 'Refena Tracing',
    this.inputBuilder = const _StateTracingInputBuilder(),
  })  : assert(slowExecutionThreshold > 0,
            'slowExecutionThreshold must be greater than 0'),
        assert(include == null || exclude == null,
            'include and exclude cannot be used at the same time');

  @override
  State<RefenaTracingPage> createState() => _RefenaTracingPageState();
}

class _RefenaTracingPageState extends State<RefenaTracingPage> with Refena {
  final _sampleWidgetKey = GlobalKey();
  final _scrollController = ScrollController();
  List<_TracingEntry> _entries = [];
  List<_TracingEntry> _filteredEntries = [];
  bool _show = false;
  bool _notInitializedError = false;
  Size _sampleWidgetSize = Size(40, 32);

  late String _query = widget.query ?? '';
  late bool _showTime = widget.showTime;

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _load({
    Duration loadDelay = const Duration(milliseconds: 300),
    Duration showDelay = const Duration(milliseconds: 500),
  }) async {
    ensureRef((ref) async {
      setState(() {
        _show = false;
      });
      await Future.delayed(loadDelay);
      if (widget.inputBuilder.requireTracingProvider &&
          !ref.notifier(tracingProvider).initialized) {
        setState(() {
          _notInitializedError = true;
        });
        return;
      }

      final renderObject = _sampleWidgetKey.currentContext?.findRenderObject();
      if (renderObject != null) {
        // Get the size of one item for reference
        _sampleWidgetSize = renderObject.paintBounds.size;
      }

      Iterable<InputEvent> events = widget.inputBuilder.build(ref);

      if (widget.exclude != null) {
        events = events.where((e) => !widget.exclude!(e.event!));
      } else if (widget.include != null) {
        events = events.where((e) => widget.include!(e.event!));
      }
      _entries = _buildEntries(events, widget.errorParser);
      _filter();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final entriesCount = _countItems(_entries);
        final destination = max(
                0,
                330 +
                    (entriesCount * _sampleWidgetSize.height) -
                    MediaQuery.sizeOf(context).height)
            .toDouble();

        _scrollController.jumpTo(destination);

        await Future.delayed(showDelay);

        setState(() {
          _show = true;
        });
      });
    });
  }

  void _filter() {
    final queryLower = _query.toLowerCase();
    setState(() {
      _filteredEntries = _entries.where((e) {
        return _contains(e, queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.account_tree),
                    title: Text('Graph'),
                  ),
                  value: 'graph',
                ),
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.refresh),
                    title: Text('Refresh'),
                  ),
                  value: 'refresh',
                ),
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.access_time),
                    trailing: _showTime
                        ? const Icon(Icons.check)
                        : const SizedBox.shrink(),
                    title: Text('Time'),
                  ),
                  value: 'time',
                ),
                PopupMenuItem(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.delete),
                    title: Text('Clear'),
                  ),
                  value: 'clear',
                ),
              ];
            },
            enabled: _show,
            onSelected: (value) async {
              switch (value) {
                case 'graph':
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RefenaGraphPage(),
                    ),
                  );
                  break;
                case 'refresh':
                  _load(loadDelay: const Duration(milliseconds: 100));
                  break;
                case 'time':
                  setState(() {
                    _showTime = !_showTime;
                  });
                  break;
                case 'clear':
                  ref.notifier(tracingProvider).clear();
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    _load(
                      loadDelay: Duration.zero,
                      showDelay: Duration.zero,
                    );
                  });
                  break;
              }
            },
            child: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.biggest.width;
          return Stack(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: screenWidth * 3,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      bottom: 100 + MediaQuery.of(context).padding.bottom,
                      top: 20,
                    ),
                    itemCount: _filteredEntries.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: EdgeInsets.only(
                              left: _showTime
                                  ? _EntryTile.timeColumnWidth
                                  : _EntryTile.noTimeWidth,
                              bottom: 10),
                          child: Text(
                            'Start of history...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      if (index == _filteredEntries.length + 1) {
                        return _TracingLegend(screenWidth: screenWidth);
                      }

                      return _EntryTile(
                        slowExecutionThreshold: widget.slowExecutionThreshold,
                        errorParser: widget.errorParser,
                        entry: _filteredEntries[index - 1],
                        depth: 0,
                        showTime: _showTime,
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextFormField(
                      initialValue: _query,
                      style: TextStyle(color: Colors.grey.shade700),
                      decoration: InputDecoration(
                        hintText: 'Filter',
                        filled: true,
                        fillColor: Colors.white,
                        labelStyle: TextStyle(color: Colors.grey.shade700),
                        iconColor: Colors.grey.shade700,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        isDense: true,
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _query = value;
                          _filter();
                        });
                      },
                    ),
                  ),
                ),
              ),
              if (!_show)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (_notInitializedError)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Tracing is not initialized. Make sure you have added the RefenaTracingObserver to your RefenaScope.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Visibility(
                key: _sampleWidgetKey,
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _EntryCharacterBox(_EventType.action),
              ),
            ],
          );
        },
      ),
    );
  }
}
