part of 'tracing_page.dart';

class _TracingEventDetailsPage extends StatelessWidget {
  final Map<String, String> attributes;
  final _ErrorEntry? error;

  const _TracingEventDetailsPage({
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
          ...attributes.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key}:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(e.value),
                  ],
                ),
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
