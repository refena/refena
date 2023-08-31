// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

class _EntryTile extends StatefulWidget {
  final _TracingEntry entry;
  final int depth;

  const _EntryTile({
    required this.entry,
    required this.depth,
  });

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: [
            Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 85,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      _formatTimestamp(widget.entry.event.timestamp),
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
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
                  child:
                      _EntryCharacterBox(widget.entry.event.event.internalType),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _expanded = !_expanded);
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: _backgroundColor[
                            widget.entry.event.event.internalType],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              switch (widget.entry.event.event) {
                                ChangeEvent event => event.stateType.toString(),
                                RebuildEvent event => widget.entry.isWidget
                                    ? event.rebuildable.debugLabel
                                    : event.stateType.toString(),
                                ActionDispatchedEvent event =>
                                  event.action.debugLabel,
                                ActionErrorEvent _ => '',
                                ProviderInitEvent event =>
                                  event.provider.toString(),
                                ProviderDisposeEvent event =>
                                  event.provider.toString(),
                                MessageEvent event => event.message,
                                ListenerAddedEvent event =>
                                  '${event.rebuildable.debugLabel} on ${event.notifier.debugLabel}',
                                ListenerRemovedEvent event =>
                                  '${event.rebuildable.debugLabel} on ${event.notifier.debugLabel}',
                              },
                              style: TextStyle(
                                color: switch (widget.entry.error?.lifecycle) {
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
                          if (widget.entry.error != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: switch (widget.entry.error!.lifecycle) {
                                ActionLifecycle.before => Icon(Icons.error,
                                    size: 16, color: Colors.red),
                                ActionLifecycle.reduce => Icon(Icons.error,
                                    size: 16, color: Colors.red),
                                ActionLifecycle.after => Icon(Icons.warning,
                                    size: 16, color: Colors.orange),
                              },
                            ),
                          ...switch (widget.entry.event.event) {
                            ActionDispatchedEvent e
                                when e.debugOriginRef is Rebuildable =>
                              [
                                const SizedBox(width: 8),
                                _EntryBadge(
                                  label: 'from: ${e.debugOrigin}',
                                  color: _headerColor[e.internalType]!,
                                ),
                              ],
                            MessageEvent e when e.origin is Rebuildable => [
                                const SizedBox(width: 8),
                                _EntryBadge(
                                  label: 'from: ${e.origin.debugLabel}',
                                  color: _headerColor[e.internalType]!,
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
            AnimatedCrossFade(
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
              firstChild: const SizedBox(),
              secondChild: Row(
                children: [
                  const SizedBox(width: 85),
                  SizedBox(width: (widget.depth + 1) * 40),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _backgroundColor[
                            widget.entry.event.event.internalType],
                      ),
                      child: _EntryDetail(
                        isWidget: widget.entry.isWidget,
                        superseded: widget.entry.superseded,
                        error: widget.entry.error,
                        attributes: switch (widget.entry.event.event) {
                          ChangeEvent event => {
                              'Notifier': event.notifier.debugLabel,
                              if (event.action != null)
                                'Triggered by': event.action!.debugLabel,
                              'Prev': event.prev.toString(),
                              'Next': event.next.toString(),
                              'Rebuild': event.rebuild.isEmpty
                                  ? '<none>'
                                  : event.rebuild
                                      .map((r) => r.debugLabel)
                                      .join(', '),
                            },
                          RebuildEvent event => widget.entry.isWidget
                              ? {}
                              : {
                                  'Notifier': event.rebuildable is BaseNotifier
                                      ? (event.rebuildable as BaseNotifier)
                                          .debugLabel
                                      : '',
                                  'Triggered by': event.causes
                                      .map((e) => e.stateType.toString())
                                      .join(', '),
                                  'Prev': event.prev.toString(),
                                  'Next': event.next.toString(),
                                  'Rebuild': event.rebuild.isEmpty
                                      ? '<none>'
                                      : event.rebuild
                                          .map((r) => r.debugLabel)
                                          .join(', '),
                                },
                          ActionDispatchedEvent event => {
                              'Origin': event.debugOrigin,
                              'Action Group': event.notifier.debugLabel,
                              'Action': event.action.toString(),
                            },
                          ActionErrorEvent _ => {},
                          ProviderInitEvent event => {
                              'Provider': event.provider.toString(),
                              'Initial': event.value.toString(),
                              'Reason': event.cause.name.toUpperCase(),
                            },
                          ProviderDisposeEvent event => {
                              'Provider': event.provider.toString(),
                            },
                          MessageEvent event => {
                              'Message': event.message,
                            },
                          ListenerAddedEvent event => {
                              'Rebuildable': event.rebuildable.debugLabel,
                              'Notifier': event.notifier.debugLabel,
                            },
                          ListenerRemovedEvent event => {
                              'Rebuildable': event.rebuildable.debugLabel,
                              'Notifier': event.notifier.debugLabel,
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
              entry: e,
              depth: widget.depth + 1,
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
          _EventType.listenerAdded => 'LA',
          _EventType.listenerRemoved => 'LR',
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
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _EntryDetail extends StatelessWidget {
  final bool isWidget;
  final bool superseded;
  final ActionErrorEvent? error;
  final Map<String, String> attributes;

  const _EntryDetail({
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
                    child: Text(e.value),
                  ),
                ],
              ),
            )),
        const SizedBox(height: 5),
        if (error?.lifecycle == ActionLifecycle.after)
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
                final text = attributes.entries
                    .map((e) => '${e.key} : ${e.value}')
                    .join('\n');
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                  ),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy'),
            ),
            const SizedBox(width: 10),
            if (error != null)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: error!.lifecycle == ActionLifecycle.after
                      ? Colors.orange
                      : Colors.red,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(
                          'Error in ${error!.action.debugLabel}.${error!.lifecycle.name}'),
                      scrollable: true,
                      content: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              error!.error.toString(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(error!.stackTrace.toString()),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            final text =
                                'Error in ${error!.action.debugLabel}.${error!.lifecycle.name}:\n${error!.error}\n\n${error!.stackTrace}';
                            Clipboard.setData(ClipboardData(text: text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Copied to clipboard'),
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          child: Text('Copy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                icon: Icon(
                    error!.lifecycle == ActionLifecycle.after
                        ? Icons.warning
                        : Icons.error,
                    size: 16),
                label: Text(error!.lifecycle == ActionLifecycle.after
                    ? 'Warning'
                    : 'Error'),
              ),
          ],
        ),
      ],
    );
  }
}
