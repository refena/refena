part of 'tracing_page.dart';

Color _getColor(_EventType type) {
  return switch (type) {
    _EventType.change => Colors.orange,
    _EventType.rebuild => Colors.purple,
    _EventType.action => Colors.blue,
    _EventType.providerInit => Colors.green,
    _EventType.listenerAdded => Colors.grey,
    _EventType.listenerRemoved => Colors.grey,
  };
}

String _formatTimestamp(DateTime timestamp) {
  return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}
