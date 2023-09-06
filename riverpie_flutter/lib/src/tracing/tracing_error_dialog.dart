part of 'tracing_page.dart';

class _TracingErrorDialog extends StatelessWidget {
  final ActionErrorEvent error;
  final ErrorParser? errorParser;

  _TracingErrorDialog({
    required this.error,
    required this.errorParser,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Error in ${error.action.debugLabel}.${error.lifecycle.name}',
      ),
      scrollable: true,
      content: _TracingErrorContent(
        error: error,
        errorParser: errorParser,
      ),
      actions: [
        TextButton(
          onPressed: () => _copyErrorToClipboard(context, error, errorParser),
          child: Text('Copy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _TracingErrorPage extends StatelessWidget {
  final ActionErrorEvent error;
  final ErrorParser? errorParser;

  _TracingErrorPage({
    required this.error,
    required this.errorParser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Error in ${error.action.debugLabel}.${error.lifecycle.name}',
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
          _TracingErrorContent(
            error: error,
            errorParser: errorParser,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () =>
                  _copyErrorToClipboard(context, error, errorParser),
              child: Text('Copy'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TracingErrorContent extends StatelessWidget {
  final ActionErrorEvent error;
  final ErrorParser? errorParser;
  final Map<String, dynamic>? parsed;

  _TracingErrorContent({
    required this.error,
    required this.errorParser,
  }) : parsed = _parseError(error.error, errorParser);

  @override
  Widget build(BuildContext context) {
    return Column(
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

void _copyErrorToClipboard(
    BuildContext context, ActionErrorEvent error, ErrorParser? errorParser) {
  final parsed = _parseError(error.error, errorParser);
  final parsedJson = parsed != null
      ? '\n\n${JsonEncoder.withIndent('  ').convert(parsed)}'
      : '';
  final text =
      'Error in ${error.action.debugLabel}.${error.lifecycle.name}:\n${error.error}$parsedJson\n\n${error.stackTrace}';
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Copied to clipboard'),
    ),
  );
  Navigator.of(context).pop();
}
