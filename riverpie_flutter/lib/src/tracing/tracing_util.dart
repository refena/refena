part of 'tracing_page.dart';

final Map<_EventType, Color> _baseColors = {
  _EventType.change: Colors.orange,
  _EventType.rebuild: Colors.purple,
  _EventType.action: Colors.blue,
  _EventType.providerInit: Colors.green,
  _EventType.providerDispose: Colors.grey,
  _EventType.message: Colors.yellow,
  _EventType.listenerAdded: Colors.cyan,
  _EventType.listenerRemoved: Colors.cyan,
};

final Map<_EventType, Color> _headerColor = _baseColors.map((key, value) {
  return MapEntry(key, value.withOpacity(0.3));
});

final Map<_EventType, Color> _backgroundColor = _baseColors.map((key, value) {
  return MapEntry(key, value.withOpacity(0.1));
});

String _formatTimestamp(DateTime timestamp) {
  return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
}

extension on int {
  String formatMicros() {
    final int milliseconds = this ~/ 1000;
    final int tenths = (this % 1000) ~/ 100;
    return '$milliseconds.${tenths}ms';
  }
}
