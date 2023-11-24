part of 'tracing_page.dart';

class _TracingEventDetailsPage extends StatelessWidget {
  final String title;
  final Map<String, String> attributes;
  final _ErrorEntry? error;

  const _TracingEventDetailsPage({
    required this.title,
    required this.attributes,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Event',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
          top: 15,
          bottom: 50,
        ),
        children: [
          _EventDetailsEntry(
            label: 'Event',
            value: title,
          ),
          ...attributes.entries.map((e) => _EventDetailsEntry(
                label: e.key,
                value: e.value,
              )),
          const SizedBox(height: 20),
          Row(
            children: [
              _CopyEventButton(attributes),
              if (error != null) _ErrorButton(error!),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventDetailsEntry extends StatelessWidget {
  final String label;
  final String value;

  const _EventDetailsEntry({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SelectableText(value),
        ],
      ),
    );
  }
}
