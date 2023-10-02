import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

final _logger = Logger('RefenaInspectorBoot');
const _inspectorPath = '.refena-inspector';

void main() async {
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${'[${record.level.name}]'.padLeft(9)} [${record.loggerName}] ${record.message}');

    if (record.error != null) {
      // ignore: avoid_print
      print(record.error);
    }

    if (record.stackTrace != null) {
      // ignore: avoid_print
      print(record.stackTrace);
    }
  });

  final config = Platform.packageConfig;
  if (config == null) {
    _logger.severe('No package config found');
    return;
  }
  _logger.info('Config: $config');

  final json = File(Uri.parse(config).toFilePath()).readAsStringSync();
  final jsonParsed = jsonDecode(json);
  final refenaEntry = (jsonParsed['packages'] as List)
          .firstWhere((e) => e['name'] == 'refena_inspector')
      as Map<String, dynamic>;

  final refenaPathUri = Uri.parse(refenaEntry['rootUri']);
  final String refenaPath;
  if (refenaPathUri.isAbsolute) {
    refenaPath = refenaPathUri.toFilePath();
  } else {
    refenaPath = p.normalize(p.join(
      Directory.current.path,
      '.dart_tool',
      refenaPathUri.toFilePath(),
    ));
  }
  _logger.info('RefenaInspector Path: $refenaPath');

  Process.runSync(
    'cp',
    ['-R', refenaPath, _inspectorPath],
    runInShell: true,
  );

  // e.g. C:\Users\MyUser\fvm\versions\3.7.12\bin\cache\dart-sdk\bin\dart.exe
  final dartPath = p.split(Platform.executable);

  // e.g. C:\Users\MyUser\fvm\versions\3.7.12\bin\flutter
  final flutterPath = p.joinAll([
    ...dartPath.sublist(0, dartPath.length - 4),
    'flutter',
  ]);

  final device = Platform.isWindows
      ? 'windows'
      : Platform.isMacOS
          ? 'macos'
          : 'linux';

  final process = await Process.start(
    flutterPath,
    ['run', '-d', device, '--profile'],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: _inspectorPath,
    runInShell: true,
  );
  await process.exitCode;
}
