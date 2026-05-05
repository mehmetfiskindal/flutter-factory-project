import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as p;

class MasonService {
  MasonService({
    required Logger logger,
    Directory? workingDirectory,
  })  : _logger = logger,
        _workingDirectory = workingDirectory ?? Directory.current;

  final Logger _logger;
  final Directory _workingDirectory;

  Future<void> generate({
    required String brickName,
    required Map<String, dynamic> vars,
    String? targetDirectory,
    bool force = false,
  }) async {
    final brickDirectory = _resolveBrickDirectory(brickName);
    final target = Directory(
      targetDirectory == null
          ? _workingDirectory.path
          : p.join(_workingDirectory.path, targetDirectory),
    );

    if (!target.existsSync()) {
      target.createSync(recursive: true);
    }

    final brick = Brick.path(brickDirectory.path);
    final generator = await MasonGenerator.fromBrick(brick);
    var generationVars = Map<String, dynamic>.of(vars);

    await generator.hooks.preGen(
      vars: generationVars,
      workingDirectory: target.path,
      onVarsChanged: (vars) => generationVars = vars,
      logger: _logger,
    );

    await generator.generate(
      DirectoryGeneratorTarget(target),
      fileConflictResolution: force
          ? FileConflictResolution.overwrite
          : FileConflictResolution.skip,
      logger: _logger,
      vars: generationVars,
    );

    await generator.hooks.postGen(
      vars: generationVars,
      workingDirectory: target.path,
      logger: _logger,
    );
  }

  Directory _resolveBrickDirectory(String brickName) {
    final root = _resolveFlutterFactoryRoot();
    final brickPath = switch (brickName) {
      'starter' => p.join(root.path, 'starter'),
      _ => p.join(root.path, 'bricks', brickName),
    };

    final directory = Directory(brickPath);
    if (!directory.existsSync() ||
        !File(p.join(directory.path, 'brick.yaml')).existsSync()) {
      throw BrickNotFoundException(brickName, directory.path);
    }

    return directory;
  }

  Directory _resolveFlutterFactoryRoot() {
    final envRoot = Platform.environment['FLUTTER_FACTORY_ROOT'];
    if (envRoot != null && envRoot.trim().isNotEmpty) {
      final directory = Directory(envRoot);
      if (directory.existsSync()) {
        return directory;
      }
    }

    final fromWorkingDirectory = _findRootFrom(_workingDirectory);
    if (fromWorkingDirectory != null) {
      return fromWorkingDirectory;
    }

    final executableDirectory = File(Platform.script.toFilePath()).parent;
    final fromExecutable = _findRootFrom(executableDirectory);
    if (fromExecutable != null) {
      return fromExecutable;
    }

    return _workingDirectory;
  }

  Directory? _findRootFrom(Directory start) {
    var current = start.absolute;

    while (true) {
      final hasMasonFile =
          File(p.join(current.path, 'mason.yaml')).existsSync();
      final hasBricksDirectory =
          Directory(p.join(current.path, 'bricks')).existsSync();
      final hasCliDirectory =
          Directory(p.join(current.path, 'cli')).existsSync();

      if (hasMasonFile && hasBricksDirectory && hasCliDirectory) {
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

class BrickNotFoundException implements Exception {
  const BrickNotFoundException(this.brickName, this.expectedPath);

  final String brickName;
  final String expectedPath;

  String get message =>
      'Could not find Mason brick "$brickName" at $expectedPath.';

  @override
  String toString() => message;
}
