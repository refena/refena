part of 'tracing_page.dart';

class _TracingLegend extends StatelessWidget {
  const _TracingLegend();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: max(600, screenWidth - 40),
          child: Wrap(
            children: _EventType.values.map((e) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _EntryCharacterBox(e),
                    const SizedBox(width: 10),
                    Text(
                      switch (e) {
                        _EventType.change => 'State Change',
                        _EventType.rebuild => 'Rebuild',
                        _EventType.action => 'Action Dispatch',
                        _EventType.providerInit =>
                        'Provider Initialization',
                        _EventType.providerDispose =>
                        'Provider Dispose',
                        _EventType.message => 'Message',
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
}
