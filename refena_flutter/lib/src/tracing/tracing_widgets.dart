// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

class _EntryTile extends StatefulWidget {
  static const timeColumnWidth = 85.0;
  static const noTimeWidth = 20.0;

  final int slowExecutionThreshold;
  final ErrorParser? errorParser;
  final _TracingEntry entry;
  final int depth;
  final bool showTime;

  const _EntryTile({
    required this.slowExecutionThreshold,
    required this.errorParser,
    required this.entry,
    required this.depth,
    required this.showTime,
  });

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry.event;
    final error = widget.entry.error;
    return Column(
      children: [
        Column(
          children: [
            Row(
              children: [
                if (widget.showTime)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: _EntryTile.timeColumnWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Text(
                        _formatTimestamp(widget.entry.timestamp),
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: _EntryTile.noTimeWidth),
                if (widget.depth != 0)
                  Padding(
                    padding: EdgeInsets.only(left: (widget.depth - 1) * 40),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 40,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.subdirectory_arrow_right,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                GestureDetector(
                  onTap: () {
                    setState(() => _expanded = !_expanded);
                  },
                  child: _EntryCharacterBox(e.type.internalType),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _expanded = !_expanded);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: _backgroundColor[e.type.internalType],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              switch (e.type) {
                                InputEventType.change =>
                                  e.notifierLabel ?? e.stateType!,
                                InputEventType.rebuild => widget.entry.isWidget
                                    ? e.rebuildableLabel!
                                    : e.stateType!,
                                InputEventType.actionDispatched =>
                                  e.actionLabel!,
                                InputEventType.actionFinished => '',
                                InputEventType.actionError => '',
                                InputEventType.init => e.providerLabel!,
                                InputEventType.dispose => e.providerLabel!,
                                InputEventType.message => e.message!,
                              },
                              style: TextStyle(
                                color: switch (error?.actionLifecycle) {
                                  null => null,
                                  ActionLifecycle.before => Colors.red,
                                  ActionLifecycle.reduce => Colors.red,
                                  ActionLifecycle.after => Colors.orange,
                                },
                                decoration: widget.entry.superseded
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (error?.actionLifecycle != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: switch (error!.actionLifecycle) {
                                ActionLifecycle.before => Icon(
                                    Icons.error,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ActionLifecycle.reduce => Icon(
                                    Icons.error,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                ActionLifecycle.after => Icon(
                                    Icons.warning,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                              },
                            ),
                          ...switch (e.type) {
                            InputEventType.actionDispatched => [
                                if (widget.depth == 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _EntryBadge(
                                      label: 'from: ${e.debugOrigin}',
                                      color: _headerColor[e.type.internalType]!,
                                    ),
                                  ),
                                if (widget.entry.result != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: _EntryBadge(
                                      label: '✓ Result',
                                      color: _headerColor[e.type.internalType]!,
                                    ),
                                  ),
                                if (widget.entry.millis != null &&
                                    widget.entry.millis! >=
                                        widget.slowExecutionThreshold)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      widget.entry.millis!.formatMillis(),
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            InputEventType.message when widget.depth == 0 => [
                                const SizedBox(width: 8),
                                _EntryBadge(
                                  label:
                                      'from: ${widget.entry.event.debugOrigin}',
                                  color: _headerColor[
                                      widget.entry.event.type.internalType]!,
                                ),
                              ],
                            _ => [],
                          },
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutExpo,
              switchOutCurve: Curves.easeInExpo,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: child,
                ),
              ),
              child: !_expanded
                  ? null
                  : Row(
                      children: [
                        SizedBox(
                          width: widget.showTime
                              ? _EntryTile.timeColumnWidth
                              : _EntryTile.noTimeWidth,
                        ),
                        SizedBox(width: (widget.depth + 1) * 40),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _backgroundColor[e.type.internalType],
                            ),
                            child: _EntryDetail(
                              errorParser: widget.errorParser,
                              isWidget: widget.entry.isWidget,
                              superseded: widget.entry.superseded,
                              error: widget.entry.error,
                              attributes: switch (e.type) {
                                InputEventType.change => {
                                    'Notifier': e.notifierLabel!,
                                    if (e.actionId != null)
                                      'Triggered by': e.actionLabel!,
                                    'Prev': e.prevState.toString(),
                                    'Next': e.nextState.toString(),
                                    'Rebuild': e.rebuildWidgets == null ||
                                            e.rebuildWidgets!.isEmpty
                                        ? '<none>'
                                        : e.rebuildWidgets!.join(', '),
                                  },
                                InputEventType.rebuild => widget.entry.isWidget
                                    ? {}
                                    : {
                                        'Notifier': e.rebuildableLabel!,
                                        'Triggered by':
                                            e.rebuildCausesLabels!.join(', '),
                                        'Prev': e.prevState.toString(),
                                        'Next': e.nextState.toString(),
                                        'Rebuild': e.rebuildWidgets!.isEmpty
                                            ? '<none>'
                                            : e.rebuildWidgets!.join(', '),
                                      },
                                InputEventType.actionDispatched => {
                                    'Origin': e.debugOrigin!,
                                    'Action Group': e.notifierLabel!,
                                    'Action': e.actionLabel!,
                                    if (widget.entry.millis != null)
                                      'Duration':
                                          '${widget.entry.millis?.formatMillis()}',
                                    if (widget.entry.result != null)
                                      'Result':
                                          _formatResult(widget.entry.result!),
                                  },
                                InputEventType.actionFinished => {},
                                InputEventType.actionError => {},
                                InputEventType.init => {
                                    'Provider': e.providerLabel!,
                                    'Initial': e.value.toString(),
                                    'Reason':
                                        e.providerInitCause!.name.toUpperCase(),
                                  },
                                InputEventType.dispose => {
                                    'Provider': e.providerLabel!,
                                  },
                                InputEventType.message => {
                                    'Origin': e.debugOrigin!,
                                    'Message': e.message!,
                                  },
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        ...widget.entry.children.map((e) => _EntryTile(
              slowExecutionThreshold: widget.slowExecutionThreshold,
              errorParser: widget.errorParser,
              entry: e,
              depth: widget.depth + 1,
              showTime: widget.showTime,
            )),
      ],
    );
  }
}

class _EntryCharacterBox extends StatelessWidget {
  final _EventType type;

  const _EntryCharacterBox(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _headerColor[type],
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 40,
      ),
      child: Text(
        switch (type) {
          _EventType.change => 'S',
          _EventType.rebuild => 'R',
          _EventType.action => 'A',
          _EventType.providerInit => 'I',
          _EventType.providerDispose => 'D',
          _EventType.message => 'M',
        },
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EntryBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _EntryBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _EntryDetail extends StatelessWidget {
  final ErrorParser? errorParser;
  final bool isWidget;
  final bool superseded;
  final _ErrorEntry? error;
  final Map<String, String> attributes;

  const _EntryDetail({
    required this.errorParser,
    required this.isWidget,
    required this.superseded,
    required this.error,
    required this.attributes,
  });

  @override
  Widget build(BuildContext context) {
    if (isWidget) {
      return Text(
        'This is a widget.\nFlutter will rebuild this\nas soon as possible.',
        style: TextStyle(
          color: Colors.orange,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (superseded)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(
              'Superseded by another event in the same frame.',
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          ),
        ...attributes.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${e.key} : ', style: TextStyle(color: Colors.grey)),
                  Expanded(
                    child: Text(e.value.split('\n').take(30).join('\n')),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 5),
        if (error?.actionLifecycle == ActionLifecycle.after)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'This is a warning because the error happened\nin the after method of the action.',
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          ),
        Row(
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _TracingEventDetailsPage(
                      attributes: attributes,
                      error: error,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open'),
            ),
            const SizedBox(width: 10),
            _CopyEventButton(attributes),
            const SizedBox(width: 10),
            if (error != null) _ErrorButton(error!),
          ],
        ),
      ],
    );
  }
}

class _CopyEventButton extends StatelessWidget {
  final Map<String, String> attributes;

  const _CopyEventButton(this.attributes);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey,
      ),
      onPressed: () {
        final text =
            attributes.entries.map((e) => '${e.key} : ${e.value}').join('\n');
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Copied to clipboard'),
          ),
        );
      },
      icon: const Icon(Icons.copy, size: 16),
      label: const Text('Copy'),
    );
  }
}

class _ErrorButton extends StatelessWidget {
  final _ErrorEntry error;

  const _ErrorButton(this.error);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: error.actionLifecycle == ActionLifecycle.after
            ? Colors.orange
            : Colors.red,
      ),
      onPressed: () {
        if (MediaQuery.sizeOf(context).width <= 800) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _TracingErrorPage(error),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (_) => _TracingErrorDialog(error),
          );
        }
      },
      icon: Icon(
        error.actionLifecycle == ActionLifecycle.after
            ? Icons.warning
            : Icons.error,
        size: 16,
      ),
      label: Text(
          error.actionLifecycle == ActionLifecycle.after ? 'Warning' : 'Error'),
    );
  }
}
