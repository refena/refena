import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:refena_flutter/src/element_rebuildable.dart';

final _provider = Provider((ref) => 'Hello, World!');

void main() {
  setUpAll(() {
    printWarning = false;
  });

  setUp(() {
    warningCount = 0;
  });

  tearDownAll(() {
    printWarning = true;
  });

  testWidgets('Should not log warning on watch inside build', (tester) async {
    final scope = RefenaScope(
      child: MaterialApp(
        home: _CorrectSimpleWidget(),
      ),
    );

    expect(warningCount, 0);

    await tester.pumpWidget(scope);

    expect(find.text('Hello, World!'), findsOneWidget);
    expect(warningCount, 0);
  });

  testWidgets('Should log warning on watch inside callback', (tester) async {
    final scope = RefenaScope(
      child: MaterialApp(
        home: _IncorrectOnPressedWidget(),
      ),
    );

    expect(warningCount, 0);

    await tester.pumpWidget(scope);

    expect(find.text('Hello, World!'), findsOneWidget);
    expect(warningCount, 0);

    await tester.tap(find.text('Tap me!'));
    await tester.pump();

    expect(warningCount, 1);
  });

  testWidgets('Should not log warning on read inside callback', (tester) async {
    final scope = RefenaScope(
      child: MaterialApp(
        home: _CorrectOnPressedWidget(),
      ),
    );

    expect(warningCount, 0);

    await tester.pumpWidget(scope);

    expect(find.text('Hello, World!'), findsOneWidget);
    expect(warningCount, 0);

    await tester.tap(find.text('Tap me!'));
    await tester.pump();

    expect(warningCount, 0);
  });

  testWidgets('Should not log warning on watch inside Builder', (tester) async {
    final scope = RefenaScope(
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            return Text(context.watch(_provider));
          },
        ),
      ),
    );

    expect(warningCount, 0);

    await tester.pumpWidget(scope);

    expect(find.text('Hello, World!'), findsOneWidget);
    expect(warningCount, 0);
  });

  testWidgets('Should not log warning on watch inside LayoutBuilder',
      (tester) async {
    final scope = RefenaScope(
      child: MaterialApp(
        home: LayoutBuilder(
          builder: (context, constraints) {
            return Text(context.watch(_provider));
          },
        ),
      ),
    );

    expect(warningCount, 0);

    await tester.pumpWidget(scope);

    expect(find.text('Hello, World!'), findsOneWidget);
    expect(warningCount, 0);
  });
}

class _CorrectSimpleWidget extends StatelessWidget {
  const _CorrectSimpleWidget();

  @override
  Widget build(BuildContext context) {
    return Text(context.watch(_provider));
  }
}

class _IncorrectOnPressedWidget extends StatelessWidget {
  const _IncorrectOnPressedWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(context.watch(_provider)),
        TextButton(
          onPressed: () {
            context.watch(_provider);
          },
          child: const Text('Tap me!'),
        ),
      ],
    );
  }
}

class _CorrectOnPressedWidget extends StatelessWidget {
  const _CorrectOnPressedWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(context.watch(_provider)),
        TextButton(
          onPressed: () {
            context.read(_provider);
          },
          child: const Text('Tap me!'),
        ),
      ],
    );
  }
}
