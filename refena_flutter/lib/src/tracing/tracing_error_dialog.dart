// ignore_for_file: invalid_use_of_internal_member

part of 'tracing_page.dart';

class _TracingErrorDialog extends StatelessWidget {
  final _ErrorEntry error;

  _TracingErrorDialog(this.error);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Error in ${error.actionLabel}.${error.actionLifecycle.name}',
      ),
      scrollable: true,
      content: _TracingErrorContent(
        error: error.error,
        stackTrace: error.stackTrace,
        parsedErrorData: error.parsedErrorData,
      ),
      actions: [
        TextButton(
          onPressed: () => _copyErrorToClipboard(
            context: context,
            error: error,
          ),
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
  final _ErrorEntry error;

  _TracingErrorPage(this.error);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Error in ${error.actionLabel}.${error.actionLifecycle.name}',
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
            error: error.error,
            stackTrace: error.stackTrace,
            parsedErrorData: error.parsedErrorData,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () => _copyErrorToClipboard(
                context: context,
                error: error,
              ),
              child: Text('Copy'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TracingErrorContent extends StatelessWidget {
  final String error;
  final String stackTrace;
  final Map<String, dynamic>? parsedErrorData;

  _TracingErrorContent({
    required this.error,
    required this.stackTrace,
    required this.parsedErrorData,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        _QuoteContainer(error),
        if (parsedErrorData != null) ...[
          const SizedBox(height: 10),
          Text('Info:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          _QuoteContainer(
            _jsonEncoder.convert(parsedErrorData),
          ),
        ],
        const SizedBox(height: 10),
        Text('Stacktrace:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        _QuoteContainer(stackTrace),
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

void _copyErrorToClipboard({
  required BuildContext context,
  required _ErrorEntry error,
}) {
  final parsedJson = error.parsedErrorData != null
      ? '\n\n${_jsonEncoder.convert(error.parsedErrorData)}'
      : '';
  final text =
      'Error in ${error.actionLabel}.${error.actionLifecycle.name}:\n${error.error}$parsedJson\n\n${error.stackTrace}';
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Copied to clipboard'),
    ),
  );
  Navigator.of(context).pop();
}
