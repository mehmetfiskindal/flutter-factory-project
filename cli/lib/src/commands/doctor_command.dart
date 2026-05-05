import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> args,
);

class DoctorCommand extends Command<int> {
  DoctorCommand({
    required Logger logger,
    ProcessRunner? processRunner,
  })  : _logger = logger,
        _processRunner = processRunner ?? _defaultProcessRunner {
    argParser.addFlag(
      'firebase',
      negatable: false,
      help: 'Also check Firebase CLI and FlutterFire CLI tooling.',
    );
  }

  final Logger _logger;
  final ProcessRunner _processRunner;

  @override
  String get description => 'Check the local flutter_factory environment.';

  @override
  String get name => 'doctor';

  @override
  Future<int> run() async {
    var hasError = false;

    hasError = !await _checkExecutable('dart', ['--version']) || hasError;
    hasError = !await _checkExecutable('flutter', ['--version']) || hasError;
    hasError = !await _checkExecutable('mason', ['--version']) || hasError;

    final root = _resolveRoot();
    if (root == null) {
      _logger.err(
        'Could not resolve flutter-factory root. Set FLUTTER_FACTORY_ROOT.',
      );
      hasError = true;
    } else {
      _logger.success('flutter-factory root: ${root.path}');
      for (final path in [
        'mason.yaml',
        'starter/brick.yaml',
        'bricks/feature/brick.yaml',
        'bricks/api_service/brick.yaml',
        'bricks/page/brick.yaml',
      ]) {
        final file = File(p.join(root.path, path));
        if (file.existsSync()) {
          _logger.success(path);
        } else {
          _logger.err('Missing $path');
          hasError = true;
        }
      }
    }

    final path = Platform.environment['PATH'];
    if (path == null || path.isEmpty) {
      _logger.warn('PATH is empty.');
    } else {
      _logger.info('PATH configured.');
    }

    if (argResults?['firebase'] == true) {
      hasError = !await _checkFirebaseTooling() || hasError;
    }

    return hasError ? ExitCode.software.code : ExitCode.success.code;
  }

  Future<bool> _checkFirebaseTooling() async {
    var hasError = false;

    hasError = !await _checkNodeVersion() || hasError;
    hasError = !await _checkExecutable(
          'npm',
          ['--version'],
          installHint:
              'Install Node.js from https://nodejs.org; npm ships with Node.js.',
        ) ||
        hasError;
    hasError = !await _checkExecutable(
          'firebase',
          ['--version'],
          installHint:
              'Install Firebase CLI with `npm install -g firebase-tools`.',
        ) ||
        hasError;
    hasError = !await _checkFlutterFireCli() || hasError;

    if (!hasError) {
      await _checkFirebaseLoginState();
      _logger.info(
        'Configure generated Firebase apps with `firebase login` then `flutterfire configure`.',
      );
    }

    return !hasError;
  }

  Future<bool> _checkNodeVersion() async {
    final result = await _tryExecutable('node', ['--version']);
    if (result == null || result.exitCode != ExitCode.success.code) {
      _logger.err(
        'node not available. Install Node.js 18 or newer before installing firebase-tools.',
      );
      return false;
    }

    final output = _commandOutput(result);
    final major = _parseMajorVersion(output);
    if (major == null) {
      _logger.err('Could not parse Node.js version from "$output".');
      return false;
    }

    if (major < 18) {
      _logger.err(
        'Node.js $output is too old. Firebase CLI requires Node.js 18 or newer.',
      );
      return false;
    }

    _logger.success('Node.js $output');
    return true;
  }

  Future<bool> _checkFlutterFireCli() async {
    final direct = await _tryExecutable('flutterfire', ['--version']);
    if (direct != null && direct.exitCode == ExitCode.success.code) {
      _logger.success('flutterfire ${_commandOutput(direct)}');
      return true;
    }

    final globalList = await _tryExecutable('dart', ['pub', 'global', 'list']);
    if (globalList != null &&
        globalList.exitCode == ExitCode.success.code &&
        _commandOutput(globalList).contains('flutterfire_cli')) {
      _logger.success('flutterfire_cli is activated with dart pub global.');
      return true;
    }

    _logger.err(
      'FlutterFire CLI not available. Install it with `dart pub global activate flutterfire_cli`.',
    );
    return false;
  }

  Future<void> _checkFirebaseLoginState() async {
    final result = await _tryExecutable('firebase', ['login:list']);
    if (result != null && result.exitCode == ExitCode.success.code) {
      _logger.success('Firebase login state available.');
      return;
    }

    _logger.warn(
      'Could not confirm Firebase login state. Run `firebase login` before `flutterfire configure`.',
    );
  }

  Future<bool> _checkExecutable(
    String executable,
    List<String> args, {
    String? installHint,
  }) async {
    final result = await _tryExecutable(executable, args);

    if (result != null && result.exitCode == ExitCode.success.code) {
      final output = _commandOutput(result);
      final firstLine = output.split('\n').firstOrNull ?? executable;
      _logger.success(firstLine);
      return true;
    }

    if (result == null) {
      _logger.err('$executable not available.');
    } else {
      _logger.err('$executable failed: ${_commandOutput(result)}');
    }
    if (installHint != null) {
      _logger.info(installHint);
    }
    return false;
  }

  Future<ProcessResult?> _tryExecutable(
    String executable,
    List<String> args,
  ) async {
    try {
      return await _processRunner(executable, args);
    } on Object {
      return null;
    }
  }

  static Future<ProcessResult> _defaultProcessRunner(
    String executable,
    List<String> args,
  ) {
    return Process.run(
      executable,
      args,
      runInShell: true,
    );
  }

  String _commandOutput(ProcessResult result) {
    final stdout = result.stdout.toString().trim();
    if (stdout.isNotEmpty) {
      return stdout;
    }

    return result.stderr.toString().trim();
  }

  int? _parseMajorVersion(String output) {
    final match = RegExp(r'v?(\d+)').firstMatch(output);
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  Directory? _resolveRoot() {
    final envRoot = Platform.environment['FLUTTER_FACTORY_ROOT'];
    if (envRoot != null && envRoot.isNotEmpty) {
      final directory = Directory(envRoot);
      if (directory.existsSync()) {
        return directory;
      }
    }

    var current = Directory.current.absolute;
    while (true) {
      if (File(p.join(current.path, 'mason.yaml')).existsSync() &&
          Directory(p.join(current.path, 'bricks')).existsSync() &&
          Directory(p.join(current.path, 'starter')).existsSync()) {
        return current;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        return null;
      }

      current = parent;
    }
  }
}
