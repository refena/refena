import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:refena_inspector/util/logger.dart';
import 'package:refena_inspector/util/regex.dart';

final _logger = Logger('RefenaInspectorBoot');
const _inspectorPath = '.refena_inspector';
const _compilePath = 'compile';
const _appPath = 'app';
const _versionFileName = 'version.txt';

enum _Platform {
  windows,
  macos,
  linux,
}

void main() async {
  initLogger();

  final platform = Platform.isWindows
      ? _Platform.windows
      : Platform.isMacOS
          ? _Platform.macos
          : _Platform.linux;

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

  // Read version from pubspec.yaml with regex
  final pubspec = File(p.join(refenaPath, 'pubspec.yaml')).readAsStringSync();
  final version = versionRegex.firstMatch(pubspec)?.group(1);
  if (version == null) {
    _logger.severe('No version found in pubspec.yaml');
    return;
  }
  _logger.info('Detected version in pubspec.yaml: $version');

  // Read version from version.txt to check if a rebuild is needed
  final versionFile = File(p.join(_inspectorPath, _appPath, _versionFileName));
  final versionFileContent =
      versionFile.existsSync() ? versionFile.readAsStringSync() : null;
  final versionFileContentLines = versionFileContent?.split('\n');
  if (versionFileContentLines != null && versionFileContentLines.length >= 2) {
    final versionFileContentVersion = versionFileContentLines[1].trim();
    if (versionFileContentVersion == version) {
      _logger.info('Using cached app.');
      await _runApp(platform);
      return;
    }
  }

  // Cleanup inspector path
  _logger.info('Cleaning up $_inspectorPath');
  if (Platform.isWindows) {
    Process.runSync(
      'rmdir',
      ['/s', '/q', _inspectorPath],
      runInShell: true,
    );
  } else {
    Process.runSync(
      'rm',
      ['-rf', _inspectorPath],
      runInShell: true,
    );
  }

  // Create compile path
  if (Platform.isWindows) {
    Process.runSync(
      'mkdir',
      ['$_inspectorPath\\$_compilePath'],
      runInShell: true,
    );
  } else {
    Process.runSync(
      'mkdir',
      ['-p', '$_inspectorPath/$_compilePath'],
      runInShell: true,
    );
  }

  switch (platform) {
    case _Platform.windows:
      Process.runSync(
        'xcopy',
        [
          '/e',
          '/k',
          '/h',
          '/i',
          '/y',
          refenaPath,
          '$_inspectorPath\\$_compilePath',
        ],
        runInShell: true,
      );
      break;
    case _Platform.macos:
      Process.runSync(
        'cp',
        ['-R', '$refenaPath/', '$_inspectorPath/$_compilePath'],
        runInShell: true,
      );
      break;
    case _Platform.linux:
      Process.runSync(
        'cp',
        ['-R', '$refenaPath/.', '$_inspectorPath/$_compilePath'],
        runInShell: true,
      );
      break;
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
  _logger.info('Compiling app...');
  final process = await Process.start(
    flutterPath,
    ['build', device],
    mode: ProcessStartMode.inheritStdio,
    workingDirectory: '$_inspectorPath${Platform.pathSeparator}$_compilePath',
    runInShell: true,
  );
  await process.exitCode;

  // Create app path
  _logger.info('Creating app folder in $_inspectorPath/$_appPath');
  if (Platform.isWindows) {
    Process.runSync(
      'mkdir',
      ['$_inspectorPath\\$_appPath'],
      runInShell: true,
    );
  } else {
    Process.runSync(
      'mkdir',
      ['-p', '$_inspectorPath/$_appPath'],
      runInShell: true,
    );
  }

  // Copy to app path
  _logger.info('Copying to $_appPath');
  switch (platform) {
    case _Platform.windows:
      Process.runSync(
        'xcopy',
        [
          '/e',
          '/k',
          '/h',
          '/i',
          '/y',
          '$_compilePath\\build\\$device\\x64\\runner\\Release',
          _appPath,
        ],
        workingDirectory: _inspectorPath,
        runInShell: true,
      );
      break;
    case _Platform.macos:
      Process.runSync(
        'cp',
        [
          '-R',
          '$_compilePath/build/macos/Build/Products/Release/refena_inspector.app',
          _appPath,
        ],
        workingDirectory: _inspectorPath,
        runInShell: true,
      );
      break;
    case _Platform.linux:
      Process.runSync(
        'cp',
        [
          '-R',
          '$_compilePath/build/linux/x64/release/bundle/.',
          _appPath,
        ],
        workingDirectory: _inspectorPath,
        runInShell: true,
      );
      break;
  }

  // Write version
  _logger.info('Writing version to $_versionFileName');
  final versionContent = '''
DO NOT EDIT THIS FILE MANUALLY!
$version
''';
  File(p.join(_inspectorPath, _appPath, _versionFileName))
      .writeAsStringSync(versionContent);

  // Remove compile path
  _logger.info('Removing $_compilePath');
  if (Platform.isWindows) {
    Process.runSync(
      'rmdir',
      ['/s', '/q', _compilePath],
      workingDirectory: _inspectorPath,
      runInShell: true,
    );
  } else {
    Process.runSync(
      'rm',
      ['-rf', _compilePath],
      workingDirectory: _inspectorPath,
      runInShell: true,
    );
  }

  // Run
  _logger.info('Running app');
  await _runApp(platform);
}

Future<void> _runApp(_Platform platform) async {
  switch (platform) {
    case _Platform.windows:
      await Process.start(
        '$_inspectorPath\\$_appPath\\refena_inspector.exe',
        [],
        mode: ProcessStartMode.inheritStdio,
        runInShell: true,
      );
      break;
    case _Platform.macos:
      await Process.start(
        'open',
        ['$_inspectorPath/$_appPath/refena_inspector.app'],
        mode: ProcessStartMode.inheritStdio,
        runInShell: true,
      );
      break;
    case _Platform.linux:
      await Process.start(
        '$_inspectorPath/$_appPath/refena_inspector',
        [],
        mode: ProcessStartMode.inheritStdio,
        runInShell: true,
      );
      break;
  }
}
