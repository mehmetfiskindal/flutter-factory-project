import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

class DoctorCommand extends Command<int> {
  DoctorCommand({
    required Logger logger,
  }) : _logger = logger;

  final Logger _logger;

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

    return hasError ? ExitCode.software.code : ExitCode.success.code;
  }

  Future<bool> _checkExecutable(String executable, List<String> args) async {
    try {
      final result = await Process.run(
        executable,
        args,
        runInShell: true,
      );

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final firstLine = output.split('\n').firstOrNull ?? executable;
        _logger.success(firstLine);
        return true;
      }

      _logger.err('$executable failed: ${result.stderr}');
      return false;
    } on Object catch (error) {
      _logger.err('$executable not available: $error');
      return false;
    }
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
