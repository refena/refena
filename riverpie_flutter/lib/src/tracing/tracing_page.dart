// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ignore: implementation_imports
import 'package:riverpie/src/notifier/base_notifier.dart';

// ignore: implementation_imports
import 'package:riverpie/src/notifier/rebuildable.dart';

// ignore: implementation_imports
import 'package:riverpie/src/observer/tracing_observer.dart';
import 'package:riverpie_flutter/riverpie_flutter.dart';
import 'package:riverpie_flutter/src/element_rebuildable.dart';

part 'tracing_model.dart';

part 'tracing_model_builder.dart';

part 'tracing_util.dart';

part 'tracing_widgets.dart';

class RiverpieTracingPage extends StatefulWidget {
  const RiverpieTracingPage({super.key});

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

      _entries = _buildEntries(ref.notifier(tracingProvider).events);
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
          Tooltip(
            message: 'Refresh',
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _show
                  ? () {
                      _load(loadDelay: const Duration(milliseconds: 100));
                    }
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Clear',
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _show
                  ? () {
                      ref.notifier(tracingProvider).clear();
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        _load(
                          loadDelay: Duration.zero,
                          showDelay: Duration.zero,
                        );
                      });
                    }
                  : null,
            ),
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
                      padding: const EdgeInsets.only(left: 85, bottom: 10),
                      child: Text(
                        'Start of history...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  if (index == _filteredEntries.length + 1) {
                    // legend
                    return Padding(
                      padding: const EdgeInsets.only(top: 20, left: 20),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: screenWidth - 40,
                          child: Wrap(
                            children: _EventType.values.map((e) {
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _EntryCharacterBox(e),
                                    const SizedBox(width: 5),
                                    Text(
                                      switch (e) {
                                        _EventType.change => 'State Change',
                                        _EventType.rebuild => 'Rebuild',
                                        _EventType.action => 'Action Dispatch',
                                        _EventType.providerInit =>
                                          'Provider Initialization',
                                        _EventType.listenerAdded =>
                                          'Listener Added',
                                        _EventType.listenerRemoved =>
                                          'Listener Removed',
                                      },
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  }

                  final entry = _filteredEntries[index - 1];

                  return _EntryTile(
                    entry: entry,
                    depth: 0,
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
