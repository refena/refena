import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:riverpie/riverpie.dart';

// ignore: implementation_imports
import 'package:riverpie/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:riverpie/src/notifier/rebuildable.dart';

// ignore: implementation_imports
import 'package:riverpie_flutter/src/element_rebuildable.dart';
import 'package:riverpie_flutter/src/mixin.dart';

part 'tracing_error_dialog.dart';

part 'tracing_error_parser.dart';

part 'tracing_legend.dart';

part 'tracing_model.dart';

part 'tracing_model_builder.dart';

part 'tracing_util.dart';

part 'tracing_widgets.dart';

/// Parses an error to a map.
/// This data will be displayed in the error dialog.
/// Return null to fallback to the default error parser provided by Riverpie.
/// See [_parseErrorDefault] for the default error parser.
typedef ErrorParser = Map<String, dynamic>? Function(Object error);

class RiverpieTracingPage extends StatefulWidget {
  /// Time in milliseconds to consider an event as slow.
  /// The execution time will be highlighted in the UI.
  final int slowExecutionThreshold;

  /// A function to parse an error to a map.
  /// See [ErrorParser] for more details.
  final ErrorParser? errorParser;

  /// If the given function returns `true`, then the event
  /// won't be displayed.
  final bool Function(RiverpieEvent event)? exclude;

  /// If the given function returns `true`, then the event
  /// will be displayed.
  final bool Function(RiverpieEvent event)? include;

  /// Display a time column by default.
  /// This can still be toggled in the UI.
  final bool showTime;

  const RiverpieTracingPage({
    super.key,
    this.slowExecutionThreshold = 500,
    this.errorParser,
    this.exclude,
    this.include,
    this.showTime = false,
  })  : assert(slowExecutionThreshold > 0,
            'slowExecutionThreshold must be greater than 0'),
        assert(include == null || exclude == null,
            'include and exclude cannot be used at the same time');

  @override
  State<RiverpieTracingPage> createState() => _RiverpieTracingPageState();
}

class _RiverpieTracingPageState extends State<RiverpieTracingPage>
    with Riverpie {
  final _sampleWidgetKey = GlobalKey();
  final _scrollController = ScrollController();
  List<_TracingEntry> _entries = [];
  List<_TracingEntry> _filteredEntries = [];
  bool _show = false;
  bool _notInitializedError = false;
  Size _sampleWidgetSize = Size(40, 32);

  String _query = '';
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
      if (!ref.notifier(tracingProvider).initialized) {
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

      Iterable<RiverpieEvent> events = ref.notifier(tracingProvider).events;
      if (widget.exclude != null) {
        events = events.where((e) => !widget.exclude!(e));
      } else if (widget.include != null) {
        events = events.where((e) => widget.include!(e));
      }
      _entries = _buildEntries(events);
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpie Tracing'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) {
              return [
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
      body: Stack(
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
                    return _TracingLegend();
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
                child: TextField(
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
                  'Tracing is not initialized. Make sure you have added the RiverpieTracingObserver to your RiverpieScope.',
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
      ),
    );
  }
}
