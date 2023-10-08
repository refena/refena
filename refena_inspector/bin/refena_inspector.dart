import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:refena_inspector/util/logger.dart';

final _logger = Logger('RefenaInspectorBoot');
const _compilePath = '.refena_inspector/compile';
const _appPath = '.refena_inspector/app';

void main() async {
  initLogger();

  // Run compiled app if exists
  if (Directory(_appPath).existsSync()) {
    _logger.info('Detected compiled app. Running...');
    if (Platform.isWindows) {
      Process.runSync(
        '$_appPath\\refena_inspector.exe',
        [],
        runInShell: true,
      );
    } else if (Platform.isMacOS) {
      Process.runSync(
        'open',
        ['$_appPath/refena_inspector.app'],
        runInShell: true,
      );
    } else {
      Process.runSync(
        '$_appPath/refena_inspector',
        [],
        runInShell: true,
      );
    }
    return;
  }

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

  // Create compile path
  if (Platform.isWindows) {
    Process.runSync(
      'mkdir',
      [_compilePath],
      runInShell: true,
    );
  } else {
    Process.runSync(
      'mkdir',
      ['-p', _compilePath],
      runInShell: true,
    );
  }

  if (Platform.isWindows) {
    Process.runSync(
      'xcopy',
      ['/e', '/k', '/h', '/i', refenaPath, _compilePath],
      runInShell: true,
    );
  } else {
    Process.runSync(
      'cp',
      ['-R', '$refenaPath/', _compilePath],
      runInShell: true,
    );
  }

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

  // Compile app
  _logger.info('Compiling app in $_compilePath');
  final process = await Process.start(
    flutterPath,
    ['build', device],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: _compilePath,
    runInShell: true,
  );
  await process.exitCode;

  // Create app path
  _logger.info('Creating app in $_appPath');
  if (Platform.isWindows) {
    Process.runSync(
      'mkdir',
      [_appPath],
      runInShell: true,
    );
  } else {
    Process.runSync(
      'mkdir',
      ['-p', _appPath],
      runInShell: true,
    );
  }

  // Copy to app path
  _logger.info('Copying app to $_appPath');
  if (Platform.isWindows) {
    Process.runSync(
      'xcopy',
      [
        '/e',
        '/k',
        '/h',
        '/i',
        '$_compilePath\\build\\$device\\runner\\Release',
        _appPath,
      ],
      runInShell: true,
    );
  } else if (Platform.isMacOS) {
    Process.runSync(
      'cp',
      [
        '-R',
        '$_compilePath/build/macos/Build/Products/Release/refena_inspector.app',
        _appPath,
      ],
      runInShell: true,
    );
  } else {
    Process.runSync(
      'cp',
      [
        '-R',
        '$_compilePath/build/$device/release/bundle/libexec/refena_inspector',
        _appPath,
      ],
      runInShell: true,
    );
  }

  // Remove compile path
  _logger.info('Removing $_compilePath');
  if (Platform.isWindows) {
    Process.runSync(
      'rmdir',
      ['/s', '/q', _compilePath],
      runInShell: true,
    );
  } else {
    Process.runSync(
      'rm',
      ['-rf', _compilePath],
      runInShell: true,
    );
  }

  // Run
  _logger.info('Running app');
  if (Platform.isWindows) {
    Process.runSync(
      '$_appPath\\refena_inspector.exe',
      [],
      runInShell: true,
    );
  } else if (Platform.isMacOS) {
    Process.runSync(
      'open',
      ['$_appPath/refena_inspector.app'],
      runInShell: true,
    );
  } else {
    Process.runSync(
      '$_appPath/refena_inspector',
      [],
      runInShell: true,
    );
  }
}
