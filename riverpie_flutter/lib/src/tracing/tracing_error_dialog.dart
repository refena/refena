part of 'tracing_page.dart';

class _TracingErrorDialog extends StatelessWidget {
  final ActionErrorEvent error;
  final ErrorParser? errorParser;
  final Map<String, dynamic>? parsed;

  _TracingErrorDialog({
    required this.error,
    required this.errorParser,
  }) : parsed = _parseError(error.error, errorParser);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Error in ${error.action.debugLabel}.${error.lifecycle.name}',
      ),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _QuoteContainer(
            error.error.toString(),
          ),
          if (parsed != null) ...[
            const SizedBox(height: 10),
            Text('Info:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            _QuoteContainer(
              JsonEncoder.withIndent('  ').convert(parsed),
            ),
          ],
          const SizedBox(height: 10),
          Text('Stacktrace:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _QuoteContainer(error.stackTrace.toString()),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            final text =
                'Error in ${error.action.debugLabel}.${error.lifecycle.name}:\n${error.error}\n\n${JsonEncoder.withIndent('  ').convert(parsed)}\n\n${error.stackTrace}';
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
    );
  }
}

/// Container with left border and padding
class _QuoteContainer extends StatelessWidget {
  final String text;

  const _QuoteContainer(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.orange,
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.only(left: 5),
      child: SelectableText(text),
    );
  }
}
